import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

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
    final name = TextEditingController();
    final url = TextEditingController(text: 'https://');
    final username = TextEditingController();
    final password = TextEditingController();
    var type = ServerType.webdav;
    final result = await showDialog<(ServerProfile, String)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.l10n.addServer),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: name,
                    decoration: InputDecoration(labelText: context.l10n.name)),
                const SizedBox(height: 12),
                SegmentedButton<ServerType>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                        value: ServerType.webdav, label: Text('WebDAV')),
                    ButtonSegment(value: ServerType.http, label: Text('HTTP')),
                    ButtonSegment(value: ServerType.ftp, label: Text('FTP')),
                  ],
                  selected: {type},
                  onSelectionChanged: (value) => setState(() {
                    type = value.single;
                    if (url.text == 'https://' || url.text == 'ftp://') {
                      url.text = type == ServerType.ftp ? 'ftp://' : 'https://';
                    }
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: url,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: type == ServerType.ftp
                        ? context.l10n.ftpAddress
                        : context.l10n.httpAddress,
                  ),
                ),
                if (type == ServerType.ftp)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      context.l10n.ftpUnencrypted,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ),
                TextField(
                    controller: username,
                    decoration: InputDecoration(
                        labelText: context.l10n.usernameOptional)),
                TextField(
                    controller: password,
                    obscureText: true,
                    decoration:
                        InputDecoration(labelText: context.l10n.password)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.cancel)),
            FilledButton(
              onPressed: () {
                final uri = Uri.tryParse(url.text.trim());
                final validScheme = type == ServerType.ftp
                    ? uri?.scheme == 'ftp'
                    : {'http', 'https'}.contains(uri?.scheme);
                if (name.text.trim().isEmpty ||
                    uri == null ||
                    !validScheme ||
                    uri.host.isEmpty ||
                    uri.userInfo.isNotEmpty) {
                  return;
                }
                Navigator.pop(
                  context,
                  (
                    ServerProfile(
                      id: const Uuid().v4(),
                      name: name.text.trim(),
                      baseUrl: uri.toString(),
                      type: type,
                      username: username.text.trim(),
                    ),
                    password.text,
                  ),
                );
              },
              child: Text(context.l10n.save),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    url.dispose();
    username.dispose();
    password.dispose();
    if (result != null && context.mounted) {
      await context.read<ServerProvider>().addProfile(result.$1, result.$2);
    }
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
          children: [
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
                Consumer<DownloadQueueProvider>(
                  builder: (context, downloads, _) => downloads.records.isEmpty
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Badge(
                            isLabelVisible: downloads.activeCount > 0,
                            label: Text('${downloads.activeCount}'),
                            child: IconButton.filledTonal(
                              tooltip: context.l10n.downloads,
                              onPressed: () => _showDownloadQueue(context),
                              icon: const Icon(Icons.download_rounded),
                            ),
                          ),
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
            const SizedBox(height: 28),
            Text(
              context.l10n.serversHeadline,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.04,
                    letterSpacing: -1.6,
                  ),
            ),
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
          child: ListTile(
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
            subtitle: Text(
              profile.baseUrl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: context.l10n.scanNewAlbums,
                  onPressed: scanning ? null : onScan,
                  icon: scanning
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.new_releases_outlined),
                ),
                IconButton(
                  tooltip: context.l10n.delete,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
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
                    onPressed: () => _showDownloadQueue(context),
                    tooltip: context.l10n.downloads,
                    icon: const Icon(Icons.download_rounded),
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
                      : _folderName(crumbs[index]),
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

  static String _folderName(Uri uri) {
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
                      if (!downloaded)
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

  Future<void> _downloadFolder(
    BuildContext context,
    ServerProvider servers,
  ) =>
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _FolderDownloadDialog(
          entry: entry,
          servers: servers,
          downloads: context.read<DownloadQueueProvider>(),
        ),
      );

  Future<void> _download(BuildContext context, ServerProvider servers) async {
    final profile = servers.selected!;
    if (profile.type == ServerType.ftp) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _FolderDownloadDialog(
          entry: entry,
          servers: servers,
          downloads: context.read<DownloadQueueProvider>(),
        ),
      );
      return;
    }
    try {
      final added = await context.read<DownloadQueueProvider>().enqueueAll(
        [entry],
        headers: servers.remoteService
            .authorizationHeaders(profile, servers.password),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(added > 0
            ? context.l10n.queuedForDownload(entry.name)
            : context.l10n.alreadyDownloading(entry.name)),
      ));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.downloadFailed)));
    }
  }

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

class _FolderDownloadDialog extends StatefulWidget {
  const _FolderDownloadDialog({
    required this.entry,
    required this.servers,
    required this.downloads,
  });

