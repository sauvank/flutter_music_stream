import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../models/music_track.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../services/audio_output_service.dart';
import '../widgets/audio_visualizer.dart';
import '../widgets/track_artwork.dart';
import 'lyrics_sheet.dart';
import '../l10n/l10n.dart';
import 'library_screen.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key, this.onClose});

  /// Leaves the screen when the user pulls it down from the top.
  final VoidCallback? onClose;

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

    // A restored queue has no player duration until the track loads.
    final duration = player.duration > Duration.zero
        ? player.duration
        : Duration(milliseconds: track.durationMs ?? 0);
    final maximum =
        duration.inMilliseconds.toDouble().clamp(1, double.infinity).toDouble();
    final screenHeight = MediaQuery.sizeOf(context).height;
    final compactHeight = screenHeight < 760;
    return _ArtworkTint(
      track: track,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOutCubic,
        child: NotificationListener<ScrollUpdateNotification>(
          key: ValueKey(track.id),
          onNotification: (notification) {
            if (onClose != null &&
                notification.dragDetails != null &&
                notification.metrics.pixels < -110) {
              HapticFeedback.lightImpact();
              onClose!();
            }
            return false;
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 190),
            // Keep the controls a readable width on desktop-sized windows.
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
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
                        Column(
                          children: [
                            Text(
                              context.l10n.nowPlayingLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    letterSpacing: 1.6,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            if (player.sleepTimerActive)
                              const _SleepTimerLabel(),
                          ],
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 38,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            tooltip: context.l10n.sleepTimer,
                            color: player.sleepTimerActive
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            onPressed: () => showModalBottomSheet<void>(
                              context: context,
                              showDragHandle: true,
                              builder: (_) => const _SleepTimerSheet(),
                            ),
                            icon: Icon(player.sleepTimerActive
                                ? Icons.bedtime_rounded
                                : Icons.bedtime_outlined),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compactHeight ? 14 : 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final widthLimit =
                            constraints.maxWidth.clamp(180.0, 460.0);
                        // A title wrapping to a second line takes that height from
                        // the artwork, so the controls stay above the navigation.
                        final title = TextPainter(
                          text: TextSpan(
                              text: track.title, style: _titleStyle(context)),
                          maxLines: 1,
                          textDirection: Directionality.of(context),
                          textScaler: MediaQuery.textScalerOf(context),
                        )..layout(maxWidth: constraints.maxWidth - 156);
                        final extraTitleLine =
                            title.didExceedMaxLines ? title.height : 0.0;
                        title.dispose();
                        final heightLimit =
                            (screenHeight - 500 - extraTitleLine)
                                .clamp(180.0, 460.0);
                        final artworkSize =
                            widthLimit < heightLimit ? widthLimit : heightLimit;
                        // Swiping the artwork changes track, like the mini player.
                        return GestureDetector(
                          onHorizontalDragEnd: (details) {
                            final velocity = details.primaryVelocity ?? 0;
                            if (velocity < -300 && player.hasNext) {
                              _tap(player.next);
                            } else if (velocity > 300 && player.hasPrevious) {
                              _tap(player.previous);
                            }
                          },
                          child: Container(
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
                              _ArtistAlbumLine(track: track),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: context.l10n.addToPlaylist,
                          onPressed: () =>
                              showAddToPlaylistSheet(context, [track]),
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
                          onPressed: () => context
                              .read<LibraryProvider>()
                              .toggleFavorite(track.id),
                          icon: Icon(favorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded),
                        ),
                      ],
                    ),
                    if (track.isAudiobook)
                      const _AudiobookPanel()
                    else ...[
                      SizedBox(height: compactHeight ? 12 : 22),
                      ValueListenableBuilder<Duration>(
                        valueListenable: player.positionListenable,
                        builder: (context, position, _) => Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 6,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 7),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 18),
                              ),
                              child: Slider(
                                value: duration > Duration.zero
                                    ? position.inMilliseconds
                                        .toDouble()
                                        .clamp(0, maximum)
                                        .toDouble()
                                    : 0,
                                max: maximum,
                                onChanged: (next) => player
                                    .seek(Duration(milliseconds: next.round())),
                                onChangeEnd: (next) => context
                                    .read<LibraryProvider>()
                                    .savePosition(track.id,
                                        Duration(milliseconds: next.round())),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_time(position)),
                                  Text(
                                      '-${_time(_remaining(duration, position))}'),
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
                            onPressed: () => _tap(player.toggleShuffle),
                            icon: const Icon(Icons.shuffle_rounded),
                          ),
                          IconButton(
                            iconSize: 38,
                            tooltip: context.l10n.actionPrevious,
                            onPressed: player.hasPrevious
                                ? () => _tap(player.previous)
                                : null,
                            icon: const Icon(Icons.skip_previous_rounded),
                          ),
                          const SizedBox(width: 8),
                          _PlayButton(player: player),
                          const SizedBox(width: 8),
                          IconButton(
                            iconSize: 38,
                            tooltip: context.l10n.actionNext,
                            onPressed:
                                player.hasNext ? () => _tap(player.next) : null,
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
                              context.l10n
                                  .volumePercent((player.volume * 100).round()),
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
                            builder: (context, currentPlayer, _) =>
                                FractionallySizedBox(
                              heightFactor: .78,
                              child: currentPlayer.current == null
                                  ? Center(
                                      child: Text(context.l10n.nothingPlaying))
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
                    ],
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
                            label: _time(
                                Duration(milliseconds: track.durationMs!)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
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

/// Tints Now Playing and its controls with colors drawn from the artwork.
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.player});
  final PlayerProvider player;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
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
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: .34),
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
          onPressed: () => _tap(player.toggle),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              key: ValueKey(player.playing),
            ),
          ),
        ),
      );
}

