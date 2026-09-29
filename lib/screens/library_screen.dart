import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/music_playlist.dart';
import '../models/music_track.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/track_artwork.dart';
import '../widgets/import_music_sheet.dart';

enum _LibraryMode { tracks, history, artists, albums, genres, playlists }

extension on _LibraryMode {
  String get label => switch (this) {
        _LibraryMode.tracks => 'Morceaux',
        _LibraryMode.history => 'Historique',
        _LibraryMode.artists => 'Artistes',
        _LibraryMode.albums => 'Albums',
        _LibraryMode.genres => 'Genres',
        _LibraryMode.playlists => 'Playlists',
      };

  IconData get icon => switch (this) {
        _LibraryMode.tracks => Icons.music_note_rounded,
        _LibraryMode.history => Icons.history_rounded,
        _LibraryMode.artists => Icons.mic_external_on_rounded,
        _LibraryMode.albums => Icons.album_rounded,
        _LibraryMode.genres => Icons.auto_awesome_rounded,
        _LibraryMode.playlists => Icons.queue_music_rounded,
      };

  String valueFor(MusicTrack track) => switch (this) {
        _LibraryMode.tracks => track.title,
        _LibraryMode.history => '',
        _LibraryMode.artists => track.artist,
        _LibraryMode.albums => track.album,
        _LibraryMode.genres => track.genre,
        _LibraryMode.playlists => '',
      };
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen> {
  _LibraryMode _mode = _LibraryMode.tracks;
  final _TrackSelection _selection = _TrackSelection();

  /// Consumes a system back press to leave selection mode.
  bool handleBack() {
    if (!_selection.active) return false;
    _selection.clear();
    return true;
  }

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
        value: _selection,
        child: Stack(
          children: [
            _content(context),
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: _SelectionBar(
                visible: switch (_mode) {
                  _LibraryMode.tracks =>
                    context.watch<LibraryProvider>().tracks,
                  _LibraryMode.history =>
                    context.watch<LibraryProvider>().listeningHistory,
                  _ => const <MusicTrack>[],
                },
              ),
            ),
          ],
        ),
      );

  Widget _content(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final tracks =
        _mode == _LibraryMode.playlists ? const <MusicTrack>[] : library.tracks;
    final history = _mode == _LibraryMode.history
        ? library.listeningHistory
        : const <MusicTrack>[];
    final groups = _mode == _LibraryMode.tracks ||
            _mode == _LibraryMode.history ||
            _mode == _LibraryMode.playlists
        ? const <String, List<MusicTrack>>{}
        : _group(tracks, _mode);
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _LibraryHeader(
            count: library.trackCount,
            importing: library.isImporting || library.isDeleting,
            importProgress: library.importProgress,
            favoritesOnly: library.favoritesOnly,
            onImport: () => showMusicImportSheet(context),
            onFavorites: library.toggleFavoritesFilter,
            onDeleteAll: library.trackCount == 0 ||
                    library.isImporting ||
                    library.isDeleting
                ? null
                : () => _confirmDeleteDownloads(context),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          sliver: SliverToBoxAdapter(
            child: SearchBar(
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(
                Theme.of(context)
                    .colorScheme
                    .surfaceContainerHigh
                    .withValues(alpha: .72),
              ),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 18),
              ),
              hintText: 'Rechercher dans votre musique',
              leading: const Icon(Icons.search_rounded),
              onChanged: library.setQuery,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 54,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              scrollDirection: Axis.horizontal,
              itemCount: _LibraryMode.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final mode = _LibraryMode.values[index];
                return ChoiceChip(
                  selected: _mode == mode,
                  showCheckmark: false,
                  avatar: Icon(mode.icon, size: 18),
                  label: Text(mode.label),
                  onSelected: (_) {
                    _selection.clear();
                    setState(() => _mode = mode);
                  },
                );
              },
            ),
          ),
        ),
        if (_mode == _LibraryMode.playlists) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
            sliver: SliverToBoxAdapter(
              child: _SectionTitle(
                title: 'Vos playlists',
                detail:
                    '${library.playlists.length} playlist${library.playlists.length > 1 ? 's' : ''}',
                action: FilledButton.tonalIcon(
                  onPressed: () => _createPlaylist(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Créer'),
                ),
              ),
            ),
          ),
          if (library.playlists.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyPlaylists(onCreate: () => _createPlaylist(context)),
            )
          else
            _PlaylistGrid(playlists: library.playlists),
          const SliverToBoxAdapter(child: SizedBox(height: 190)),
        ] else if (library.trackCount == 0)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyLibrary(importing: library.isImporting),
          )
        else if (tracks.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _NoResults(),
          )
        else if (_mode == _LibraryMode.history) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
            sliver: SliverToBoxAdapter(
              child: _SectionTitle(
                title: 'Écoutés récemment',
                detail: _trackCount(history.length),
                action: history.isEmpty
                    ? null
                    : TextButton.icon(
                        onPressed: () =>
                            context.read<PlayerProvider>().playAll(history),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Tout lire'),
                      ),
              ),
            ),
          ),
          if (history.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyHistory(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 190),
              sliver: SliverList.builder(
                itemCount: history.length,
                itemBuilder: (context, index) => _StaggeredEntry(
                  index: index,
                  child: _TrackTile(track: history[index], queue: history),
                ),
              ),
            ),
        ] else if (_mode == _LibraryMode.tracks) ...[
          SliverToBoxAdapter(child: _RecentTracks(tracks: tracks)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 10),
            sliver: SliverToBoxAdapter(
              child: _SectionTitle(
                title:
                    library.favoritesOnly ? 'Vos favoris' : 'Tous les morceaux',
                detail:
                    '${_trackCount(tracks.length)} · ${library.sort.label.toLowerCase()}',
                action: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PopupMenuButton<TrackSort>(
                      tooltip: 'Trier par ${library.sort.label.toLowerCase()}',
                      icon: const Icon(Icons.sort_rounded),
                      initialValue: library.sort,
                      onSelected: library.setSort,
                      itemBuilder: (_) => [
                        for (final value in TrackSort.values)
                          CheckedPopupMenuItem(
                            value: value,
                            checked: value == library.sort,
                            child: Text(value.label),
                          ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          context.read<PlayerProvider>().playShuffled(tracks),
                      icon: const Icon(Icons.shuffle_rounded),
                      label: const Text('Aléatoire'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 190),
            sliver: SliverList.builder(
              itemCount: tracks.length,
              itemBuilder: (context, index) => _StaggeredEntry(
                index: index,
                child: _TrackTile(track: tracks[index], queue: tracks),
              ),
            ),
          ),
        ] else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
            sliver: SliverToBoxAdapter(
              child: _SectionTitle(
                title: _mode.label,
                detail:
                    '${groups.length} collection${groups.length > 1 ? 's' : ''}',
              ),
            ),
          ),
          _GroupGrid(groups: groups, mode: _mode),
          const SliverToBoxAdapter(child: SizedBox(height: 190)),
        ],
      ],
    );
  }

  Map<String, List<MusicTrack>> _group(
    List<MusicTrack> tracks,
    _LibraryMode mode,
  ) {
    final grouped = <String, List<MusicTrack>>{};
    for (final track in tracks) {
      grouped.putIfAbsent(mode.valueFor(track), () => []).add(track);
    }
    for (final values in grouped.values) {
      values.sort((a, b) {
        final disc = (a.discNumber ?? 0).compareTo(b.discNumber ?? 0);
        return disc != 0
            ? disc
            : (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0);
      });
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    return Map.fromEntries(entries);
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({
    required this.count,
    required this.importing,
    this.importProgress,
    required this.favoritesOnly,
    required this.onImport,
    required this.onFavorites,
    required this.onDeleteAll,
  });

  final int count;
  final bool importing;
  final ({int completed, int total})? importProgress;
  final bool favoritesOnly;
  final VoidCallback onImport;
  final VoidCallback onFavorites;
  final VoidCallback? onDeleteAll;

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
                      colors: [Color(0xFF7C4DFF), Color(0xFFFF4D8D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x557C4DFF),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child:
                      const Icon(Icons.graphic_eq_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VOTRE BIBLIOTHÈQUE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      Text(
                        count == 0 ? 'MusicStream' : _greeting(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: favoritesOnly ? 'Afficher tout' : 'Favoris',
                  onPressed: onFavorites,
                  icon: Icon(favoritesOnly
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded),
                ),
                if (count > 0)
                  IconButton(
                    tooltip: 'Supprimer les téléchargements du téléphone',
                    onPressed: onDeleteAll,
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
                IconButton.filled(
                  tooltip: 'Importer des morceaux',
                  onPressed: importing ? null : onImport,
                  icon: importing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              count == 0
                  ? 'Votre musique mérite\nun bel écrin.'
                  : 'Qu’avez-vous envie\nd’écouter ?',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.04,
                    letterSpacing: -1.6,
                  ),
            ),
            if (count > 0) ...[
              const SizedBox(height: 10),
              Text(
                '$count morceau${count > 1 ? 'x' : ''} disponible${count > 1 ? 's' : ''} hors connexion',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            if (importProgress case final progress?
                when progress.total > 0) ...[
              const SizedBox(height: 14),
              Text(
                'Import ${progress.completed} / ${progress.total}…',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.completed / progress.total,
                  minHeight: 4,
                ),
              ),
            ],
          ],
        ),
      );

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }
}

class _RecentTracks extends StatelessWidget {
  const _RecentTracks({required this.tracks});
  final List<MusicTrack> tracks;

  @override
  Widget build(BuildContext context) {
    final recent = List<MusicTrack>.of(tracks)
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    final visible = recent.take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 14),
          child: _SectionTitle(
            title: 'Ajoutés récemment',
            action: TextButton.icon(
              onPressed: () => context.read<PlayerProvider>().playAll(visible),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Tout lire'),
            ),
          ),
        ),
        SizedBox(
          height: 226,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: visible.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, index) => Builder(builder: (context) {
              final track = visible[index];
              final selection = context.read<_TrackSelection>();
              final selected = context.select<_TrackSelection, bool>(
                (selection) => selection.contains(track.id),
              );
              return SizedBox(
                width: 158,
                child: InkWell(
                  onTap: () => selection.active
                      ? selection.toggle(track.id)
                      : context
                          .read<PlayerProvider>()
                          .playTrack(track, visible),
                  onLongPress: () => selection.toggle(track.id),
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          TrackArtwork(
                            track: track,
                            size: 158,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                  selected
                                      ? Icons.check_rounded
                                      : Icons.play_arrow_rounded,
                                  color: selected
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : const Color(0xFF171221)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _GroupGrid extends StatelessWidget {
  const _GroupGrid({required this.groups, required this.mode});
  final Map<String, List<MusicTrack>> groups;
  final _LibraryMode mode;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
        builder: (context, constraints) {
          final columns = math.max(2, constraints.crossAxisExtent ~/ 210);
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: .76,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final entry = groups.entries.elementAt(index);
                return _CollectionCard(
                  title: entry.key,
                  tracks: entry.value,
                  circularArtwork: mode == _LibraryMode.artists,
                );
              },
            ),
          );
        },
      );
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.title,
    required this.tracks,
    required this.circularArtwork,
  });
  final String title;
  final List<MusicTrack> tracks;
  final bool circularArtwork;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => _CollectionScreen(title: title, tracks: tracks),
          )),
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => TrackArtwork(
                      track: tracks.first,
                      size: constraints.maxWidth,
                      borderRadius: BorderRadius.circular(
                          circularArtwork ? constraints.maxWidth : 24),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  _trackCount(tracks.length),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
}

