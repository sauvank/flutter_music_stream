import 'package:background_downloader/background_downloader.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/download_queue_provider.dart';
import '../providers/library_provider.dart';
import '../providers/download_request.dart';
import '../models/server_profile.dart';

Future<void> showDownloadQueue(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 720),
      builder: (_) => const DownloadsSheet(),
    );

/// A labelled entry point stays discoverable, even before the first download.
class DownloadQueueShortcut extends StatelessWidget {
  const DownloadQueueShortcut({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<DownloadQueueProvider>();
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Card.filled(
        margin: EdgeInsets.zero,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Icon(Icons.downloading_rounded, color: colors.primary),
          title: Text(context.l10n.downloads),
          subtitle: Text(queue.requests.any((r) => r.active)
              ? context.l10n.downloadPreparingShort
              : queue.activeCount > 0
                  ? context.l10n.downloadQueueActive(queue.activeCount)
                  : queue.hasFailed
                      ? context.l10n.downloadNeedsAttention
                      : context.l10n.downloadManage),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => showDownloadQueue(context),
        ),
      ),
    );
  }
}

enum _Filter { all, active, failed, finished }

bool _failed(TaskRecord record) =>
    record.status == TaskStatus.failed || record.status == TaskStatus.notFound;

class DownloadsSheet extends StatefulWidget {
  const DownloadsSheet({super.key});

  @override
  State<DownloadsSheet> createState() => _DownloadsSheetState();
}

class _DownloadsSheetState extends State<DownloadsSheet> {
  _Filter _filter = _Filter.all;
  final Set<String> _busy = {};

