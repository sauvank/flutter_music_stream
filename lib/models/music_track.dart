import 'dart:convert';

enum MusicSource { localImport, serverDownload }

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
          _ => null,
        },
        sourceUri: json['sourceUri'] as String?,
        addedAt: DateTime.parse(json['addedAt']! as String),
      );

  static String encodeAll(List<MusicTrack> tracks) =>
      jsonEncode(tracks.map((track) => track.toJson()).toList());

  static List<MusicTrack> decodeAll(String value) => (jsonDecode(value)
          as List<Object?>)
      .map(
          (item) => MusicTrack.fromJson((item! as Map).cast<String, Object?>()))
      .toList();
}
