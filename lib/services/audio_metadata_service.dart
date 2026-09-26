import 'dart:typed_data';

import 'package:audiotags/audiotags.dart';

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
}

class AudioMetadataService {
  const AudioMetadataService();

  Future<AudioMetadata> read(String path) async {
    final tag = await AudioTags.read(path);
    if (tag == null) return const AudioMetadata();
    final artwork = tag.pictures.where((picture) {
          return picture.pictureType == PictureType.coverFront;
        }).firstOrNull ??
        tag.pictures.firstOrNull;

    return AudioMetadata(
      title: _nonEmpty(tag.title),
      artist: _nonEmpty(tag.trackArtist) ?? _nonEmpty(tag.albumArtist),
      album: _nonEmpty(tag.album),
      genre: _nonEmpty(tag.genre),
      trackNumber: tag.trackNumber,
      discNumber: tag.discNumber,
      durationMs: tag.duration == null ? null : tag.duration! * 1000,
      artworkBytes: artwork?.bytes,
      artworkExtension: _extension(artwork?.mimeType),
    );
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String _extension(MimeType? mimeType) => switch (mimeType) {
        MimeType.png => 'png',
        MimeType.gif => 'gif',
        MimeType.bmp => 'bmp',
        MimeType.tiff => 'tiff',
        MimeType.jpeg || null => 'jpg',
      };
}
