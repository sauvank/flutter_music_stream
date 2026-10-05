import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart' as tags;

import '../models/music_track.dart';

class AudioMetadata {
  const AudioMetadata({
    this.title,
    this.artist,
    this.album,
    this.genre,
    this.trackNumber,
    this.discNumber,
    this.durationMs,
    this.artworkBytes,
    this.artworkExtension,
    this.chapters = const [],
  });

  final String? title;
  final String? artist;
  final String? album;
  final String? genre;
  final int? trackNumber;
  final int? discNumber;
  final int? durationMs;
  final Uint8List? artworkBytes;
  final String? artworkExtension;
  final List<TrackChapter> chapters;
}

class AudioMetadataService {
  const AudioMetadataService();

  Future<AudioMetadata> read(String path) async {
    final tag = tags.readMetadata(File(path), getImage: true);
    final artwork = tag.pictures.where((picture) {
          return picture.pictureType == tags.PictureType.coverFront;
        }).firstOrNull ??
        tag.pictures.firstOrNull;

    return AudioMetadata(
      title: _nonEmpty(tag.title),
      artist: _nonEmpty(tag.artist) ?? _nonEmpty(tag.albumArtist),
      album: _nonEmpty(tag.album),
      genre: tag.genres.map(_nonEmpty).nonNulls.firstOrNull,
      trackNumber: tag.trackNumber,
      discNumber: tag.discNumber,
      durationMs: tag.duration?.inMilliseconds,
      artworkBytes: artwork?.bytes,
      artworkExtension: _extension(artwork?.mimetype),
      chapters: [
        for (final chapter in tag.chapters)
          if (chapter.title.trim().isNotEmpty || chapter.start > Duration.zero)
            TrackChapter(
              startMs: chapter.start.inMilliseconds,
              title: chapter.title.trim(),
            ),
      ]..sort((a, b) => a.startMs.compareTo(b.startMs)),
    );
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String _extension(String? mimeType) => switch (mimeType) {
        'image/png' => 'png',
        'image/gif' => 'gif',
        'image/bmp' => 'bmp',
        'image/tiff' => 'tiff',
        _ => 'jpg',
      };
}
