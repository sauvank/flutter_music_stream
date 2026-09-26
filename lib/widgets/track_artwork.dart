import 'dart:io';

import 'package:flutter/material.dart';

import '../models/music_track.dart';

class TrackArtwork extends StatelessWidget {
  const TrackArtwork({
    required this.track,
    this.size,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    super.key,
  });

  final MusicTrack track;
  final double? size;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Icon(
        Icons.music_note_rounded,
        color: Theme.of(context).colorScheme.onSecondaryContainer,
        size: size == null ? 32 : size! * .45,
      ),
    );
    final artworkUri = track.artworkUri;
    final image = artworkUri == null
        ? fallback
        : Image.file(
            File.fromUri(Uri.parse(artworkUri)),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
          );
    return SizedBox.square(
      dimension: size,
      child: ClipRRect(borderRadius: borderRadius, child: image),
    );
  }
}
