import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/music_track.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final tracks = library.tracks;
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('MusicStream'),
          actions: [
            IconButton(
              tooltip: library.favoritesOnly ? 'Afficher tout' : 'Favoris',
              onPressed: library.toggleFavoritesFilter,
              icon: Icon(library.favoritesOnly
                  ? Icons.favorite
                  : Icons.favorite_border),
            ),
            const SizedBox(width: 8),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          sliver: SliverToBoxAdapter(
            child: SearchBar(
              hintText: 'Titre, artiste ou album',
              leading: const Icon(Icons.search),
              onChanged: library.setQuery,
            ),
          ),
        ),
        if (tracks.isEmpty)
          SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyLibrary(importing: library.isImporting))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
            sliver: SliverList.builder(
              itemCount: tracks.length,
              itemBuilder: (context, index) =>
                  _TrackTile(track: tracks[index], queue: tracks),
            ),
          ),
      ],
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.importing});
  final bool importing;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.headphones_rounded,
                  size: 88, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 20),
              Text('Votre musique, partout',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                  'Importez vos fichiers audio. Ils restent sur cet appareil et sont disponibles hors connexion.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: importing
                    ? null
                    : context.read<LibraryProvider>().importFiles,
                icon: importing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add),
                label: Text(importing ? 'Import…' : 'Importer des morceaux'),
              ),
            ],
          ),
        ),
      );
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({required this.track, required this.queue});
  final MusicTrack track;
  final List<MusicTrack> queue;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          onTap: () => context.read<PlayerProvider>().playTrack(track, queue),
          leading: const CircleAvatar(child: Icon(Icons.music_note_rounded)),
          title:
              Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${track.artist} • ${track.album}',
              maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: IconButton(
            tooltip:
                track.favorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
            onPressed: () =>
                context.read<LibraryProvider>().toggleFavorite(track.id),
            icon: Icon(track.favorite ? Icons.favorite : Icons.favorite_border),
          ),
        ),
      );
}
