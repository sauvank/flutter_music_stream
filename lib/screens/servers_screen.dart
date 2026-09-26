import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/remote_audio_entry.dart';
import '../models/server_profile.dart';
import '../providers/library_provider.dart';
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
          child: _ServerHeader(onAdd: () => _showAddProfile(context)),
        ),
        if (servers.profiles.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyServers(onAdd: () => _showAddProfile(context)),
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
                  ],
                  selected: {type},
                  onSelectionChanged: (value) =>
                      setState(() => type = value.single),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: url,
                  keyboardType: TextInputType.url,
                  decoration:
                      const InputDecoration(labelText: 'Adresse HTTPS ou HTTP'),
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
                if (name.text.trim().isEmpty ||
                    uri == null ||
                    !{'http', 'https'}.contains(uri.scheme) ||
                    uri.host.isEmpty) {
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
}

class _ServerHeader extends StatelessWidget {
  const _ServerHeader({required this.onAdd});
  final VoidCallback onAdd;

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
  const _EmptyServers({required this.onAdd});
  final VoidCallback onAdd;

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
                  'Parcourez un serveur WebDAV ou HTTP, puis gardez vos morceaux préférés hors connexion.',
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
    required this.onDelete,
  });
  final ServerProfile profile;
  final VoidCallback onOpen;
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
              child: Icon(profile.type == ServerType.webdav
                  ? Icons.cloud_outlined
                  : Icons.http_rounded),
            ),
            title: Text(profile.name,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(
              profile.baseUrl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              tooltip: 'Supprimer',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
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
    return Card(
      child: ListTile(
        onTap: entry.isDirectory ? () => servers.openDirectory(entry) : null,
        leading: Icon(entry.isDirectory
            ? Icons.folder_outlined
            : Icons.audio_file_outlined),
        title: Text(entry.name),
        subtitle: entry.size == null || entry.isDirectory
            ? null
            : Text(_size(entry.size!)),
        trailing: entry.isDirectory
            ? const Icon(Icons.chevron_right)
            : IconButton(
                tooltip: 'Télécharger',
                onPressed: context.watch<LibraryProvider>().isImporting
                    ? null
                    : () => _download(context, servers),
                icon: const Icon(Icons.download_rounded),
              ),
      ),
    );
  }

  Future<void> _download(BuildContext context, ServerProvider servers) async {
    final profile = servers.selected!;
    try {
      final added = await context.read<LibraryProvider>().importRemote(
            name: entry.name,
            uri: entry.uri,
            headers: servers.remoteService
                .authorizationHeaders(profile, servers.password),
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(added
            ? '${entry.name} ajouté hors ligne.'
            : '${entry.name} est déjà présent.'),
      ));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Téléchargement impossible.')));
    }
  }

  String _size(int bytes) => bytes >= 1048576
      ? '${(bytes / 1048576).toStringAsFixed(1)} Mo'
      : '${(bytes / 1024).toStringAsFixed(0)} Ko';
}
