import 'dart:io';

import 'package:flutter/material.dart';

import '../models/music_track.dart';

class TrackArtwork extends StatelessWidget {
  const TrackArtwork({
    required this.track,
    this.size,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.heroTag,
    super.key,
  });

  final MusicTrack track;
  final double? size;
  final BorderRadius borderRadius;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final colors = _artworkColors(track.id);
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -18,
            bottom: -24,
            child: Icon(
              Icons.album_rounded,
              color: Colors.white.withValues(alpha: .16),
              size: size == null ? 140 : size! * 1.1,
            ),
          ),
          Center(
            child: Icon(
              Icons.graphic_eq_rounded,
              color: Colors.white,
              size: size == null ? 52 : size! * .42,
            ),
          ),
        ],
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
    final artwork = SizedBox.square(
      dimension: size,
      child: ClipRRect(borderRadius: borderRadius, child: image),
    );
    return heroTag == null ? artwork : Hero(tag: heroTag!, child: artwork);
  }
}

List<Color> _artworkColors(String seed) {
  const palettes = [
    [Color(0xFF7C4DFF), Color(0xFFEC407A)],
    [Color(0xFF00BFA5), Color(0xFF2979FF)],
    [Color(0xFFFF7043), Color(0xFFFFCA28)],
    [Color(0xFF5C6BC0), Color(0xFF26C6DA)],
    [Color(0xFFAB47BC), Color(0xFFFF5C8A)],
  ];
  final hash = seed.codeUnits.fold<int>(0, (value, unit) => value + unit);
  return palettes[hash % palettes.length];
}
