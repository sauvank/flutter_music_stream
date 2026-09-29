import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/library_provider.dart';
import '../l10n/l10n.dart';

enum _ImportSource { files, directory }

Future<void> showMusicImportSheet(BuildContext context) async {
  final library = context.read<LibraryProvider>();
  final source = await showModalBottomSheet<_ImportSource>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Text(
                context.l10n.importSheetTitle,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.audio_file_rounded),
              ),
              title: Text(context.l10n.importChooseFiles),
              subtitle: Text(context.l10n.importChooseFilesHint),
              onTap: () => Navigator.pop(context, _ImportSource.files),
            ),
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.folder_copy_rounded),
              ),
              title: Text(context.l10n.importChooseFolder),
              subtitle: Text(context.l10n.importChooseFolderHint),
              onTap: () => Navigator.pop(context, _ImportSource.directory),
            ),
          ],
        ),
      ),
    ),
  );
  if (source == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  if (source == _ImportSource.directory && !await _canReadSharedAudio()) {
    messenger.showSnackBar(SnackBar(
      content: Text(l10n.audioPermissionDenied),
      action: SnackBarAction(
        label: l10n.openSettings,
        onPressed: openAppSettings,
      ),
    ));
    return;
  }
  try {
    final summary = switch (source) {
      _ImportSource.files => await library.importFiles(),
      _ImportSource.directory =>
        await library.importDirectory(dialogTitle: l10n.pickMusicFolder),
    };
    if (summary == null) return;
    messenger.showSnackBar(
        SnackBar(content: Text(importSummaryText(l10n, summary))));
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.importFailed)),
    );
  }
}

/// Folder import lists shared storage by path, which Android only exposes
/// with READ_MEDIA_AUDIO (13+) or READ_EXTERNAL_STORAGE (12 and below).
/// Picking individual files goes through a copy and needs neither.
Future<bool> _canReadSharedAudio() async {
  if (!Platform.isAndroid) return true;
  final statuses = await [Permission.audio, Permission.storage].request();
  return statuses.values.any((status) => status.isGranted || status.isLimited);
}

String importSummaryText(AppLocalizations l10n, LocalImportSummary summary) {
  final parts = [
    l10n.importAdded(summary.added),
    if (summary.skipped > 0) l10n.importSkipped(summary.skipped),
    if (summary.failed > 0) l10n.importFailures(summary.failed),
  ];
  return parts.join(' · ');
}
