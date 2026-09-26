import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/music_track.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/track_artwork.dart';

enum _LibraryMode { tracks, artists, albums, genres }

extension on _LibraryMode {
  String get label => switch (this) {
        _LibraryMode.tracks => 'Morceaux',
        _LibraryMode.artists => 'Artistes',
        _LibraryMode.albums => 'Albums',
        _LibraryMode.genres => 'Genres',
      };

  IconData get icon => switch (this) {
        _LibraryMode.tracks => Icons.queue_music_rounded,
        _LibraryMode.artists => Icons.person_rounded,
        _LibraryMode.albums => Icons.album_rounded,
        _LibraryMode.genres => Icons.category_rounded,
      };

  String valueFor(MusicTrack track) => switch (this) {
        _LibraryMode.tracks => track.title,
        _LibraryMode.artists => track.artist,
        _LibraryMode.albums => track.album,
        _LibraryMode.genres => track.genre,
      };
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  _LibraryMode _mode = _LibraryMode.tracks;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final tracks = library.tracks;
    final groups = _mode == _LibraryMode.tracks
        ? const <String, List<MusicTrack>>{}
        : _group(tracks, _mode);
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title:
              Text(_mode == _LibraryMode.tracks ? 'MusicStream' : _mode.label),
          actions: [
            PopupMenuButton<_LibraryMode>(
              tooltip: 'Organiser la bibliothèque',
              initialValue: _mode,
              onSelected: (value) => setState(() => _mode = value),
              itemBuilder: (_) => _LibraryMode.values
                  .map((mode) => PopupMenuItem(
                        value: mode,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(mode.icon),
                          title: Text(mode.label),
                        ),
                      ))
                  .toList(),
              icon: Icon(_mode.icon),
            ),
            IconButton(
              tooltip: library.favoritesOnly ? 'Afficher tout' : 'Favoris',
              onPressed: library.toggleFavoritesFilter,
              icon: Icon(library.favoritesOnly
                  ? Icons.favorite
                  : Icons.favorite_border),
            ),
            if (library.allTracks.isNotEmpty)
              IconButton(
                tooltip: 'Importer des morceaux',
                onPressed: library.isImporting ? null : library.importFiles,
                icon: library.isImporting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_rounded),
              ),
            const SizedBox(width: 8),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          sliver: SliverToBoxAdapter(
            child: SearchBar(
              hintText: 'Titre, artiste, album ou genre',
              leading: const Icon(Icons.search),
              onChanged: library.setQuery,
            ),
          ),
        ),
        if (library.allTracks.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyLibrary(importing: library.isImporting),
          )
        else if (tracks.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _NoResults(),
          )
        else if (_mode == _LibraryMode.tracks)
          _trackSliver(tracks)
        else
          _groupSliver(context, groups),
      ],
    );
  }

  SliverPadding _trackSliver(List<MusicTrack> tracks) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
        sliver: SliverList.builder(
          itemCount: tracks.length,
          itemBuilder: (context, index) =>
              _TrackTile(track: tracks[index], queue: tracks),
        ),
      );

  SliverPadding _groupSliver(
    BuildContext context,
    Map<String, List<MusicTrack>> groups,
  ) =>
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
        sliver: SliverList.builder(
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final entry = groups.entries.elementAt(index);
            return Card(
              child: ListTile(
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => _CollectionScreen(
                    title: entry.key,
                    tracks: entry.value,
                  ),
                )),
                leading: TrackArtwork(track: entry.value.first, size: 52),
                title: Text(entry.key,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(_trackCount(entry.value.length)),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            );
          },
        ),
      );

  Map<String, List<MusicTrack>> _group(
    List<MusicTrack> tracks,
    _LibraryMode mode,
  ) {
    final grouped = <String, List<MusicTrack>>{};
    for (final track in tracks) {
      grouped.putIfAbsent(mode.valueFor(track), () => []).add(track);
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    return Map.fromEntries(entries);
  }
}

class _CollectionScreen extends StatelessWidget {
  const _CollectionScreen({required this.title, required this.tracks});

  final String title;
  final List<MusicTrack> tracks;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
          itemCount: tracks.length,
          itemBuilder: (context, index) =>
              _TrackTile(track: tracks[index], queue: tracks),
        ),
      );
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
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: importing
                    ? null
                    : context.read<LibraryProvider>().importFiles,
                icon: importing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(importing ? 'Import…' : 'Importer des morceaux'),
              ),
            ],
          ),
        ),
      );
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Aucun morceau ne correspond aux filtres actuels.',
            textAlign: TextAlign.center,
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
          leading: TrackArtwork(track: track, size: 48),
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

String _trackCount(int count) => '$count morceau${count > 1 ? 'x' : ''}';