class _CollectionScreen extends StatelessWidget {
  const _CollectionScreen({required this.title, required this.tracks});
  final String title;
  final List<MusicTrack> tracks;

  @override
  Widget build(BuildContext context) {
    final available = {
      for (final track in context.watch<LibraryProvider>().allTracks)
        track.id: track,
    };
    final visible =
        tracks.map((track) => available[track.id]).nonNulls.toList();
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 310,
            pinned: true,
            actions: [
              IconButton(
                tooltip: 'Lecture aléatoire',
                onPressed: visible.isEmpty
                    ? null
                    : () =>
                        context.read<PlayerProvider>().playShuffled(visible),
                icon: const Icon(Icons.shuffle_rounded),
              ),
              IconButton.filledTonal(
                tooltip: 'Lire la collection',
                onPressed: visible.isEmpty
                    ? null
                    : () => context.read<PlayerProvider>().playAll(visible),
                icon: const Icon(Icons.play_arrow_rounded),
              ),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(title, maxLines: 1),
              background: visible.isEmpty
                  ? null
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        TrackArtwork(track: visible.first),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Color(0xCC0D0C14)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
            sliver: SliverList.builder(
              itemCount: visible.length,
              itemBuilder: (context, index) =>
                  _TrackTile(track: visible[index], queue: visible),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistGrid extends StatelessWidget {
  const _PlaylistGrid({required this.playlists});
  final List<MusicPlaylist> playlists;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
        builder: (context, constraints) {
          final columns = math.max(2, constraints.crossAxisExtent ~/ 210);
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: .88,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: playlists.length,
              itemBuilder: (context, index) =>
                  _PlaylistCard(playlist: playlists[index]),
            ),
          );
        },
      );
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({required this.playlist});
  final MusicPlaylist playlist;

  @override
  Widget build(BuildContext context) {
    final tracks = context.watch<LibraryProvider>().tracksForPlaylist(playlist);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => _PlaylistScreen(playlistId: playlist.id),
        )),
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFFE43F83)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: tracks.isEmpty
                      ? const Icon(Icons.queue_music_rounded,
                          size: 56, color: Colors.white)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: TrackArtwork(track: tracks.first),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Text(playlist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(_trackCount(tracks.length),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistScreen extends StatefulWidget {
  const _PlaylistScreen({required this.playlistId});
  final String playlistId;

  @override
  State<_PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<_PlaylistScreen> {
  var _reordering = false;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final index =
        library.playlists.indexWhere((item) => item.id == widget.playlistId);
    if (index == -1) return const SizedBox.shrink();
    final playlist = library.playlists[index];
    final tracks = library.tracksForPlaylist(playlist);
    final reordering = _reordering && tracks.length > 1;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            title: Text(playlist.name),
            actions: [
              if (reordering)
                IconButton(
                  tooltip: 'Terminer',
                  onPressed: () => setState(() => _reordering = false),
                  icon: const Icon(Icons.check_rounded),
                )
              else ...[
                IconButton(
                  tooltip: 'Ajouter des morceaux',
                  onPressed: () => _selectTracks(context, playlist),
                  icon: const Icon(Icons.playlist_add_rounded),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) async {
                    if (action == 'edit') {
                      await _editPlaylist(context, playlist);
                    } else if (action == 'reorder') {
                      setState(() => _reordering = true);
                    } else if (action == 'delete' &&
                        await _confirmDelete(context, playlist.name)) {
                      if (!context.mounted) return;
                      await context
                          .read<LibraryProvider>()
                          .deletePlaylist(playlist.id);
                      if (context.mounted) Navigator.of(context).pop();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                    if (tracks.length > 1)
                      const PopupMenuItem(
                        value: 'reorder',
                        child: Text("Réorganiser l'ordre"),
                      ),
                    const PopupMenuItem(
                        value: 'delete', child: Text('Supprimer')),
                  ],
                ),
              ],
            ],
          ),
          if (playlist.description.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  playlist.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
              ),
            ),
          if (tracks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child:
                  _EmptyPlaylist(onAdd: () => _selectTracks(context, playlist)),
            )
          else if (reordering) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Faites glisser les poignées pour changer l’ordre.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
              sliver: SliverReorderableList(
                itemCount: tracks.length,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex--;
                  context
                      .read<LibraryProvider>()
                      .movePlaylistTrack(playlist.id, oldIndex, newIndex);
                },
                itemBuilder: (context, index) => _ReorderableTrackTile(
                  key: ValueKey(tracks[index].id),
                  track: tracks[index],
                  index: index,
                ),
              ),
            ),
          ] else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: () =>
                          context.read<PlayerProvider>().playAll(tracks),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Tout lire'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          context.read<PlayerProvider>().playShuffled(tracks),
                      icon: const Icon(Icons.shuffle_rounded),
                      label: const Text('Aléatoire'),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
              sliver: SliverList.builder(
                itemCount: tracks.length,
                itemBuilder: (context, index) => _TrackTile(
                  track: tracks[index],
                  queue: tracks,
                  playlistId: playlist.id,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReorderableTrackTile extends StatelessWidget {
  const _ReorderableTrackTile({
    super.key,
    required this.track,
    required this.index,
  });
  final MusicTrack track;
  final int index;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Material(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainer
              .withValues(alpha: .48),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                TrackArtwork(
                  track: track,
                  size: 48,
                  borderRadius: BorderRadius.circular(14),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(track.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.drag_handle_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.importing});
  final bool importing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 180),
        child: Center(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 620),
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C44E9), Color(0xFFE43F83)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(36),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x446C44E9),
                  blurRadius: 34,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -44,
                  top: -54,
                  child: Icon(Icons.album_rounded,
                      size: 210, color: Colors.white.withValues(alpha: .1)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.library_music_rounded,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 72),
                    Text(
                      'Donnez vie à\nvotre bibliothèque',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ajoutez vos morceaux : ils restent privés, disponibles hors connexion et classés automatiquement.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: .82),
                            height: 1.45,
                          ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF321B62),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                      ),
                      onPressed: importing
                          ? null
                          : () => showMusicImportSheet(context),
                      icon: importing
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_rounded),
                      label: Text(importing
                          ? 'Import en cours…'
                          : 'Ajouter ma musique'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 190),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_toggle_off_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Votre historique est encore vide',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Les morceaux suffisamment écoutés apparaîtront ici.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
}