String _time(Duration value) {
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (value.inHours == 0) return '${value.inMinutes}:$seconds';
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  return '${value.inHours}:$minutes:$seconds';
}

void _showChapters(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ChaptersSheet(),
    );

/// Spoken-word layout: the slider spans the current chapter, because a
/// whole 18-hour book on one slider cannot be scrubbed with a finger.
class _AudiobookPanel extends StatelessWidget {
  const _AudiobookPanel();

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final track = player.current!;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 14),
        ValueListenableBuilder<Duration>(
          valueListenable: player.positionListenable,
          builder: (context, position, _) {
            final total = player.duration > Duration.zero
                ? player.duration.inMilliseconds
                : track.durationMs ?? 0;
            final chapters = track.chapters;
            final index = track.chapterIndexAt(position.inMilliseconds);
            final start = index >= 0 ? chapters[index].startMs : 0;
            final end = index >= 0 && index + 1 < chapters.length
                ? chapters[index + 1].startMs
                : total;
            final span = end - start > 0 ? end - start : 1;
            final inChapter =
                (position.inMilliseconds - start).clamp(0, span).toInt();
            final left = total - position.inMilliseconds;
            final percent =
                total > 0 ? (position.inMilliseconds * 100 / total).floor() : 0;
            final title = index >= 0 ? _chapterTitle(chapters[index]) : null;
            return Column(
              children: [
                if (index >= 0)
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _showChapters(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Column(
                        children: [
                          if (title != null)
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          Text(
                            l10n.chapterPosition(index + 1, chapters.length),
                            style: (title == null
                                    ? theme.textTheme.titleMedium
                                    : theme.textTheme.labelMedium)
                                ?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 18),
                  ),
                  child: Slider(
                    value: inChapter.toDouble(),
                    max: span.toDouble(),
                    onChanged: (next) => player
                        .seek(Duration(milliseconds: start + next.round())),
                    onChangeEnd: (next) => context
                        .read<LibraryProvider>()
                        .savePosition(track.id,
                            Duration(milliseconds: start + next.round())),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_time(Duration(milliseconds: inChapter))),
                      Text(
                          '-${_time(Duration(milliseconds: span - inChapter))}'),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.audiobookOverall(
                    percent.clamp(0, 100).toInt(),
                    _time(Duration(
                      milliseconds: (left > 0 ? left : 0) ~/ player.speed,
                    )),
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 32,
              tooltip: l10n.rewind30,
              onPressed: () => player.skipBy(const Duration(seconds: -30)),
              icon: const Icon(Icons.replay_30_rounded),
            ),
            IconButton(
              iconSize: 36,
              tooltip: l10n.previousChapter,
              onPressed: () => _tap(player.previousChapter),
              icon: const Icon(Icons.skip_previous_rounded),
            ),
            const SizedBox(width: 6),
            _PlayButton(player: player),
            const SizedBox(width: 6),
            IconButton(
              iconSize: 36,
              tooltip: l10n.nextChapter,
              onPressed: track.chapters.isEmpty
                  ? null
                  : () => _tap(player.nextChapter),
              icon: const Icon(Icons.skip_next_rounded),
            ),
            IconButton(
              iconSize: 32,
              tooltip: l10n.forward30,
              onPressed: () => player.skipBy(const Duration(seconds: 30)),
              icon: const Icon(Icons.forward_30_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            _SpeedButton(player: player),
            if (track.chapters.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => _showChapters(context),
                icon: const Icon(Icons.list_rounded),
                label: Text(l10n.chapters),
              ),
          ],
        ),
      ],
    );
  }
}

/// A chapter's own title, or null when it only repeats its number
/// ("Chapitre 5", "Track 05"), which the position line already shows.
String? _chapterTitle(TrackChapter chapter) {
  final title = chapter.title.trim();
  final generic = RegExp(
    r'^(chapitre|chapter|chap\.?|ch\.?|partie|part|piste|track)?\s*0*\d+$',
    caseSensitive: false,
  );
  return title.isEmpty || generic.hasMatch(title) ? null : title;
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({required this.player});
  final PlayerProvider player;

  static const speeds = [0.75, 1.0, 1.1, 1.25, 1.5, 1.75, 2.0];

  @override
  Widget build(BuildContext context) => PopupMenuButton<double>(
        tooltip: context.l10n.playbackSpeed,
        initialValue: player.speed,
        onSelected: player.setSpeed,
        itemBuilder: (_) => [
          for (final value in speeds)
            CheckedPopupMenuItem(
              value: value,
              checked: value == player.speed,
              child: Text('${value}x'),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.speed_rounded, size: 18),
              const SizedBox(width: 8),
              Text('${player.speed}x',
                  style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      );
}

class _ChaptersSheet extends StatelessWidget {
  const _ChaptersSheet();

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final track = player.current;
    if (track == null) return const SizedBox.shrink();
    final active = player.chapterIndexAt(player.position);
    final colors = Theme.of(context).colorScheme;
    return FractionallySizedBox(
      heightFactor: .7,
      child: ListView.builder(
        itemCount: track.chapters.length,
        itemBuilder: (context, index) {
          final chapter = track.chapters[index];
          final selected = index == active;
          return ListTile(
            selected: selected,
            leading: selected
                ? Icon(Icons.graphic_eq_rounded, color: colors.primary)
                : Text('${index + 1}'),
            title: Text(
              _chapterTitle(chapter) ?? context.l10n.chapterDefault(index + 1),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(_time(Duration(milliseconds: chapter.startMs))),
            onTap: () {
              player.seekToChapter(index);
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }
}

class _ArtworkTint extends StatefulWidget {
  const _ArtworkTint({required this.track, required this.child});
  final MusicTrack track;
  final Widget child;

  @override
  State<_ArtworkTint> createState() => _ArtworkTintState();
}

class _ArtworkTintState extends State<_ArtworkTint> {
  // Extraction takes a few dozen milliseconds; replays reuse the result.
  static final _cache = <String, ColorScheme>{};
  ColorScheme? _scheme;
  String? _key;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(_ArtworkTint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track.artworkUri != widget.track.artworkUri) _resolve();
  }

  Future<void> _resolve() async {
    final uri = widget.track.artworkUri;
    final brightness = Theme.of(context).brightness;
    final key = uri == null ? null : '$uri|${brightness.name}';
    if (key == _key) return;
    _key = key;
    if (uri == null || key == null) {
      _scheme = null;
      return;
    }
    final cached = _cache[key];
    if (cached != null) {
      _scheme = cached;
      return;
    }
    try {
      final scheme = await ColorScheme.fromImageProvider(
        provider: ResizeImage(
          FileImage(File.fromUri(Uri.parse(uri))),
          width: 96,
          height: 96,
        ),
        brightness: brightness,
      );
      if (_cache.length >= 64) _cache.remove(_cache.keys.first);
      _cache[key] = scheme;
      if (mounted && _key == key) setState(() => _scheme = scheme);
    } catch (_) {
      // Unreadable artwork keeps the app colors.
      if (mounted && _key == key) setState(() => _scheme = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = _scheme;
    final tint = scheme == null
        ? Colors.transparent
        : scheme.primaryContainer.withValues(
            alpha: theme.brightness == Brightness.dark ? .45 : .6,
          );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tint, tint.withValues(alpha: 0)],
          stops: const [0, .8],
        ),
      ),
      child: AnimatedTheme(
        duration: const Duration(milliseconds: 600),
        data: theme.copyWith(colorScheme: scheme ?? theme.colorScheme),
        child: widget.child,
      ),
    );
  }
}

class _SleepTimerLabel extends StatefulWidget {
  const _SleepTimerLabel();

  @override
  State<_SleepTimerLabel> createState() => _SleepTimerLabelState();
}

class _SleepTimerLabelState extends State<_SleepTimerLabel> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker =
        Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final sleepAt = player.sleepAt;
    final String text;
    if (sleepAt == null) {
      text = context.l10n.sleepTimerAtTrackEnd;
    } else {
      final left = sleepAt.difference(DateTime.now());
      final seconds = left.isNegative ? 0 : left.inSeconds;
      text = context.l10n.sleepTimerRemaining(
          '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}');
    }
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}

class _SleepTimerSheet extends StatelessWidget {
  const _SleepTimerSheet();

  static const _minutes = [15, 30, 45, 60, 90];

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    void choose(VoidCallback action) {
      action();
      Navigator.pop(context);
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(context.l10n.sleepTimer,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            ListTile(
              leading: const Icon(Icons.timer_off_outlined),
              title: Text(context.l10n.sleepTimerOff),
              selected: !player.sleepTimerActive,
              onTap: () => choose(() => player.setSleepTimer(null)),
            ),
            for (final minutes in _minutes)
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: Text(context.l10n.sleepTimerMinutes(minutes)),
                onTap: () => choose(
                    () => player.setSleepTimer(Duration(minutes: minutes))),
              ),
            if (player.current?.chapters.isNotEmpty == true)
              ListTile(
                leading: const Icon(Icons.bookmark_outline_rounded),
                title: Text(context.l10n.sleepTimerEndOfChapter),
                selected: player.sleepAtChapterEnd,
                onTap: () => choose(player.setSleepAtChapterEnd),
              ),
            ListTile(
              leading: const Icon(Icons.music_off_outlined),
              title: Text(player.current?.isAudiobook == true
                  ? context.l10n.sleepTimerEndOfBook
                  : context.l10n.sleepTimerEndOfTrack),
              selected: player.sleepAtTrackEnd,
              onTap: () => choose(player.setSleepAtTrackEnd),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
                  onReorderStart: (_) => HapticFeedback.mediumImpact(),
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

/// Playback buttons answer with a light tap, like system media controls.
void _tap(Future<void> Function() action) {
  HapticFeedback.lightImpact();
  action();
}

/// "Artist • Album"; tapping the artist lists all of their tracks.
class _ArtistAlbumLine extends StatelessWidget {
  const _ArtistAlbumLine({required this.track});
  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    final known = track.artist != MusicTrack.unknownArtist;
    return Row(
      children: [
        Flexible(
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: known ? () => showArtistTracks(context, track.artist) : null,
            child: Text(
              context.l10n.metadata(track.artist),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: known
                  ? style?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    )
                  : style,
            ),
          ),
        ),
        Text('  •  ', style: style),
        Flexible(
          child: Text(
            context.l10n.metadata(track.album),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}