  final RemoteAudioEntry entry;
  final ServerProvider servers;
  final DownloadQueueProvider downloads;

  @override
  State<_FolderDownloadDialog> createState() => _FolderDownloadDialogState();
}

class _FolderDownloadDialogState extends State<_FolderDownloadDialog> {
  String Function(AppLocalizations) _status = (l10n) => l10n.scanningFolder;
  double? _progress;
  int? _queued;
  Object? _error;
  _FolderStage _stage = _FolderStage.inventory;

  String _errorMessage(AppLocalizations l10n) {
    final error = _error;
    final stage = switch (_stage) {
      _FolderStage.inventory => l10n.stageInventory,
      _FolderStage.ftp => l10n.stageFtp,
      _FolderStage.queue => l10n.stageQueue,
    };
    if (error is DioException) {
      final status = error.response?.statusCode;
      return status == null
          ? l10n.folderConnectionLost(stage)
          : l10n.folderHttpError(status, stage);
    }
    // The only StateError while listing is the folder size guard.
    if (error is StateError) return l10n.folderTooLarge;
    return l10n.folderFailed(stage);
  }

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final profile = widget.servers.selected!;
      final files = widget.entry.isDirectory
          ? await widget.servers.remoteService.listRecursively(
              profile,
              widget.entry.uri,
              widget.servers.password,
            )
          : [widget.entry];
      if (!mounted) return;
      if (files.isEmpty) {
        setState(() {
          _status = (l10n) => l10n.noCompatibleTracks;
          _queued = 0;
          _progress = 1;
        });
        return;
      }
      setState(() {
        _status = profile.type == ServerType.ftp
            ? (l10n) => l10n.downloadingTracks(files.length)
            : (l10n) => l10n.queueingTracks(files.length);
      });
      if (profile.type == ServerType.ftp) {
        _stage = _FolderStage.ftp;
        await _downloadFtp(profile, files);
        return;
      }
      _stage = _FolderStage.queue;
      final queued = await widget.downloads.enqueueAll(
        files,
        headers: widget.servers.remoteService.authorizationHeaders(
          profile,
          widget.servers.password,
        ),
      );
      if (!mounted) return;
      setState(() {
        _queued = queued;
        _progress = 1;
      });
    } catch (error) {
      final status = error is DioException ? error.response?.statusCode : null;
      debugPrint('Folder download failed: stage=${_stage.name}, '
          'type=${error.runtimeType}, httpStatus=$status');
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  Future<void> _downloadFtp(
    ServerProfile profile,
    List<RemoteAudioEntry> files,
  ) async {
    final library = context.read<LibraryProvider>();
    final root = Directory(
      p.join((await getTemporaryDirectory()).path, 'ftp_downloads'),
    );
    await root.create(recursive: true);
    var added = 0;
    var skipped = 0;
    var failed = 0;
    for (var index = 0; index < files.length; index++) {
      final file = files[index];
      final digest =
          sha256.convert(utf8.encode(file.uri.toString())).toString();
      final temporary = File(
        p.join(
            root.path, '${digest.substring(0, 24)}${p.extension(file.name)}'),
      );
      try {
        await widget.servers.remoteService.downloadFtp(
          profile,
          file,
          widget.servers.password,
          temporary.path,
          onProgress: (received, total) {
            if (!mounted) return;
            final fileProgress = total > 0 ? received / total : 0.0;
            setState(() {
              _status =
                  (l10n) => l10n.downloadProgress(index + 1, files.length);
              _progress = (index + fileProgress) / files.length;
            });
          },
        );
        final imported = await library.importDownloadedFile(
          sourcePath: temporary.path,
          originalName: file.name,
          sourceUri: file.uri.toString(),
        );
        imported ? added++ : skipped++;
      } catch (_) {
        failed++;
        if (await temporary.exists()) await temporary.delete();
      }
      if (mounted) setState(() => _progress = (index + 1) / files.length);
    }
    if (!mounted) return;
    setState(() {
      _queued = added;
      _status = (l10n) => [
            l10n.addedCount(added),
            if (skipped > 0) l10n.importSkipped(skipped),
            if (failed > 0) l10n.importFailures(failed),
          ].join(' • ');
      _progress = 1;
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(context.l10n.downloadTitle(widget.entry.name)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Text(_errorMessage(context.l10n))
            else ...[
              Text(widget.servers.selected?.type == ServerType.ftp
                  ? _status(context.l10n)
                  : _queued == null
                      ? _status(context.l10n)
                      : _queued == 0
                          ? context.l10n.nothingNewToDownload
                          : context.l10n.folderQueued(_queued!)),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress),
            ],
          ],
        ),
        actions: [
          if (_queued != null || _error != null)
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_error != null ||
                      widget.servers.selected?.type == ServerType.ftp
                  ? context.l10n.close
                  : context.l10n.continueInBackground),
            ),
        ],
      );
}