class _EmptyPlaylists extends StatelessWidget {
  const _EmptyPlaylists({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 180),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.queue_music_rounded,
                  size: 72, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 18),
              Text('Créez votre première playlist',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'Regroupez vos morceaux pour les retrouver et les lire dans l’ordre.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Créer une playlist'),
              ),
            ],
          ),
        ),
      );
}

class _EmptyPlaylist extends StatelessWidget {
  const _EmptyPlaylist({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.music_note_rounded, size: 64),
              const SizedBox(height: 16),
              Text('Cette playlist est vide',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.playlist_add_rounded),
                label: const Text('Ajouter des morceaux'),
              ),
            ],
          ),
        ),
      );
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 180),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text('Aucun résultat',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              const Text(
                'Essayez un autre titre, artiste, album ou genre.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

/// Multi-selection shared by the library lists. Tiles outside a
/// [LibraryScreen] (collections, playlists) have no scope and open their
/// options menu on long press instead.
class _TrackSelection extends ChangeNotifier {
  final Set<String> _ids = {};

  bool get active => _ids.isNotEmpty;
  int get count => _ids.length;
  Iterable<String> get ids => _ids;
  bool contains(String id) => _ids.contains(id);

  void toggle(String id) {
    if (!_ids.remove(id)) _ids.add(id);
    notifyListeners();
  }

  void selectAll(Iterable<String> ids) {
    _ids.addAll(ids);
    notifyListeners();
  }

  void clear() {
    if (_ids.isEmpty) return;
    _ids.clear();
    notifyListeners();
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({required this.visible});
  final List<MusicTrack> visible;

  @override
  Widget build(BuildContext context) {
    final selection = context.watch<_TrackSelection>();
    final colors = Theme.of(context).colorScheme;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: !selection.active
          ? const SizedBox.shrink()
          : Material(
              key: const ValueKey('selection'),
              color: colors.primaryContainer,
              elevation: 6,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Annuler la sélection',
                      onPressed: selection.clear,
                      icon: const Icon(Icons.close_rounded),
                    ),
                    Expanded(
                      child: Text(
                        '${selection.count} sélectionné${selection.count > 1 ? 's' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Lire ensuite',
                      onPressed: () => _run(context, (tracks) async {
                        final messenger = ScaffoldMessenger.of(context);
                        await context
                            .read<PlayerProvider>()
                            .playNextAll(tracks);
                        messenger.showSnackBar(
                            const SnackBar(content: Text('Lecture suivante.')));
                        return true;
                      }),
                      icon: const Icon(Icons.playlist_play_rounded),
                    ),
                    IconButton(
                      tooltip: 'Ajouter à la file',
                      onPressed: () => _run(context, (tracks) async {
                        final messenger = ScaffoldMessenger.of(context);
                        await context
                            .read<PlayerProvider>()
                            .addAllToQueue(tracks);
                        messenger.showSnackBar(SnackBar(
                            content: Text(
                                'Ajouté${tracks.length > 1 ? 's' : ''} à la file.')));
                        return true;
                      }),
                      icon: const Icon(Icons.queue_music_rounded),
                    ),
                    IconButton(
                      tooltip: 'Ajouter à une playlist',
                      onPressed: () => _run(
                        context,
                        (tracks) => _addTracksToPlaylist(context, tracks),
                      ),
                      icon: const Icon(Icons.playlist_add_rounded),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Plus d’actions',
                      onSelected: (action) => action == 'all'
                          ? selection
                              .selectAll(visible.map((track) => track.id))
                          : _run(
                              context,
                              (tracks) => _confirmDeleteTracks(context, tracks),
                            ),
                      itemBuilder: (_) => [
                        if (visible
                            .any((track) => !selection.contains(track.id)))
                          const PopupMenuItem(
                            value: 'all',
                            child: Text('Tout sélectionner'),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Supprimer du téléphone'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Runs [action] on the selected tracks and leaves selection mode only
  /// once the action completed, so a cancelled dialog keeps the selection.
  Future<void> _run(
    BuildContext context,
    Future<bool> Function(List<MusicTrack> tracks) action,
  ) async {
    final selection = context.read<_TrackSelection>();
    final tracks =
        context.read<LibraryProvider>().tracksByIds(selection.ids.toList());
    if (tracks.isEmpty) return selection.clear();
    if (await action(tracks)) selection.clear();
  }
}

class _TrackTile extends StatefulWidget {
  const _TrackTile({
    required this.track,
    required this.queue,
    this.playlistId,
  });
  final MusicTrack track;
  final List<MusicTrack> queue;
  final String? playlistId;

  @override
  State<_TrackTile> createState() => _TrackTileState();
}

class _TrackTileState extends State<_TrackTile> {
  final _menuKey = GlobalKey<PopupMenuButtonState<String>>();

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    final selection = context.watch<_TrackSelection?>();
    final selected = selection?.contains(track.id) ?? false;
    final current = context.select<PlayerProvider?, bool>(
      (player) => player?.current?.id == track.id,
    );
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected
            ? colors.primaryContainer.withValues(alpha: .8)
            : colors.surfaceContainer.withValues(alpha: .48),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => selection?.active ?? false
              ? selection!.toggle(track.id)
              : context.read<PlayerProvider>().playTrack(track, widget.queue),
          onLongPress: () => selection != null
              ? selection.toggle(track.id)
              : _menuKey.currentState?.showButtonMenu(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Stack(
                  children: [
                    TrackArtwork(
                      track: track,
                      size: 58,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    if (selected)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: .72),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Icon(Icons.check_rounded,
                              color: colors.onPrimary, size: 30),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (current) ...[
                            Icon(Icons.graphic_eq_rounded,
                                size: 16, color: colors.primary),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: current ? colors.primary : null,
                                )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text('${track.artist}  •  ${track.album}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                if (track.durationMs != null)
                  Text(
                    _duration(track.durationMs!),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                IconButton(
                  tooltip: track.favorite
                      ? 'Retirer des favoris'
                      : 'Ajouter aux favoris',
                  onPressed: () =>
                      context.read<LibraryProvider>().toggleFavorite(track.id),
                  icon: Icon(track.favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded),
                ),
                PopupMenuButton<String>(
                  key: _menuKey,
                  tooltip: 'Options du morceau',
                  onSelected: (action) => _onAction(context, action),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'next',
                      child: Text('Lire ensuite'),
                    ),
                    const PopupMenuItem(
                      value: 'queue',
                      child: Text('Ajouter à la file'),
                    ),
                    if (widget.playlistId == null)
                      const PopupMenuItem(
                        value: 'add',
                        child: Text('Ajouter à une playlist'),
                      )
                    else
                      const PopupMenuItem(
                        value: 'remove',
                        child: Text('Retirer de la playlist'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer du téléphone'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onAction(BuildContext context, String action) async {
    final track = widget.track;
    if (action == 'next') {
      await context.read<PlayerProvider>().playNext(track);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lecture suivante.')),
        );
      }
    } else if (action == 'queue') {
      await context.read<PlayerProvider>().addToQueue(track);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajouté à la file.')),
        );
      }
    } else if (action == 'add') {
      await _addTracksToPlaylist(context, [track]);
    } else if (action == 'remove') {
      await context
          .read<LibraryProvider>()
          .removeTrackFromPlaylist(widget.playlistId!, track.id);
    } else if (action == 'delete') {
      await _confirmDeleteTracks(context, [track]);
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.detail, this.action});
  final String title;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.4,
                        )),
                if (detail != null)
                  Text(detail!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      );
}

class _StaggeredEntry extends StatelessWidget {
  const _StaggeredEntry({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 260 + math.min(index, 5) * 45),
        tween: Tween(begin: 0, end: 1),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: child,
          ),
        ),
        child: child,
      );
}

String _trackCount(int count) => '$count morceau${count > 1 ? 'x' : ''}';

String _duration(int milliseconds) {
  final value = Duration(milliseconds: milliseconds);
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${value.inMinutes}:$seconds';
}

Future<void> _createPlaylist(BuildContext context) async {
  final name = await _askForName(context, title: 'Nouvelle playlist');
  if (name == null || !context.mounted) return;
  await context.read<LibraryProvider>().createPlaylist(name);
}

Future<void> _editPlaylist(
  BuildContext context,
  MusicPlaylist playlist,
) async {
  final details = await showDialog<({String name, String description})>(
    context: context,
    builder: (_) => _PlaylistDetailsDialog(playlist: playlist),
  );
  if (details == null || !context.mounted) return;
  await context.read<LibraryProvider>().updatePlaylistDetails(
        playlist.id,
        name: details.name,
        description: details.description,
      );
}

class _PlaylistDetailsDialog extends StatefulWidget {
  const _PlaylistDetailsDialog({required this.playlist});
  final MusicPlaylist playlist;

  @override
  State<_PlaylistDetailsDialog> createState() => _PlaylistDetailsDialogState();
}

class _PlaylistDetailsDialogState extends State<_PlaylistDetailsDialog> {
  late final _name = TextEditingController(text: widget.playlist.name);
  late final _description =
      TextEditingController(text: widget.playlist.description);

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(
      context,
      (name: name, description: _description.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Modifier la playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: _submit,
            child: const Text('Enregistrer'),
          ),
        ],
      );
}

Future<String?> _askForName(
  BuildContext context, {
  required String title,
  String initialValue = '',
}) async {
  var currentValue = initialValue;
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextFormField(
        initialValue: initialValue,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(labelText: 'Nom'),
        onChanged: (value) => currentValue = value,
        onFieldSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            Navigator.pop(dialogContext, value.trim());
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final name = currentValue.trim();
            if (name.isNotEmpty) Navigator.pop(dialogContext, name);
          },
          child: const Text('Enregistrer'),
        ),
      ],
    ),
  );
}

Future<void> _confirmDeleteDownloads(BuildContext context) async {
  final library = context.read<LibraryProvider>();
  final downloads = library.downloadedTracks;
  final unknown = library.unknownSourceTracks;
  var includeUnknown = false;
  if (unknown.isNotEmpty) {
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Anciens morceaux'),
        content: Text(
          '${unknown.length} morceau${unknown.length > 1 ? 'x' : ''} ajouté${unknown.length > 1 ? 's' : ''} avant cette version n’indique${unknown.length > 1 ? 'nt' : ''} pas leur origine. Ne les incluez que si vous savez qu’ils viennent tous du serveur : un ancien import local serait aussi supprimé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          if (downloads.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'known'),
              child: const Text('Téléchargements identifiés'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'all'),
            child: const Text('Inclure les anciens'),
          ),
        ],
      ),
    );
    if (choice == null || !context.mounted) return;
    includeUnknown = choice == 'all';
  }
  await _confirmDeleteTracks(
    context,
    [...downloads, if (includeUnknown) ...unknown],
    bulk: true,
    includeLegacy: includeUnknown,
  );
}