  Future<void> _run(String key, Future<void> Function() action) async {
    if (_busy.contains(key)) return;
    setState(() => _busy.add(key));
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.downloadActionFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(key));
    }
  }

  Future<void> _cancelAll(DownloadQueueProvider queue) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.cancelAllTitle),
        content: Text(context.l10n.cancelAllBody(
            queue.records.where((r) => r.status.isNotFinalState).length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.continueAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.cancelAll),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _run('bulk', queue.cancelAll);
  }

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<DownloadQueueProvider>();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final records = queue.records;
    final running = records.where((r) => r.status == TaskStatus.running).length;
    final waiting = records
        .where((r) =>
            r.status == TaskStatus.enqueued ||
            r.status == TaskStatus.waitingToRetry)
        .length;
    final paused = records.where((r) => r.status == TaskStatus.paused).length;
    bool active(TaskRecord r) => r.status.isNotFinalState;
    bool matches(TaskRecord r, _Filter filter) => switch (filter) {
          _Filter.all => true,
          _Filter.active => active(r),
          _Filter.failed => _failed(r),
          _Filter.finished => !active(r) && !_failed(r),
        };
    final counts = {
      for (final f in _Filter.values)
        f: records.where((r) => matches(r, f)).length
    };
    final visible = records.where((r) => matches(r, _filter)).toList();
    // Keep ongoing work and problems above history, preserving order per group.
    final ordered = [
      ...visible.where((r) => r.status == TaskStatus.running),
      ...visible.where((r) =>
          active(r) &&
          r.status != TaskStatus.running &&
          r.status != TaskStatus.paused),
      ...visible.where((r) => r.status == TaskStatus.paused),
      ...visible.where(_failed),
      ...visible.where((r) => !active(r) && !_failed(r)),
    ];
    final labels = {
      _Filter.all: l10n.downloadFilterAll,
      _Filter.active: l10n.downloadFilterActive,
      _Filter.failed: l10n.downloadFilterFailed,
      _Filter.finished: l10n.downloadFilterFinished,
    };
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .86,
      minChildSize: .45,
      maxChildSize: .96,
      builder: (context, controller) => SafeArea(
        top: false,
        child: CustomScrollView(
          controller: controller,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(l10n.downloads,
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800))),
                      if (records.isNotEmpty)
                        PopupMenuButton<String>(
                          tooltip: l10n.downloadQueueActions,
                          enabled: _busy.isEmpty,
                          onSelected: (value) async {
                            if (value == 'cancel') {
                              await _cancelAll(queue);
                            } else if (value == 'retry') {
                              await _run('bulk', queue.retryFailed);
                            } else {
                              await _run('bulk', queue.clearFinished);
                            }
                          },
                          itemBuilder: (_) => [
                            if (queue.hasFailed)
                              PopupMenuItem(
                                  value: 'retry',
                                  child: Text(l10n.retryFailed)),
                            if (queue.hasClearable)
                              PopupMenuItem(
                                  value: 'clear',
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(l10n.downloadClearHistory),
                                      Text(l10n.downloadHistoryHint,
                                          style: theme.textTheme.bodySmall)
                                    ],
                                  )),
                            if (records.any((r) => r.status.isNotFinalState))
                              PopupMenuItem(
                                  value: 'cancel',
                                  child: Text(l10n.cancelAll,
                                      style: TextStyle(
                                          color: theme.colorScheme.error))),
                          ],
                        ),
                      IconButton(
                          tooltip: l10n.close,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded)),
                    ]),
                    Text(
                        queue.requests.any((r) =>
                                r.active && r.profile.type == ServerType.ftp)
                            ? l10n.downloadFtpHint
                            : l10n.downloadBackgroundHint,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    if (records.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(children: [
                          Icon(
                              counts[_Filter.active]! > 0
                                  ? Icons.downloading_rounded
                                  : queue.hasFailed
                                      ? Icons.error_outline_rounded
                                      : Icons.offline_pin_rounded,
                              size: 32,
                              color: theme.colorScheme.onPrimaryContainer),
                          const SizedBox(width: 16),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(
                                    running > 0
                                        ? l10n.downloadQueueActive(running)
                                        : counts[_Filter.active]! > 0
                                            ? waiting > 0
                                                ? l10n.statusEnqueued
                                                : paused > 0
                                                    ? l10n.statusPaused
                                                    : l10n.downloadIndexing
                                            : queue.hasFailed
                                                ? l10n.downloadNeedsAttention
                                                : l10n.downloadQueueUpToDate,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: theme.colorScheme
                                                .onPrimaryContainer)),
                                const SizedBox(height: 4),
                                Text(
                                    counts[_Filter.active]! > 0
                                        ? l10n.downloadWaitingSummary(
                                            waiting, paused)
                                        : l10n.downloadQueueSummary(
                                            counts[_Filter.finished]!,
                                            counts[_Filter.failed]!),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme
                                            .colorScheme.onPrimaryContainer)),
                              ])),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final f in _Filter.values)
                            ChoiceChip(
                              label: Text('${labels[f]} · ${counts[f]}'),
                              selected: _filter == f,
                              onSelected: (_) => setState(() => _filter = f),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (queue.requests.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.builder(
                  itemCount: queue.requests.length,
                  itemBuilder: (context, index) =>
                      _RequestCard(request: queue.requests[index]),
                ),
              ),
            if (ordered.isEmpty && queue.requests.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 28, 32, 48),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            records.isEmpty
                                ? Icons.download_for_offline_outlined
                                : Icons.check_circle_outline_rounded,
                            size: 64,
                            color: theme.colorScheme.primary),
                        const SizedBox(height: 20),
                        Text(
                            records.isEmpty
                                ? l10n.noDownloads
                                : l10n.downloadEmptyFilter,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                            records.isEmpty
                                ? l10n.downloadEmptyHint
                                : l10n.downloadEmptyFilterHint,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 20),
                        TextButton(
                            onPressed: records.isEmpty
                                ? () => Navigator.pop(context)
                                : () => setState(() => _filter = _Filter.all),
                            child: Text(records.isEmpty
                                ? l10n.downloadBrowseServers
                                : l10n.downloadShowAll)),
                      ]),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.builder(
                  itemCount: ordered.length,
                  itemBuilder: (context, index) {
                    final record = ordered[index];
                    return _DownloadCard(
                      key: ValueKey(record.taskId),
                      record: record,
                      importing: queue.isImporting(record.taskId),
                      busy: _busy.contains(record.taskId) ||
                          _busy.contains('bulk'),
                      onAction: (action) => _run(record.taskId, action),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});
  final DownloadRequest request;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final queue = context.read<DownloadQueueProvider>();
    final error = request.error;
    final httpCode = error is DioException ? error.response?.statusCode : null;
    final label = switch (request.stage) {
      DownloadRequestStage.scanning => l10n.scanningFolder,
      DownloadRequestStage.queueing => l10n.queueingTracks(request.total),
      DownloadRequestStage.transferring =>
        request.currentFile ?? l10n.statusEnqueued,
      DownloadRequestStage.failed => httpCode != null
          ? l10n.downloadHttpError(httpCode)
          : error is StateError
              ? l10n.folderTooLarge
              : l10n.downloadFailedHint,
      DownloadRequestStage.complete => request.total == 0
          ? l10n.noCompatibleTracks
          : request.profile.type != ServerType.ftp
              ? l10n.nothingNewToDownload
              : '${l10n.addedCount(request.added)} · ${l10n.importFailures(request.failed)}',
    };
    return Card.filled(
        child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(request.error == null
              ? Icons.folder_open_rounded
              : Icons.error_outline_rounded),
          const SizedBox(width: 12),
          Expanded(
              child: Text(request.entry.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall)),
          if (!request.active)
            IconButton(
                tooltip: l10n.close,
                onPressed: () => queue.dismissRequest(request.id),
                icon: const Icon(Icons.close_rounded)),
        ]),
        const SizedBox(height: 8),
        Text(label),
        if (request.active) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(value: request.progress),
          const SizedBox(height: 8),
          Text(
              request.profile.type == ServerType.ftp
                  ? l10n.downloadFtpHint
                  : l10n.downloadPreparationHint,
              style: Theme.of(context).textTheme.bodySmall),
        ],
        if (request.error != null || request.failed > 0)
          TextButton.icon(
              onPressed: () => queue.retryRequest(request),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry)),
      ]),
    ));
  }
}

