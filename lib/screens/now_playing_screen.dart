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
    if (track == null) {
      return const Center(
          child: Text('Choisissez un morceau dans la bibliothèque.'));
    }
    final maximum = player.duration.inMilliseconds
        .toDouble()
        .clamp(1, double.infinity)
        .toDouble();
    final value =
        player.position.inMilliseconds.toDouble().clamp(0, maximum).toDouble();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          AspectRatio(
            aspectRatio: 1,
            child: TrackArtwork(
              track: track,
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          const Spacer(),
          Text(track.title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(track.artist, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          Slider(
            value: value,
            max: maximum,
            onChanged: (next) =>
                player.seek(Duration(milliseconds: next.round())),
            onChangeEnd: (next) => context
                .read<LibraryProvider>()
                .savePosition(track.id, Duration(milliseconds: next.round())),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(_time(player.position)),
            Text(_time(player.duration))
          ]),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  iconSize: 42,
                  onPressed: player.hasPrevious ? player.previous : null,
                  icon: const Icon(Icons.skip_previous_rounded)),
              const SizedBox(width: 20),
              IconButton.filled(
                  iconSize: 54,
                  onPressed: player.toggle,
                  icon: Icon(player.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded)),
              const SizedBox(width: 20),
              IconButton(
                  iconSize: 42,
                  onPressed: player.hasNext ? player.next : null,
                  icon: const Icon(Icons.skip_next_rounded)),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  String _time(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