Future<bool> _confirmDeleteTracks(
  BuildContext context,
  Iterable<MusicTrack> tracks, {
  bool bulk = false,
  bool includeLegacy = false,
}) async {
  final library = context.read<LibraryProvider>();
  if (library.isDeleting || library.isImporting) return false;
  final ids = tracks.map((track) => track.id).toSet();
  if (ids.isEmpty) return false;
  final count = ids.length;
  final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(bulk
              ? 'Supprimer les téléchargements ?'
              : count > 1
                  ? 'Supprimer ces $count morceaux ?'
                  : 'Supprimer ce morceau ?'),
          content: Text(bulk
              ? 'Les $count morceau${count > 1 ? 'x' : ''} sélectionné${count > 1 ? 's' : ''} seront supprimés de MusicStream sur ce téléphone. ${includeLegacy ? 'Cela inclut les anciens morceaux que vous avez choisis.' : 'Les imports locaux sont conservés.'}'
              : count > 1
                  ? 'Les morceaux et leurs fichiers associés seront supprimés de MusicStream sur ce téléphone. Les fichiers d’origine sont conservés.'
                  : 'Le morceau et ses fichiers associés seront supprimés de MusicStream sur ce téléphone. Le fichier d’origine est conservé.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      ) ??
      false;
  if (!confirmed || !context.mounted) return false;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await context.read<PlayerProvider>().removeTracksByIds(ids);
    final removed = await library.deleteTracks(ids);
    messenger.showSnackBar(SnackBar(
      content: Text(
          '$removed morceau${removed > 1 ? 'x' : ''} supprimé${removed > 1 ? 's' : ''} du téléphone.'),
    ));
    return true;
  } catch (_) {
    messenger.showSnackBar(const SnackBar(
      content: Text('Suppression impossible. Réessayez.'),
    ));
    return false;
  }
}

