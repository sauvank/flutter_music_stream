import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/library_provider.dart';

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
                'Ajouter de la musique',
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
              title: const Text('Choisir des fichiers'),
              subtitle: const Text('Sélectionner un ou plusieurs morceaux'),
              onTap: () => Navigator.pop(context, _ImportSource.files),
            ),
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.folder_copy_rounded),
              ),
              title: const Text('Choisir un dossier'),
              subtitle: const Text(
                'Importer récursivement tous les morceaux du dossier',
              ),
              onTap: () => Navigator.pop(context, _ImportSource.directory),
            ),
          ],
        ),
      ),
    ),
  );
  if (source == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final summary = switch (source) {
      _ImportSource.files => await library.importFiles(),
      _ImportSource.directory => await library.importDirectory(),
    };
    if (summary == null) return;
    messenger.showSnackBar(SnackBar(content: Text(importSummaryText(summary))));
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Import impossible. Réessayez.')),
    );
  }
}

String importSummaryText(LocalImportSummary summary) {
  String plural(int count, String singular, String plural) =>
      '$count ${count > 1 ? plural : singular}';
  final parts = [
    plural(summary.added, 'morceau ajouté', 'morceaux ajoutés'),
    if (summary.skipped > 0)
      plural(summary.skipped, 'déjà présent', 'déjà présents'),
    if (summary.failed > 0) plural(summary.failed, 'échec', 'échecs'),
  ];
  return parts.join(' · ');
}
