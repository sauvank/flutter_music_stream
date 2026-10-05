import 'dart:convert';

/// Where a track's file lives: private copies for imports and downloads,
/// the file in place for [deviceMedia], which the app never deletes.
enum MusicSource { localImport, serverDownload, deviceMedia }

/// A chapter marker read from the file, such as an M4B audiobook chapter.
class TrackChapter {
  const TrackChapter({required this.startMs, required this.title});

  final int startMs;
  final String title;

  Map<String, Object?> toJson() => {'startMs': startMs, 'title': title};

  factory TrackChapter.fromJson(Map<String, Object?> json) => TrackChapter(
        startMs: json['startMs'] as int? ?? 0,
        title: json['title'] as String? ?? '',
      );
}

class MusicTrack {
  // Stored placeholders for missing tags; translated only when displayed.
  static const unknownArtist = 'Artiste inconnu';
  static const unknownAlbum = 'Album inconnu';
  static const unknownGenre = 'Genre inconnu';
  static const untitled = 'Piste sans titre';

  const MusicTrack({
    required this.id,
    required this.title,
    required this.uri,
    required this.addedAt,
    this.artist = unknownArtist,
    this.album = unknownAlbum,
    this.genre = unknownGenre,
    this.artworkUri,
    this.trackNumber,
    this.discNumber,
    this.durationMs,
    this.favorite = false,
    this.lastPositionMs = 0,
    this.lastPlayedAt,
    this.playCount = 0,
    this.metadataRead = false,
    this.source,
    this.sourceUri,
    this.chapters = const [],
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final String genre;
  final String? artworkUri;
  final int? trackNumber;
  final int? discNumber;
  final String uri;
  final int? durationMs;
  final bool favorite;
  final int lastPositionMs;
  final DateTime? lastPlayedAt;
  final int playCount;
  final bool metadataRead;
  final MusicSource? source;
  final String? sourceUri;
  final DateTime addedAt;
  final List<TrackChapter> chapters;

  /// Audiobooks get chapters, a progress bar and spoken-word controls.
  bool get isAudiobook {
    final path = Uri.tryParse(uri)?.path.toLowerCase() ?? '';
    final tagged = genre.toLowerCase().replaceAll(RegExp('[^a-z]'), '');
    return path.endsWith('.m4b') ||
        tagged.contains('audiobook') ||
        tagged.contains('livreaudio') ||
        tagged.contains('hrbuch');
  }

  /// Fraction listened, or null when the length is unknown.
  double? get progress {
    final total = durationMs;
    if (total == null || total <= 0) return null;
    return (lastPositionMs / total).clamp(0.0, 1.0);
  }

  /// Index of the chapter containing [positionMs], or -1 without chapters.
  int chapterIndexAt(int positionMs) {
    var found = -1;
    for (var i = 0; i < chapters.length; i++) {
      if (chapters[i].startMs <= positionMs) found = i;
    }
    return found;
  }

  MusicTrack copyWith({
    bool? favorite,
    int? lastPositionMs,
    DateTime? lastPlayedAt,
    int? playCount,
  }) =>
      MusicTrack(
        id: id,
        title: title,
        artist: artist,
        album: album,
        genre: genre,
        artworkUri: artworkUri,
        trackNumber: trackNumber,
        discNumber: discNumber,
        uri: uri,
        durationMs: durationMs,
        favorite: favorite ?? this.favorite,
        lastPositionMs: lastPositionMs ?? this.lastPositionMs,
        lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
        playCount: playCount ?? this.playCount,
        metadataRead: metadataRead,
        source: source,
        sourceUri: sourceUri,
        addedAt: addedAt,
        chapters: chapters,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'genre': genre,
        'artworkUri': artworkUri,
        'trackNumber': trackNumber,
        'discNumber': discNumber,
        'uri': uri,
        'durationMs': durationMs,
        'favorite': favorite,
        'lastPositionMs': lastPositionMs,
        'lastPlayedAt': lastPlayedAt?.toIso8601String(),
        'playCount': playCount,
        'metadataRead': metadataRead,
        'source': source?.name,
        'sourceUri': sourceUri,
        'addedAt': addedAt.toIso8601String(),
        if (chapters.isNotEmpty)
          'chapters': [for (final chapter in chapters) chapter.toJson()],
      };

  factory MusicTrack.fromJson(Map<String, Object?> json) => MusicTrack(
        id: json['id']! as String,
        title: json['title']! as String,
        artist: json['artist'] as String? ?? unknownArtist,
        album: json['album'] as String? ?? unknownAlbum,
        genre: json['genre'] as String? ?? unknownGenre,
        artworkUri: json['artworkUri'] as String?,
        trackNumber: json['trackNumber'] as int?,
        discNumber: json['discNumber'] as int?,
        uri: json['uri']! as String,
        durationMs: json['durationMs'] as int?,
        favorite: json['favorite'] as bool? ?? false,
        lastPositionMs: json['lastPositionMs'] as int? ?? 0,
        lastPlayedAt: switch (json['lastPlayedAt']) {
          final String value => DateTime.tryParse(value),
          _ => null,
        },
        playCount: json['playCount'] as int? ?? 0,
        metadataRead: json['metadataRead'] as bool? ?? false,
        source: switch (json['source']) {
          'localImport' => MusicSource.localImport,
          'serverDownload' => MusicSource.serverDownload,
          'deviceMedia' => MusicSource.deviceMedia,
          _ => null,
        },
        sourceUri: json['sourceUri'] as String?,
        addedAt: DateTime.parse(json['addedAt']! as String),
        chapters: [
          for (final item in json['chapters'] as List<Object?>? ?? const [])
            TrackChapter.fromJson((item! as Map).cast<String, Object?>()),
        ],
      );

  static String encodeAll(List<MusicTrack> tracks) =>
      jsonEncode(tracks.map((track) => track.toJson()).toList());

  static List<MusicTrack> decodeAll(String value) => (jsonDecode(value)
          as List<Object?>)
      .map(
          (item) => MusicTrack.fromJson((item! as Map).cast<String, Object?>()))
      .toList();
}