Future<bool> _confirmDelete(BuildContext context, String name) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer la playlist ?'),
        content:
            Text('« $name » sera supprimée. Vos morceaux seront conservés.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    ) ??
    false;

Future<bool> _addTracksToPlaylist(
  BuildContext context,
  List<MusicTrack> tracks,
) async {
  if (tracks.isEmpty) return false;
  final library = context.read<LibraryProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final ids = tracks.map((track) => track.id).toList();
  Future<void> addTo(MusicPlaylist playlist) async {
    final added = await library.addTracksToPlaylist(playlist.id, ids);
    if (tracks.length > 1) {
      messenger.showSnackBar(SnackBar(
        content: Text(
            '${_trackCount(added)} ajouté${added > 1 ? 's' : ''} à « ${playlist.name} ».'),
      ));
    }
  }

  if (library.playlists.isEmpty) {
    final name = await _askForName(context, title: 'Nouvelle playlist');
    if (name == null || !context.mounted) return false;
    final playlist = await library.createPlaylist(name);
    if (playlist == null) return false;
    await addTo(playlist);
    return true;
  }
  if (!context.mounted) return false;
  final added = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * .72,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                  tracks.length == 1
                      ? 'Ajouter « ${tracks.single.title} »'
                      : 'Ajouter ${_trackCount(tracks.length)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(sheetContext).textTheme.titleLarge),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final playlist in library.playlists)
                    Builder(builder: (_) {
                      final complete = ids.every(playlist.trackIds.contains);
                      return ListTile(
                        leading: const Icon(Icons.queue_music_rounded),
                        title: Text(playlist.name),
                        trailing:
                            complete ? const Icon(Icons.check_rounded) : null,
                        enabled: !complete,
                        onTap: () async {
                          await addTo(playlist);
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext, true);
                          }
                        },
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
  return added ?? false;
}

Future<void> _selectTracks(
  BuildContext context,
  MusicPlaylist playlist,
) async {
  final library = context.read<LibraryProvider>();
  final selected = playlist.trackIds.toSet();
  final result = await showDialog<Set<String>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Morceaux de la playlist'),
        content: SizedBox(
          width: 520,
          child: library.allTracks.isEmpty
              ? const Text(
                  'Importez d’abord des morceaux dans la bibliothèque.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: library.allTracks.length,
                  itemBuilder: (context, index) {
                    final track = library.allTracks[index];
                    return CheckboxListTile(
                      value: selected.contains(track.id),
                      title: Text(track.title),
                      subtitle: Text(track.artist),
                      onChanged: (checked) => setState(() {
                        checked == true
                            ? selected.add(track.id)
                            : selected.remove(track.id);
                      }),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, selected),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );
  if (result == null || !context.mounted) return;
  for (final trackId in result.difference(playlist.trackIds.toSet())) {
    await library.addTrackToPlaylist(playlist.id, trackId);
  }
  for (final trackId in playlist.trackIds.toSet().difference(result)) {
    await library.removeTrackFromPlaylist(playlist.id, trackId);
  }
}
