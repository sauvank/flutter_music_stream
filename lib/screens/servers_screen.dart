import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/remote_audio_entry.dart';
import '../models/remote_audio_metadata.dart';
import '../models/server_profile.dart';
import '../models/music_track.dart';
import '../providers/download_queue_provider.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../providers/server_provider.dart';
import '../l10n/l10n.dart';
import '../services/server_scan_service.dart';
import '../widgets/add_server_sheet.dart';
import 'downloads_sheet.dart';

void _downloadServer(
    BuildContext context, ServerProvider servers, ServerProfile profile) {
  final root = Uri.parse(profile.baseUrl);
  _startDownload(
      context,
      servers,
      profile,
      RemoteAudioEntry(
        name: profile.name,
        uri: root.replace(
            path: root.path.endsWith('/') ? root.path : '${root.path}/'),
        isDirectory: true,
      ));
}

void _startDownload(BuildContext context, ServerProvider servers,
    ServerProfile profile, RemoteAudioEntry entry) {
  final started = context.read<DownloadQueueProvider>().startRequest(
        entry: entry,
        profile: profile,
        password: () => servers.passwordFor(profile),
        remote: servers.remoteService,
      );
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(started
          ? context.l10n.downloadPreparing(entry.name)
          : context.l10n.alreadyDownloading(entry.name)),
      action: SnackBarAction(
          label: context.l10n.downloadViewQueue,
          onPressed: () => showDownloadQueue(context)),
    ));
}

class ServersScreen extends StatelessWidget {
  const ServersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final servers = context.watch<ServerProvider>();
    if (servers.selected != null) return _Browser(provider: servers);
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _ServerHeader(
            onAdd: () => _showAddProfile(context),
            onImport: () => _chooseImport(context),
          ),
        ),
        const SliverToBoxAdapter(child: DownloadQueueShortcut()),
        if (servers.profiles.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyServers(
              onAdd: () => _showAddProfile(context),
              onImport: () => _chooseImport(context),
            ),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                context.l10n.sourceCount(servers.profiles.length),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 190),
            sliver: SliverList.builder(
              itemCount: servers.profiles.length,
              itemBuilder: (context, index) {
                final profile = servers.profiles[index];
                return _ServerCard(
                  profile: profile,
                  onOpen: () => servers.connect(profile),
                  onScan: () => _scanForNewAlbums(context, profile),
                  scanning: servers.scanningProfileIds.contains(profile.id),
                  onDelete: () => _confirmDeleteProfile(context, profile),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmDeleteProfile(
    BuildContext context,
    ServerProfile profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteServerTitle),
        content: Text(context.l10n.deleteServerBody(profile.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<ServerProvider>().deleteProfile(profile);
  }

  Future<void> _showAddProfile(BuildContext context) async {
    final servers = context.read<ServerProvider>();
    final result = await showAddServerSheet(context);
    if (result != null) await servers.addProfile(result.$1, result.$2);
  }

  Future<void> _scanForNewAlbums(
    BuildContext context,
    ServerProfile profile,
  ) async {
    try {
      final result =
          await context.read<ServerProvider>().scanForNewAlbums(profile);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(result.baselineCreated
              ? context.l10n.baselineCreated
              : result.newAlbums.isEmpty
                  ? context.l10n.libraryUpToDate
                  : context.l10n.newAlbums),
          content: result.baselineCreated
              ? Text(
                  context.l10n.baselineBody(result.totalTracks),
                )
              : result.newAlbums.isEmpty
                  ? Text(
                      context.l10n.noNewTracks(result.totalTracks),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.newTracksCount(result.newTrackCount),
                          ),
                          const SizedBox(height: 12),
                          ...result.newAlbums.map(
                            (album) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.album_outlined),
                              title: Text(
                                  album.name == ServerScanService.rootAlbumName
                                      ? context.l10n.serverRoot
                                      : album.name),
                              trailing: Text('${album.trackCount}'),
                            ),
                          ),
                        ],
                      ),
                    ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.close),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.scanFailed)),
      );
    }
  }

  Future<void> _chooseImport(BuildContext context) async {
    final source = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.importServersTitle,
                    style: Theme.of(sheetContext)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(context.l10n.importServersHint),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_rounded),
              title: Text(context.l10n.chooseJsonFile),
              onTap: () => Navigator.pop(sheetContext, 'file'),
            ),
            ListTile(
              leading: const Icon(Icons.content_paste_rounded),
              title: Text(context.l10n.pasteJson),
              onTap: () => Navigator.pop(sheetContext, 'paste'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (source == 'file') {
      await _importProfilesFromFile(context);
    } else if (source == 'paste') {
      await _importProfilesFromPaste(context);
    }
  }

  Future<void> _importProfilesFromFile(BuildContext context) async {
    final selection = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    final path = selection?.files.single.path;
    if (path == null || !context.mounted) return;
    try {
      final content = await File(path).readAsString();
      if (!context.mounted) return;
      await _importContent(context, content);
    } on FileSystemException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.fileReadFailed)),
      );
    }
  }

  Future<void> _importProfilesFromPaste(BuildContext context) async {
    var content = '';
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.pasteConfiguration),
        content: SizedBox(
          width: 560,
          child: TextFormField(
            autofocus: true,
            minLines: 8,
            maxLines: 14,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: const InputDecoration(
              hintText: '[{"name": "NAS", ...}]',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => content = value,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (content.trim().isNotEmpty) {
                Navigator.pop(dialogContext, content);
              }
            },
            child: Text(context.l10n.importAction),
          ),
        ],
      ),
    );
    if (value == null || !context.mounted) return;
    await _importContent(context, value);
  }

  Future<void> _importContent(BuildContext context, String content) async {
    try {
      final count =
          await context.read<ServerProvider>().importProfilesFromJson(content);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(count == 0
            ? context.l10n.serverAlreadyConfigured
            : context.l10n.serversImported(count)),
      ));
    } on FormatException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.invalidJson)),
      );
    }
  }
}

