import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../services/audio_output_service.dart';
import '../widgets/audio_visualizer.dart';
import '../widgets/track_artwork.dart';
import 'library_screen.dart' show showAddToPlaylistSheet;
import 'lyrics_sheet.dart';
import '../l10n/l10n.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final track = player.current;
    // The queue holds snapshots; the library owns the live favorite state.
    final favorite = context.select<LibraryProvider, bool>(
      (library) =>
          track != null && (library.isFavorite(track.id) ?? track.favorite),
    );
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
                  context.l10n.nowPlayingLabel,
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
                // A title wrapping to a second line takes that height from
                // the artwork, so the controls stay above the navigation.
                final title = TextPainter(
                  text:
                      TextSpan(text: track.title, style: _titleStyle(context)),
                  maxLines: 1,
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                )..layout(maxWidth: constraints.maxWidth - 156);
                final extraTitleLine =
                    title.didExceedMaxLines ? title.height : 0.0;
                title.dispose();
                final heightLimit =
                    (screenHeight - 500 - extraTitleLine).clamp(180.0, 460.0);
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(42),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        TrackArtwork(
                          track: track,
                          size: artworkSize,
                          borderRadius: BorderRadius.circular(42),
                        ),
                        AudioVisualizer(height: artworkSize * .2),
                      ],
                    ),
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
                        style: _titleStyle(context),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${context.l10n.metadata(track.artist)}  •  '
                        '${context.l10n.metadata(track.album)}',
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
                IconButton(
                  tooltip: context.l10n.addToPlaylist,
                  onPressed: () => showAddToPlaylistSheet(context, [track]),
                  icon: const Icon(Icons.playlist_add_rounded),
                ),
                if (const AudioOutputService().supported) ...[
                  IconButton(
                    tooltip: context.l10n.audioOutput,
                    onPressed: () => _showOutputSwitcher(context),
                    icon: const Icon(Icons.speaker_group_outlined),
                  ),
                  const SizedBox(width: 4),
                ],
                IconButton.filledTonal(
                  tooltip: favorite
                      ? context.l10n.removeFavorite
                      : context.l10n.addFavorite,
                  onPressed: () =>
                      context.read<LibraryProvider>().toggleFavorite(track.id),
                  icon: Icon(favorite
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
                      ? context.l10n.shuffleDisable
                      : context.l10n.shuffleEnable,
                  color: player.shuffleEnabled
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  onPressed: player.toggleShuffle,
                  icon: const Icon(Icons.shuffle_rounded),
                ),
                IconButton(
                  iconSize: 38,
                  tooltip: context.l10n.actionPrevious,
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
                    tooltip: player.playing
                        ? context.l10n.actionPause
                        : context.l10n.actionPlay,
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
                  tooltip: context.l10n.actionNext,
                  onPressed: player.hasNext ? player.next : null,
                  icon: const Icon(Icons.skip_next_rounded),
                ),
                IconButton(
                  tooltip: switch (player.loopMode) {
                    LoopMode.off => context.l10n.repeatQueue,
                    LoopMode.all => context.l10n.repeatTrack,
                    LoopMode.one => context.l10n.repeatOff,
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
                    context.l10n.volumePercent((player.volume * 100).round()),
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
                context.l10n.queueButton(player.queue.length),
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
                        ? Center(child: Text(context.l10n.nothingPlaying))
                        : LyricsSheet(
                            key: ValueKey(currentPlayer.current!.id),
                            track: currentPlayer.current!,
                          ),
                  ),
                ),
              ),
              icon: const Icon(Icons.lyrics_rounded),
              label: Text(context.l10n.lyrics),
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetadataPill(
                    icon: Icons.album_rounded,
                    label: context.l10n.metadata(track.album)),
                _MetadataPill(
                    icon: Icons.auto_awesome_rounded,
                    label: context.l10n.metadata(track.genre)),
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

  static TextStyle? _titleStyle(BuildContext context) =>
      Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -.6,
          );

  Future<void> _showOutputSwitcher(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.audioOutputUnavailable;
    if (!await const AudioOutputService().showOutputSwitcher()) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
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
                        context.l10n.upNext,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    Text(context.l10n.trackCount(queue.length)),
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
                        context.l10n.metadata(track.artist),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        tooltip: context.l10n.removeFromQueue,
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
              Text(context.l10n.emptyPlayerTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      )),
              const SizedBox(height: 8),
              Text(
                context.l10n.emptyPlayerHint,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}
