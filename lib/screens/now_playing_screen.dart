import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/track_artwork.dart';
import 'lyrics_sheet.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final track = player.current;
    if (track == null) return const _NothingPlaying();

    final maximum = player.duration.inMilliseconds
        .toDouble()
        .clamp(1, double.infinity)
        .toDouble();
    final screenHeight = MediaQuery.sizeOf(context).height;
    final compactHeight = screenHeight < 760;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      child: SingleChildScrollView(
        key: ValueKey(track.id),
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 190),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Spacer(),
                Text(
                  'EN COURS DE LECTURE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                const SizedBox(width: 38),
              ],
            ),
            SizedBox(height: compactHeight ? 14 : 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final widthLimit = constraints.maxWidth.clamp(180.0, 460.0);
                final heightLimit = (screenHeight - 450).clamp(180.0, 460.0);
                final artworkSize =
                    widthLimit < heightLimit ? widthLimit : heightLimit;
                return Container(
                  width: artworkSize,
                  height: artworkSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(42),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: .28),
                        blurRadius: 52,
                        spreadRadius: -8,
                        offset: const Offset(0, 24),
                      ),
                    ],
                  ),
                  child: TrackArtwork(
                    track: track,
                    size: artworkSize,
                    borderRadius: BorderRadius.circular(42),
                  ),
                );
              },
            ),
            SizedBox(height: compactHeight ? 18 : 34),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -.6,
                                ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${track.artist}  •  ${track.album}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: track.favorite
                      ? 'Retirer des favoris'
                      : 'Ajouter aux favoris',
                  onPressed: () =>
                      context.read<LibraryProvider>().toggleFavorite(track.id),
                  icon: Icon(track.favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded),
                ),
              ],
            ),
            SizedBox(height: compactHeight ? 12 : 22),
            ValueListenableBuilder<Duration>(
              valueListenable: player.positionListenable,
              builder: (context, position, _) => Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 18),
                    ),
                    child: Slider(
                      value: position.inMilliseconds
                          .toDouble()
                          .clamp(0, maximum)
                          .toDouble(),
                      max: maximum,
                      onChanged: (next) =>
                          player.seek(Duration(milliseconds: next.round())),
                      onChangeEnd: (next) => context
                          .read<LibraryProvider>()
                          .savePosition(
                              track.id, Duration(milliseconds: next.round())),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_time(position)),
                        Text(
                            '-${_time(_remaining(player.duration, position))}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: compactHeight ? 12 : 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: player.shuffleEnabled
                      ? 'Désactiver la lecture aléatoire'
                      : 'Activer la lecture aléatoire',
                  color: player.shuffleEnabled
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  onPressed: player.toggleShuffle,
                  icon: const Icon(Icons.shuffle_rounded),
                ),
                IconButton(
                  iconSize: 38,
                  tooltip: 'Précédent',
                  onPressed: player.hasPrevious ? player.previous : null,
                  icon: const Icon(Icons.skip_previous_rounded),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.tertiary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: .34),
                        blurRadius: player.playing ? 30 : 18,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: IconButton(
                    iconSize: 40,
                    color: Colors.white,
                    tooltip: player.playing ? 'Pause' : 'Lire',
                    onPressed: player.toggle,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        player.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey(player.playing),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  iconSize: 38,
                  tooltip: 'Suivant',
                  onPressed: player.hasNext ? player.next : null,
                  icon: const Icon(Icons.skip_next_rounded),
                ),
                IconButton(
                  tooltip: switch (player.loopMode) {
                    LoopMode.off => 'Répéter la file',
                    LoopMode.all => 'Répéter ce morceau',
                    LoopMode.one => 'Désactiver la répétition',
                  },
                  color: player.loopMode == LoopMode.off
                      ? null
                      : Theme.of(context).colorScheme.primary,
                  onPressed: player.cycleLoopMode,
                  icon: Icon(player.loopMode == LoopMode.one
                      ? Icons.repeat_one_rounded
                      : Icons.repeat_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  player.volume == 0
                      ? Icons.volume_off_rounded
                      : Icons.volume_down_rounded,
                  size: 22,
                ),
                Expanded(
                  child: Slider(
                    value: player.volume,
                    onChanged: player.setVolume,
                  ),
                ),
                const Icon(Icons.volume_up_rounded, size: 22),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${(player.volume * 100).round()} %',
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => _showQueue(context),
              icon: const Icon(Icons.queue_music_rounded),
              label: Text(
                'File de lecture (${player.queue.length})',
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => Consumer<PlayerProvider>(
                  builder: (context, currentPlayer, _) => FractionallySizedBox(
                    heightFactor: .78,
                    child: currentPlayer.current == null
                        ? const Center(child: Text('Aucun morceau en lecture.'))
                        : LyricsSheet(
                            key: ValueKey(currentPlayer.current!.id),
                            track: currentPlayer.current!,
                          ),
                  ),
                ),
              ),
              icon: const Icon(Icons.lyrics_rounded),
              label: const Text('Paroles'),
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetadataPill(icon: Icons.album_rounded, label: track.album),
                _MetadataPill(
                    icon: Icons.auto_awesome_rounded, label: track.genre),
                if (track.durationMs != null)
                  _MetadataPill(
                    icon: Icons.schedule_rounded,
                    label: _time(Duration(milliseconds: track.durationMs!)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _time(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Duration _remaining(Duration duration, Duration position) =>
      duration > position ? duration - position : Duration.zero;

  void _showQueue(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _QueueSheet(),
    );
  }
}

class _QueueSheet extends StatelessWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
        initialChildSize: .62,
        minChildSize: .35,
        maxChildSize: .92,
        expand: false,
        builder: (context, scrollController) {
          final player = context.watch<PlayerProvider>();
          final queue = player.queue;
          final currentIndex = player.currentIndex;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'À suivre',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    Text(
                        '${queue.length} morceau${queue.length > 1 ? 'x' : ''}'),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  scrollController: scrollController,
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: queue.length,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex--;
                    player.moveQueueItem(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final track = queue[index];
                    final isCurrent = index == currentIndex;
                    return ListTile(
                      key: ValueKey('${track.id}-$index'),
                      leading: isCurrent
                          ? Icon(
                              Icons.graphic_eq_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : TrackArtwork(
                              track: track,
                              size: 44,
                              borderRadius: BorderRadius.circular(12),
                            ),
                      title: Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight:
                              isCurrent ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        tooltip: 'Retirer de la file',
                        onPressed: () => player.removeFromQueue(index),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      onTap: () {
                        player.playAt(index);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
}

class _MetadataPill extends StatelessWidget {
  const _MetadataPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHigh
              .withValues(alpha: .68),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17),
            const SizedBox(width: 7),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
}

class _NothingPlaying extends StatelessWidget {
  const _NothingPlaying();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 30, 30, 150),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFFFF4D8D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.graphic_eq_rounded,
                    size: 68, color: Colors.white),
              ),
              const SizedBox(height: 28),
              Text('Prêt à vibrer ?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      )),
              const SizedBox(height: 8),
              const Text(
                'Choisissez un morceau dans votre bibliothèque pour commencer.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}
