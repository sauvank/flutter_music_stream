import 'dart:convert';

class MusicTrack {
  const MusicTrack({
    required this.id,
    required this.title,
    required this.uri,
    required this.addedAt,
    this.artist = 'Artiste inconnu',
    this.album = 'Album inconnu',
    this.genre = 'Genre inconnu',
    this.artworkUri,
    this.trackNumber,
    this.discNumber,
    this.durationMs,
    this.favorite = false,
    this.lastPositionMs = 0,
    this.metadataRead = false,
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
  final bool metadataRead;
  final DateTime addedAt;

  MusicTrack copyWith({bool? favorite, int? lastPositionMs}) => MusicTrack(
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
        metadataRead: metadataRead,
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
        'metadataRead': metadataRead,
        'addedAt': addedAt.toIso8601String(),
      };

  factory MusicTrack.fromJson(Map<String, Object?> json) => MusicTrack(
        id: json['id']! as String,
        title: json['title']! as String,
        artist: json['artist'] as String? ?? 'Artiste inconnu',
        album: json['album'] as String? ?? 'Album inconnu',
        genre: json['genre'] as String? ?? 'Genre inconnu',
        artworkUri: json['artworkUri'] as String?,
        trackNumber: json['trackNumber'] as int?,
        discNumber: json['discNumber'] as int?,
        uri: json['uri']! as String,
        durationMs: json['durationMs'] as int?,
        favorite: json['favorite'] as bool? ?? false,
        lastPositionMs: json['lastPositionMs'] as int? ?? 0,
        metadataRead: json['metadataRead'] as bool? ?? false,
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