class _ServerHeader extends StatelessWidget {
  const _ServerHeader({required this.onAdd, required this.onImport});
  final VoidCallback onAdd;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00BFA5), Color(0xFF2979FF)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.cloud_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.yourSources,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          context.l10n.personalServers,
                          maxLines: 1,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: context.l10n.importJsonFile,
                  onPressed: onImport,
                  icon: const Icon(Icons.file_open_outlined),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: context.l10n.addServer,
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            // No decorative headline: on a phone it pushed the "Add a
            // server" button under the mini player.
          ],
        ),
      );
}

class _EmptyServers extends StatelessWidget {
  const _EmptyServers({required this.onAdd, required this.onImport});
  final VoidCallback onAdd;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 180),
        child: Center(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 620),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00695C), Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(36),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33006595),
                  blurRadius: 34,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_sync_rounded,
                    size: 52, color: Colors.white),
                const SizedBox(height: 54),
                Text(
                  context.l10n.connectCollectionTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.connectCollectionBody,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: .82),
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF064F55),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                  ),
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(context.l10n.addServer),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: onImport,
                  icon: const Icon(Icons.file_open_outlined),
                  label: Text(context.l10n.importJsonFile),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({
    required this.profile,
    required this.onOpen,
    required this.onScan,
    required this.scanning,
    required this.onDelete,
  });
  final ServerProfile profile;
  final VoidCallback onOpen;
  final VoidCallback onScan;
  final bool scanning;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Material(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainer
              .withValues(alpha: .62),
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                onTap: onOpen,
                leading: CircleAvatar(
                  child: Icon(switch (profile.type) {
                    ServerType.webdav => Icons.cloud_outlined,
                    ServerType.http => Icons.http_rounded,
                    ServerType.ftp => Icons.dns_outlined,
                  }),
                ),
                title: Text(profile.name,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(profile.baseUrl,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                // Named actions in a menu: the bare "new releases" badge read
                // as a warning, and deleting sat one tap away.
                trailing: scanning
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : PopupMenuButton<VoidCallback>(
                        tooltip: context.l10n.serverMoreOptions,
                        onSelected: (action) => action(),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: onScan,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.new_releases_outlined),
                              title: Text(context.l10n.scanNewAlbums),
                            ),
                          ),
                          PopupMenuItem(
                            value: onDelete,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.delete_outline_rounded,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              title: Text(context.l10n.delete),
                            ),
                          ),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Tooltip(
                  message: context.l10n.downloadEntireServer,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _downloadServer(
                        context, context.read<ServerProvider>(), profile),
                    icon: const Icon(Icons.download_for_offline_outlined,
                        size: 20),
                    label: Text(context.l10n.downloadAll,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _Browser extends StatefulWidget {
  const _Browser({required this.provider});
  final ServerProvider provider;

  @override
  State<_Browser> createState() => _BrowserState();
}

class _BrowserState extends State<_Browser> {
  static const _filterThreshold = 15;
  final _filter = TextEditingController();
  Uri? _filteredUri;

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    // A filter only applies to the folder it was typed in.
    if (_filteredUri != provider.currentUri) {
      _filteredUri = provider.currentUri;
      _filter.clear();
    }
    final needle = _filter.text.trim().toLowerCase();
    final entries = needle.isEmpty
        ? provider.entries
        : provider.entries
            .where((entry) => entry.name.toLowerCase().contains(needle))
            .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 12, 8),
          child: Row(
            children: [
              IconButton.filledTonal(
                onPressed:
                    provider.canGoBack ? provider.goBack : provider.disconnect,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  provider.selected!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              if (provider.selected!.type != ServerType.ftp &&
                  provider.currentUri != null &&
                  !provider.loading &&
                  provider.error == null &&
                  provider.entries.isNotEmpty)
                IconButton(
                  tooltip: context.l10n.playThisFolder,
                  onPressed: () => _playRemoteFolder(
                      context, provider, provider.currentUri!),
                  icon: const Icon(Icons.play_circle_outline_rounded),
                ),
              Consumer<DownloadQueueProvider>(
                builder: (context, downloads, _) => Badge(
                  isLabelVisible: downloads.activeCount > 0,
                  label: Text('${downloads.activeCount}'),
                  child: IconButton(
                    onPressed: () => showDownloadQueue(context),
                    tooltip: context.l10n.downloads,
                    // Not the per-track download arrow: this opens the queue.
                    icon: const Icon(Icons.downloading_rounded),
                  ),
                ),
              ),
              IconButton(
                onPressed: provider.disconnect,
                tooltip: context.l10n.disconnect,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        _Breadcrumbs(provider: provider),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            // Inside a folder the button takes that folder: it used to
            // fetch the whole server whatever folder was open.
            child: Tooltip(
              message: provider.canGoBack && provider.currentUri != null
                  ? context.l10n.downloadFolder
                  : context.l10n.downloadEntireServer,
              child: FilledButton.tonalIcon(
                onPressed: () => provider.canGoBack &&
                        provider.currentUri != null
                    ? _startDownload(
                        context,
                        provider,
                        provider.selected!,
                        RemoteAudioEntry(
                          name: _Breadcrumbs.folderName(provider.currentUri!),
                          uri: provider.currentUri!,
                          isDirectory: true,
                        ))
                    : _downloadServer(context, provider, provider.selected!),
                icon: const Icon(Icons.download_for_offline_outlined, size: 20),
                label: Text(
                    provider.canGoBack
                        ? context.l10n.downloadThisFolder
                        : context.l10n.downloadAll,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
        ),
        if (!provider.loading &&
            provider.error == null &&
            provider.entries.length >= _filterThreshold)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: TextField(
              controller: _filter,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.filter_list_rounded),
                hintText: context.l10n.filterFolder,
                suffixIcon: _filter.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: context.l10n.clearFilter,
                        onPressed: () => setState(_filter.clear),
                        icon: const Icon(Icons.clear_rounded),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        Expanded(
          child: provider.loading
              ? const Center(child: CircularProgressIndicator())
              : provider.error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(context.l10n.serverConnectionFailed,
                            textAlign: TextAlign.center),
                      ),
                    )
                  : entries.isEmpty
                      ? Center(
                          child: Text(provider.entries.isEmpty
                              ? context.l10n.noCompatibleTracks
                              : context.l10n.noFilterMatch),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 190),
                          itemCount: entries.length,
                          itemBuilder: (context, index) =>
                              _RemoteTile(entry: entries[index]),
                        ),
        ),
      ],
    );
  }
}

/// Clickable path from the server root to the current folder.
class _Breadcrumbs extends StatelessWidget {
  const _Breadcrumbs({required this.provider});
  final ServerProvider provider;

  @override
  Widget build(BuildContext context) {
    final crumbs = provider.breadcrumbs;
    if (crumbs.length < 2) return const SizedBox.shrink();
    final last = crumbs.length - 1;
    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            for (var index = 0; index <= last; index++) ...[
              if (index > 0) const Icon(Icons.chevron_right_rounded, size: 18),
              TextButton(
                onPressed: index == last || provider.loading
                    ? null
                    : () => provider.goToLevel(index),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  index == 0
                      ? provider.selected!.name
                      : folderName(crumbs[index]),
                  style: TextStyle(
                    fontWeight:
                        index == last ? FontWeight.w800 : FontWeight.w500,
                    color: index == last
                        ? Theme.of(context).colorScheme.onSurface
                        : null,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String folderName(Uri uri) {
    final raw = uri.path.split('/').lastWhere(
          (part) => part.isNotEmpty,
          orElse: () => '/',
        );
    try {
      return Uri.decodeComponent(raw);
    } catch (_) {
      // Servers may expose a literal percent sign that is not an escape.
      return raw;
    }
  }
}

class _RemoteTile extends StatelessWidget {
  const _RemoteTile({required this.entry});
  final RemoteAudioEntry entry;

  @override
  Widget build(BuildContext context) {
    final servers = context.read<ServerProvider>();
    if (entry.isDirectory) {
      return Card(
        child: ListTile(
          onTap: () => servers.openDirectory(entry),
          leading: const CircleAvatar(child: Icon(Icons.folder_outlined)),
          title: Text(
            entry.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: _FolderAvailability(entry: entry),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (servers.selected!.type != ServerType.ftp)
                IconButton(
                  tooltip: context.l10n.playFolder,
                  onPressed: () =>
                      _playRemoteFolder(context, servers, entry.uri),
                  icon: const Icon(Icons.play_circle_outline_rounded),
                ),
              IconButton(
                tooltip: context.l10n.downloadFolder,
                onPressed: () => _downloadFolder(context, servers),
                icon: const Icon(Icons.download_for_offline_outlined),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      );
    }
    final metadata = servers.metadataFor(entry);
    final downloaded = context.select<LibraryProvider, bool>(
      (library) => library.downloadedSourceUris.contains(entry.uri.toString()),
    );
    final downloadProgress = context.select<DownloadQueueProvider, double?>(
      (downloads) => downloads.activeProgress(entry.uri.toString()),
    );
    final preview =
        context.select<PlayerProvider, ({bool selected, bool playing})>(
      (player) => (
        selected: player.current?.uri == entry.uri.toString() ||
            player.current?.sourceUri == entry.uri.toString(),
        playing: player.playing,
      ),
    );
    return Card(
      child: FutureBuilder<RemoteAudioMetadata>(
        future: metadata,
        builder: (context, snapshot) {
          final details = snapshot.data;
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            leading: _RemoteArtwork(metadata: details),
            title: Text(
              details?.title ?? _titleFromFilename(entry.name),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  [
                    if (details != null) context.l10n.metadata(details.artist),
                    if (details?.album != null) details!.album!,
                    if (entry.size != null) _size(context.l10n, entry.size!),
                  ].join(' • '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (downloaded) ...[
                  const SizedBox(height: 6),
                  const _DownloadedBadge(),
                ],
              ],
            ),
            trailing: downloaded && servers.selected!.type == ServerType.ftp
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (servers.selected!.type != ServerType.ftp)
                        IconButton.filledTonal(
                          tooltip: preview.selected && preview.playing
                              ? context.l10n.pause
                              : context.l10n.streamFromServer,
                          onPressed: preview.selected
                              ? context.read<PlayerProvider>().toggle
                              : () => _preview(context, servers, details),
                          icon: Icon(preview.selected && preview.playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded),
                        ),
                      if (!downloaded && downloadProgress != null)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              value: downloadProgress < 0
                                  ? null
                                  : downloadProgress,
                            ),
                          ),
                        )
                      else if (!downloaded)
                        IconButton(
                          tooltip: context.l10n.download,
                          onPressed: () => _download(context, servers),
                          icon: const Icon(Icons.download_rounded),
                        ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  void _downloadFolder(BuildContext context, ServerProvider servers) =>
      _startDownload(context, servers, servers.selected!, entry);

  void _download(BuildContext context, ServerProvider servers) =>
      _startDownload(context, servers, servers.selected!, entry);

  Future<void> _preview(
    BuildContext context,
    ServerProvider servers,
    RemoteAudioMetadata? metadata,
  ) {
    final files = servers.entries.where((item) => !item.isDirectory).toList();
    return _playRemoteFiles(
      context,
      servers,
      files,
      start: entry,
      startMetadata: metadata,
    );
  }

  String _size(AppLocalizations l10n, int bytes) => bytes >= 1048576
      ? l10n.sizeMegabytes((bytes / 1048576).toStringAsFixed(1))
      : l10n.sizeKilobytes((bytes / 1024).toStringAsFixed(0));
}

class _DownloadedBadge extends StatelessWidget {
  const _DownloadedBadge();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? Colors.green.shade200 : Colors.green.shade800;
    final background = dark ? Colors.green.shade900 : Colors.green.shade50;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: foreground),
          const SizedBox(width: 5),
          Text(
            context.l10n.onPhone,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _FolderAvailability extends StatefulWidget {
  const _FolderAvailability({required this.entry});
  final RemoteAudioEntry entry;

  @override
  State<_FolderAvailability> createState() => _FolderAvailabilityState();
}

class _FolderAvailabilityState extends State<_FolderAvailability> {
  late Future<List<RemoteAudioEntry>> _files;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _FolderAvailability oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.uri != widget.entry.uri) _load();
  }

  void _load() {
    final servers = context.read<ServerProvider>();
    _files = servers.filesInFolder(widget.entry.uri);
  }

  @override
  Widget build(BuildContext context) {
    final downloaded = context.select<LibraryProvider, Set<String>>(
      (library) => library.downloadedSourceUris,
    );
    return FutureBuilder<List<RemoteAudioEntry>>(
      future: _files,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.hasError) {
          return Text(context.l10n.folder);
        }
        final files = snapshot.data!;
        final available = files
            .where((file) => downloaded.contains(file.uri.toString()))
            .length;
        if (available == 0) return Text(context.l10n.folder);
        final complete = available == files.length;
        final dark = Theme.of(context).brightness == Brightness.dark;
        final color = complete
            ? (dark ? Colors.green.shade300 : Colors.green.shade700)
            : (dark ? Colors.orange.shade300 : Colors.orange.shade700);
        final label = complete
            ? context.l10n.allOnPhone
            : context.l10n.partlyOnPhone(available, files.length);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              complete ? Icons.check_circle_rounded : Icons.pie_chart_rounded,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RemoteArtwork extends StatelessWidget {
  const _RemoteArtwork({required this.metadata});
  final RemoteAudioMetadata? metadata;

  @override
  Widget build(BuildContext context) {
    final artworkPath = metadata?.artworkPath;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox.square(
        dimension: 56,
        child: artworkPath == null
            ? DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFFE43F83)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child:
                    const Icon(Icons.music_note_rounded, color: Colors.white),
              )
            : Image.file(
                File(artworkPath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.music_note_rounded),
              ),
      ),
    );
  }
}

/// Streams every audio file below [folder], in path order.
Future<void> _playRemoteFolder(
  BuildContext context,
  ServerProvider servers,
  Uri folder,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  messenger.showSnackBar(SnackBar(
    content: Text(l10n.preparingPlayback),
    duration: const Duration(seconds: 30),
  ));
  List<RemoteAudioEntry> files;
  try {
    files = [...await servers.filesInFolder(folder)]..sort(
        (a, b) => a.uri.path.toLowerCase().compareTo(b.uri.path.toLowerCase()));
  } catch (_) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.folderReadFailed)));
    return;
  }
  messenger.hideCurrentSnackBar();
  if (!context.mounted) return;
  if (files.isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.noCompatibleTracks)));
    return;
  }
  await _playRemoteFiles(context, servers, files);
}

/// Plays [files] as one queue starting at [start]. Files already imported
/// play from the phone; the others stream with the profile's credentials.
Future<void> _playRemoteFiles(
  BuildContext context,
  ServerProvider servers,
  List<RemoteAudioEntry> files, {
  RemoteAudioEntry? start,
  RemoteAudioMetadata? startMetadata,
}) async {
  final profile = servers.selected;
  if (profile == null || files.isEmpty) return;
  final library = context.read<LibraryProvider>();
  final player = context.read<PlayerProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final now = DateTime.now().toUtc();
  MusicTrack trackFor(RemoteAudioEntry file) {
    final local = library.trackForSourceUri(file.uri.toString());
    if (local != null) return local;
    final metadata = file.uri == start?.uri ? startMetadata : null;
    final artworkPath = metadata?.artworkPath;
    return MusicTrack(
      id: 'remote:${file.uri}',
      title: metadata?.title ?? _titleFromFilename(file.name),
      artist: metadata?.artist ?? MusicTrack.unknownArtist,
      album: metadata?.album ?? MusicTrack.unknownAlbum,
      artworkUri: artworkPath == null ? null : File(artworkPath).uri.toString(),
      uri: file.uri.toString(),
      metadataRead: true,
      addedAt: now,
    );
  }

  final startIndex =
      start == null ? 0 : files.indexWhere((file) => file.uri == start.uri);
  try {
    await player.playRemoteQueue(
      files.map(trackFor).toList(),
      startIndex: startIndex < 0 ? 0 : startIndex,
      headers:
          servers.remoteService.authorizationHeaders(profile, servers.password),
    );
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.streamFailed)),
    );
  }
}

String _titleFromFilename(String name) {
  final extension = name.lastIndexOf('.');
  var value = extension > 0 ? name.substring(0, extension) : name;
  value = value.replaceAll('_', ' ').trim();
  return value.replaceFirst(RegExp(r'^\d+\s*[-.]\s*'), '').trim();
}