enum _FolderStage { inventory, ftp, queue }

Future<void> _showDownloadQueue(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _DownloadQueueSheet(),
    );

class _DownloadQueueSheet extends StatelessWidget {
  const _DownloadQueueSheet();

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadQueueProvider>();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .68,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
              child: Text(
                context.l10n.downloads,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (downloads.hasFailed)
                    ActionChip(
                      avatar: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(context.l10n.retryFailed),
                      onPressed: downloads.retryFailed,
                    ),
                  if (downloads.hasClearable)
                    ActionChip(
                      avatar: const Icon(Icons.clear_all_rounded, size: 18),
                      label: Text(context.l10n.clearFinished),
                      onPressed: downloads.clearFinished,
                    ),
                  if (downloads.activeCount > 0)
                    ActionChip(
                      avatar: const Icon(Icons.cancel_outlined, size: 18),
                      label: Text(context.l10n.cancelAll),
                      onPressed: () => _confirmCancelAll(context, downloads),
                    ),
                ],
              ),
            ),
            Expanded(
              child: downloads.records.isEmpty
                  ? Center(child: Text(context.l10n.noDownloads))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      itemCount: downloads.records.length,
                      itemBuilder: (context, index) {
                        final record = downloads.records[index];
                        return Card(
                          child: ListTile(
                            leading: _downloadStatusIcon(record.status),
                            title: Text(
                              record.task.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    _downloadStatusLabel(context.l10n, record)),
                                if (record.status == TaskStatus.running ||
                                    record.status == TaskStatus.enqueued)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: LinearProgressIndicator(
                                      value: record.progress >= 0
                                          ? record.progress
                                          : null,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: _DownloadActions(record: record),
                          ),
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

Future<void> _confirmCancelAll(
  BuildContext context,
  DownloadQueueProvider downloads,
) async {
  final count = downloads.activeCount;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.l10n.cancelAllTitle),
      content: Text(context.l10n.cancelAllBody(count)),
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
  if (confirmed == true) await downloads.cancelAll();
}

class _DownloadActions extends StatelessWidget {
  const _DownloadActions({required this.record});
  final TaskRecord record;

  @override
  Widget build(BuildContext context) {
    final downloads = context.read<DownloadQueueProvider>();
    if (record.status == TaskStatus.paused) {
      return IconButton(
        tooltip: context.l10n.resume,
        onPressed: () => downloads.resume(record.taskId),
        icon: const Icon(Icons.play_arrow_rounded),
      );
    }
    if (record.status == TaskStatus.running) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: context.l10n.pause,
            onPressed: () => downloads.pause(record.taskId),
            icon: const Icon(Icons.pause_rounded),
          ),
          IconButton(
            tooltip: context.l10n.cancel,
            onPressed: () => downloads.cancel(record.taskId),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      );
    }
    if (record.status == TaskStatus.enqueued ||
        record.status == TaskStatus.waitingToRetry) {
      return IconButton(
        tooltip: context.l10n.cancel,
        onPressed: () => downloads.cancel(record.taskId),
        icon: const Icon(Icons.close_rounded),
      );
    }
    if (record.status == TaskStatus.failed ||
        record.status == TaskStatus.notFound) {
      return IconButton(
        tooltip: context.l10n.retry,
        onPressed: () => downloads.retry(record.taskId),
        icon: const Icon(Icons.refresh_rounded),
      );
    }
    return const SizedBox.shrink();
  }
}

Widget _downloadStatusIcon(TaskStatus status) => switch (status) {
      TaskStatus.complete =>
        const Icon(Icons.check_circle, color: Colors.green),
      TaskStatus.failed ||
      TaskStatus.notFound =>
        const Icon(Icons.error_outline, color: Colors.red),
      TaskStatus.canceled => const Icon(Icons.cancel_outlined),
      TaskStatus.paused => const Icon(Icons.pause_circle_outline),
      _ => const Icon(Icons.download_rounded),
    };

String _downloadStatusLabel(AppLocalizations l10n, TaskRecord record) =>
    switch (record.status) {
      TaskStatus.enqueued => l10n.statusEnqueued,
      TaskStatus.running => l10n.statusRunning,
      TaskStatus.complete => l10n.statusComplete,
      TaskStatus.notFound => l10n.statusNotFound,
      TaskStatus.failed => record.exception?.description.isNotEmpty == true
          ? l10n.statusFailedWithReason(record.exception!.description)
          : l10n.statusFailed,
      TaskStatus.canceled => l10n.statusCanceled,
      TaskStatus.waitingToRetry => l10n.statusWaitingToRetry,
      TaskStatus.paused => l10n.statusPaused,
    };

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
