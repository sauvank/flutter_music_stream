import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/track_artwork.dart';

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
    final value =
        player.position.inMilliseconds.toDouble().clamp(0, maximum).toDouble();
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
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final artworkSize = constraints.maxWidth.clamp(240.0, 460.0);
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
            const SizedBox(height: 34),
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
            const SizedBox(height: 22),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              ),
              child: Slider(
                value: value,
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
                  Text(_time(player.position)),
                  Text(
                      '-${_time(_remaining(player.duration, player.position))}'),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 42,
                  tooltip: 'Précédent',
                  onPressed: player.hasPrevious ? player.previous : null,
                  icon: const Icon(Icons.skip_previous_rounded),
                ),
                const SizedBox(width: 20),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 78,
                  height: 78,
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
                const SizedBox(width: 20),
                IconButton(
                  iconSize: 42,
                  tooltip: 'Suivant',
                  onPressed: player.hasNext ? player.next : null,
                  icon: const Icon(Icons.skip_next_rounded),
                ),
              ],
            ),
            const SizedBox(height: 30),
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
