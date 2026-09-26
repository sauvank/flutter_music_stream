import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/library_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 36),
          Text('Réglages', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.library_add_rounded),
              title: const Text('Importer des morceaux'),
              subtitle: const Text('MP3, M4A, AAC, FLAC, OGG, OPUS et WAV'),
              onTap: context.read<LibraryProvider>().importFiles,
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.cloud_outlined),
              title: Text('Serveurs personnels'),
              subtitle: Text('WebDAV, HTTP et FTP — prochaine étape'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.sync_lock_outlined),
              title: Text('Synchronisation chiffrée'),
              subtitle:
                  Text('Aucun fichier audio ni chemin local ne sera envoyé'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.shield_outlined),
              title: Text('Vie privée'),
              subtitle: Text(
                  'Bibliothèque locale par défaut, aucun secret intégré à l’application'),
            ),
          ),
        ],
      );
}