class _DownloadCard extends StatelessWidget {
  const _DownloadCard(
      {super.key,
      required this.record,
      required this.importing,
      required this.busy,
      required this.onAction});
  final TaskRecord record;
  final bool importing;
  final bool busy;
  final void Function(Future<void> Function()) onAction;

  @override
  Widget build(BuildContext context) {
    final queue = context.read<DownloadQueueProvider>();
    final available = context.select<LibraryProvider, bool>(
        (library) => library.downloadedSourceUris.contains(record.task.url));
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final status = record.status;
    final failed = _failed(record);
    final exception = record.exception;
    final httpCode =
        exception is TaskHttpException && exception.httpResponseCode > 0
            ? exception.httpResponseCode
            : null;
    final color = failed ? colors.error : colors.primary;
    final progress = record.progress.isFinite && record.progress >= 0
        ? record.progress.clamp(0.0, 1.0)
        : null;
    final label = importing
        ? l10n.downloadIndexing
        : switch (status) {
            TaskStatus.enqueued => l10n.statusEnqueued,
            TaskStatus.running => l10n.statusRunning,
            TaskStatus.complete =>
              available ? l10n.statusComplete : l10n.downloadTransferComplete,
            TaskStatus.notFound => l10n.statusNotFound,
            TaskStatus.failed => l10n.statusFailed,
            TaskStatus.canceled => l10n.statusCanceled,
            TaskStatus.waitingToRetry => l10n.statusWaitingToRetry,
            TaskStatus.paused => l10n.statusPaused,
          };
    final icon = importing
        ? Icons.library_music_rounded
        : switch (status) {
            TaskStatus.complete => Icons.offline_pin_rounded,
            TaskStatus.failed ||
            TaskStatus.notFound =>
              Icons.error_outline_rounded,
            TaskStatus.paused => Icons.pause_rounded,
            TaskStatus.canceled => Icons.close_rounded,
            TaskStatus.enqueued ||
            TaskStatus.waitingToRetry =>
              Icons.schedule_rounded,
            _ => Icons.south_rounded,
          };
    final folder = Uri.tryParse(record.task.url)
        ?.pathSegments
        .where((s) => s.isNotEmpty)
        .toList();
    return Card.filled(
      margin: const EdgeInsets.only(bottom: 10),
      color: failed
          ? colors.errorContainer.withValues(alpha: .35)
          : colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(record.task.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  if (folder != null && folder.length > 1) ...[
                    const SizedBox(height: 3),
                    Text(folder[folder.length - 2],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant)),
                  ],
                ])),
            if (!importing && status.isNotFinalState)
              PopupMenuButton<String>(
                tooltip: l10n.downloadMoreActions,
                enabled: !busy,
                onSelected: (_) => onAction(() => queue.cancel(record.taskId)),
                itemBuilder: (_) =>
                    [PopupMenuItem(value: 'cancel', child: Text(l10n.cancel))],
              ),
          ]),
          const SizedBox(height: 12),
          Wrap(
              spacing: 10,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(label,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: failed ? colors.error : colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600)),
                if ((status == TaskStatus.running ||
                        status == TaskStatus.paused) &&
                    progress != null)
                  Text('${(progress * 100).round()} %',
                      style:
                          theme.textTheme.labelMedium?.copyWith(color: color)),
                if (record.expectedFileSize > 0)
                  Text(
                      status == TaskStatus.running && progress != null
                          ? '${_size(record.expectedFileSize * progress)} / ${_size(record.expectedFileSize.toDouble())}'
                          : _size(record.expectedFileSize.toDouble()),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant)),
              ]),
          if (status == TaskStatus.running ||
              status == TaskStatus.paused ||
              importing) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(
                value: importing ? null : progress,
                minHeight: 5,
                borderRadius: BorderRadius.circular(4),
                semanticsLabel: label),
          ],
          if (failed) ...[
            const SizedBox(height: 8),
            Text(
                status == TaskStatus.notFound
                    ? l10n.downloadMissingHint
                    : httpCode != null
                        ? l10n.downloadHttpError(httpCode)
                        : l10n.downloadFailedHint,
                style: theme.textTheme.bodySmall),
          ],
          if (busy)
            const Padding(
                padding: EdgeInsets.only(top: 12),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)))
          else if (!importing &&
              (status == TaskStatus.running ||
                  status == TaskStatus.paused ||
                  failed ||
                  status == TaskStatus.canceled))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: () => onAction(() => switch (status) {
                      TaskStatus.running => queue.pause(record.taskId),
                      TaskStatus.paused => queue.resume(record.taskId),
                      _ => queue.retry(record.taskId),
                    }),
                icon: Icon(
                    status == TaskStatus.running
                        ? Icons.pause_rounded
                        : status == TaskStatus.paused
                            ? Icons.play_arrow_rounded
                            : Icons.refresh_rounded,
                    size: 18),
                label: Text(status == TaskStatus.running
                    ? l10n.pause
                    : status == TaskStatus.paused
                        ? l10n.resume
                        : l10n.retry),
              ),
            ),
        ]),
      ),
    );
  }

  String _size(double bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GiB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KiB';
  }
}
