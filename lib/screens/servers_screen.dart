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
    return Scaffold(
      appBar: AppBar(title: const Text('Serveurs personnels')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProfile(context),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: servers.profiles.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Ajoutez un serveur WebDAV ou HTTP pour parcourir puis télécharger votre musique.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
              itemCount: servers.profiles.length,
              itemBuilder: (context, index) {
                final profile = servers.profiles[index];
                return Card(
                  child: ListTile(
                    onTap: () => servers.connect(profile),
                    leading: Icon(profile.type == ServerType.webdav
                        ? Icons.cloud_outlined
                        : Icons.http_rounded),
                    title: Text(profile.name),
                    subtitle: Text(
                      profile.baseUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      tooltip: 'Supprimer',
                      onPressed: () => servers.deleteProfile(profile),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                );
              },
            ),
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

class _Browser extends StatelessWidget {
  const _Browser({required this.provider});
  final ServerProvider provider;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed:
                provider.canGoBack ? provider.goBack : provider.disconnect,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(provider.selected!.name),
          actions: [
            IconButton(
                onPressed: provider.disconnect,
                tooltip: 'Déconnecter',
                icon: const Icon(Icons.close)),
          ],
        ),
        body: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : provider.error != null
                ? Center(
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child:
                            Text(provider.error!, textAlign: TextAlign.center)))
                : provider.entries.isEmpty
                    ? const Center(
                        child:
                            Text('Aucun morceau compatible dans ce dossier.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: provider.entries.length,
                        itemBuilder: (context, index) =>
                            _RemoteTile(entry: provider.entries[index]),
                      ),
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
