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
                '${servers.profiles.length} source${servers.profiles.length > 1 ? 's' : ''}',
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
                  onDelete: () => servers.deleteProfile(profile),
                );
              },
            ),
          ),
        ],
      ],
    );
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
          title: const Text('Ajouter un serveur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nom')),
                const SizedBox(height: 12),
                SegmentedButton<ServerType>(
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
                        ? 'Adresse FTP'
                        : 'Adresse HTTPS ou HTTP',
                  ),
                ),
                if (type == ServerType.ftp)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'FTP transmet les identifiants et les fichiers sans chiffrement.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ),
                TextField(
                    controller: username,
                    decoration: const InputDecoration(
                        labelText: 'Utilisateur (facultatif)')),
                TextField(
                    controller: password,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Mot de passe')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler')),
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
              child: const Text('Enregistrer'),
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
              ? 'Référence créée'
              : result.newAlbums.isEmpty
                  ? 'Bibliothèque à jour'
                  : 'Nouveaux albums'),
          content: result.baselineCreated
              ? Text(
                  '${result.totalTracks} morceau${result.totalTracks > 1 ? 'x' : ''} mémorisé${result.totalTracks > 1 ? 's' : ''}. Les prochains scans signaleront uniquement les nouveautés.',
                )
              : result.newAlbums.isEmpty
                  ? Text(
                      'Aucun nouveau morceau parmi les ${result.totalTracks} éléments analysés.',
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${result.newTrackCount} nouveau${result.newTrackCount > 1 ? 'x' : ''} morceau${result.newTrackCount > 1 ? 'x' : ''} :',
                          ),
                          const SizedBox(height: 12),
                          ...result.newAlbums.map(
                            (album) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.album_outlined),
                              title: Text(album.name),
                              trailing: Text('${album.trackCount}'),
                            ),
                          ),
                        ],
                      ),
                    ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’analyser ce serveur pour le moment.'),
        ),
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
              title: const Text('Choisir un fichier JSON'),
              onTap: () => Navigator.pop(sheetContext, 'file'),
            ),
            ListTile(
              leading: const Icon(Icons.content_paste_rounded),
              title: const Text('Coller le contenu JSON'),
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
        const SnackBar(content: Text('Impossible de lire ce fichier.')),
      );
    }
  }

  Future<void> _importProfilesFromPaste(BuildContext context) async {
    var content = '';
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Coller une configuration'),
        content: SizedBox(
          width: 560,
          child: TextFormField(
            autofocus: true,
            minLines: 8,
            maxLines: 14,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: const InputDecoration(
              hintText: '[{"name": "Mon serveur", ...}]',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => content = value,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (content.trim().isNotEmpty) {
                Navigator.pop(dialogContext, content);
              }
            },
            child: const Text('Importer'),
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
            ? 'Ce serveur est déjà configuré.'
            : '$count serveur${count > 1 ? 's' : ''} importé${count > 1 ? 's' : ''}.'),
      ));
    } on FormatException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le contenu JSON est invalide.')),
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
                        'VOS SOURCES',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      Text(
                        'Serveurs personnels',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Importer un fichier JSON',
                  onPressed: onImport,
                  icon: const Icon(Icons.file_download_outlined),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Ajouter un serveur',
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Votre musique,\noù qu’elle vive.',
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
                  'Connectez votre\ncollection',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Parcourez un serveur WebDAV, HTTP ou FTP, puis gardez vos morceaux préférés hors connexion.',
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
                  label: const Text('Ajouter un serveur'),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: onImport,
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('Importer un fichier JSON'),
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
                  tooltip: 'Rechercher de nouveaux albums',
                  onPressed: scanning ? null : onScan,
                  icon: scanning
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.new_releases_outlined),
                ),
                IconButton(
                  tooltip: 'Supprimer',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ),
        ),
      );
}

class _Browser extends StatelessWidget {
  const _Browser({required this.provider});
  final ServerProvider provider;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 12, 8),
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: provider.canGoBack
                      ? provider.goBack
                      : provider.disconnect,
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
                Consumer<DownloadQueueProvider>(
                  builder: (context, downloads, _) => Badge(
                    isLabelVisible: downloads.activeCount > 0,
                    label: Text('${downloads.activeCount}'),
                    child: IconButton(
                      onPressed: () => _showDownloadQueue(context),
                      tooltip: 'Téléchargements',
                      icon: const Icon(Icons.download_rounded),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: provider.disconnect,
                  tooltip: 'Déconnecter',
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : provider.error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(provider.error!,
                              textAlign: TextAlign.center),
                        ),
                      )
                    : provider.entries.isEmpty
                        ? const Center(
                            child: Text(
                                'Aucun morceau compatible dans ce dossier.'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 190),
                            itemCount: provider.entries.length,
                            itemBuilder: (context, index) =>
                                _RemoteTile(entry: provider.entries[index]),
                          ),
          ),
        ],
      );
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
              IconButton(
                tooltip: 'Télécharger tout le dossier',
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
    final preview =
        context.select<PlayerProvider, ({bool selected, bool playing})>(
      (player) => (
        selected: player.current?.uri == entry.uri.toString(),
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
            subtitle: Text(
              [
                if (details != null) details.artist,
                if (details?.album != null) details!.album!,
                if (entry.size != null) _size(entry.size!),
              ].join(' • '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (servers.selected!.type != ServerType.ftp)
                  IconButton.filledTonal(
                    tooltip: preview.selected && preview.playing
                        ? 'Mettre en pause'
                        : 'Écouter depuis le serveur',
                    onPressed: preview.selected
                        ? context.read<PlayerProvider>().toggle
                        : () => _preview(context, servers, details),
                    icon: Icon(preview.selected && preview.playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded),
                  ),
                IconButton(
                  tooltip: 'Télécharger',
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
            ? '${entry.name} ajouté aux téléchargements en arrière-plan.'
            : '${entry.name} est déjà en cours de téléchargement.'),
      ));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Téléchargement impossible.')));
    }
  }

  Future<void> _preview(
    BuildContext context,
    ServerProvider servers,
    RemoteAudioMetadata? metadata,
  ) async {
    final profile = servers.selected!;
    final artworkPath = metadata?.artworkPath;
    final track = MusicTrack(
      id: 'remote:${entry.uri}',
      title: metadata?.title ?? _titleFromFilename(entry.name),
      artist: metadata?.artist ?? 'Artiste inconnu',
      album: metadata?.album ?? 'Album inconnu',
      artworkUri: artworkPath == null ? null : File(artworkPath).uri.toString(),
      uri: entry.uri.toString(),
      metadataRead: true,
      addedAt: DateTime.now().toUtc(),
    );
    try {
      await context.read<PlayerProvider>().playRemote(
            track,
            headers: servers.remoteService
                .authorizationHeaders(profile, servers.password),
          );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lecture depuis le serveur impossible.')),
      );
    }
  }

  String _size(int bytes) => bytes >= 1048576
      ? '${(bytes / 1048576).toStringAsFixed(1)} Mo'
      : '${(bytes / 1024).toStringAsFixed(0)} Ko';
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
          return const Text('Dossier');
        }
        final files = snapshot.data!;
        final available = files
            .where((file) => downloaded.contains(file.uri.toString()))
            .length;
        if (available == 0) return const Text('Dossier');
        final complete = available == files.length;
        final dark = Theme.of(context).brightness == Brightness.dark;
        final color = complete
            ? (dark ? Colors.green.shade300 : Colors.green.shade700)
            : (dark ? Colors.orange.shade300 : Colors.orange.shade700);
        final label = complete
            ? 'Tout sur le téléphone'
            : '$available/${files.length} sur le téléphone';
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
  String _status = 'Analyse du dossier…';
  double? _progress;
  int? _queued;
  Object? _error;
  String _stage = 'inventaire';

  String get _errorMessage {
    final error = _error;
    if (error is DioException) {
      final status = error.response?.statusCode;
      return status == null
          ? 'Connexion interrompue pendant $_stage du dossier.'
          : 'Le serveur a renvoyé une erreur HTTP $status pendant $_stage du dossier.';
    }
    if (error is StateError) return error.message.toString();
    return 'Impossible de terminer $_stage du dossier.';
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
          _status = 'Aucun morceau compatible dans ce dossier.';
          _queued = 0;
          _progress = 1;
        });
        return;
      }
      setState(() {
        _status = profile.type == ServerType.ftp
            ? 'Téléchargement de ${files.length} morceau${files.length > 1 ? 'x' : ''}…'
            : 'Ajout de ${files.length} morceaux à la file…';
      });
      if (profile.type == ServerType.ftp) {
        _stage = 'transfert FTP';
        await _downloadFtp(profile, files);
        return;
      }
      _stage = 'mise en file';
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
      debugPrint('Folder download failed: stage=$_stage, '
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
              _status = 'Téléchargement ${index + 1} / ${files.length}';
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
      _status = [
        '$added ajouté${added > 1 ? 's' : ''}',
        if (skipped > 0) '$skipped déjà présent${skipped > 1 ? 's' : ''}',
        if (failed > 0) '$failed échec${failed > 1 ? 's' : ''}',
      ].join(' • ');
      _progress = 1;
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Télécharger « ${widget.entry.name} »'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Text(_errorMessage)
            else ...[
              Text(widget.servers.selected?.type == ServerType.ftp
                  ? _status
                  : _queued == null
                      ? _status
                      : _queued == 0
                          ? 'Aucun nouveau téléchargement à ajouter.'
                          : '$_queued morceau${_queued! > 1 ? 'x' : ''} ajouté${_queued! > 1 ? 's' : ''}. Vous pouvez fermer cette fenêtre : le téléchargement continue en arrière-plan.'),
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
                  ? 'Fermer'
                  : 'Continuer en arrière-plan'),
            ),
        ],
      );
}

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
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'Téléchargements',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Expanded(
              child: downloads.records.isEmpty
                  ? const Center(child: Text('Aucun téléchargement.'))
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
                                Text(_downloadStatusLabel(record)),
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

class _DownloadActions extends StatelessWidget {
  const _DownloadActions({required this.record});
  final TaskRecord record;

  @override
  Widget build(BuildContext context) {
    final downloads = context.read<DownloadQueueProvider>();
    if (record.status == TaskStatus.paused) {
      return IconButton(
        tooltip: 'Reprendre',
        onPressed: () => downloads.resume(record.taskId),
        icon: const Icon(Icons.play_arrow_rounded),
      );
    }
    if (record.status == TaskStatus.running) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Mettre en pause',
            onPressed: () => downloads.pause(record.taskId),
            icon: const Icon(Icons.pause_rounded),
          ),
          IconButton(
            tooltip: 'Annuler',
            onPressed: () => downloads.cancel(record.taskId),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      );
    }
    if (record.status == TaskStatus.enqueued ||
        record.status == TaskStatus.waitingToRetry) {
      return IconButton(
        tooltip: 'Annuler',
        onPressed: () => downloads.cancel(record.taskId),
        icon: const Icon(Icons.close_rounded),
      );
    }
    if (record.status == TaskStatus.failed ||
        record.status == TaskStatus.notFound) {
      return IconButton(
        tooltip: 'Réessayer',
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

String _downloadStatusLabel(TaskRecord record) => switch (record.status) {
      TaskStatus.enqueued => 'En attente',
      TaskStatus.running => 'Téléchargement en cours',
      TaskStatus.complete => 'Disponible hors ligne',
      TaskStatus.notFound => 'Fichier introuvable',
      TaskStatus.failed => record.exception?.description.isNotEmpty == true
          ? 'Échec : ${record.exception!.description}'
          : 'Échec du téléchargement',
      TaskStatus.canceled => 'Annulé',
      TaskStatus.waitingToRetry => 'Nouvelle tentative en attente',
      TaskStatus.paused => 'En pause',
    };

String _titleFromFilename(String name) {
  final extension = name.lastIndexOf('.');
  var value = extension > 0 ? name.substring(0, extension) : name;
  value = value.replaceAll('_', ' ').trim();
  return value.replaceFirst(RegExp(r'^\d+\s*[-.]\s*'), '').trim();
}
