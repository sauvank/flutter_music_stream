import 'dart:convert';

class MusicTrack {
  const MusicTrack({
    required this.id,
    required this.title,
    required this.uri,
    required this.addedAt,
    this.artist = 'Artiste inconnu',
    this.album = 'Album inconnu',
    this.durationMs,
    this.favorite = false,
    this.lastPositionMs = 0,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final String uri;
  final int? durationMs;
  final bool favorite;
  final int lastPositionMs;
  final DateTime addedAt;

  MusicTrack copyWith({bool? favorite, int? lastPositionMs}) => MusicTrack(
        id: id,
        title: title,
        artist: artist,
        album: album,
        uri: uri,
        durationMs: durationMs,
        favorite: favorite ?? this.favorite,
        lastPositionMs: lastPositionMs ?? this.lastPositionMs,
        addedAt: addedAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'uri': uri,
        'durationMs': durationMs,
        'favorite': favorite,
        'lastPositionMs': lastPositionMs,
        'addedAt': addedAt.toIso8601String(),
      };

  factory MusicTrack.fromJson(Map<String, Object?> json) => MusicTrack(
        id: json['id']! as String,
        title: json['title']! as String,
        artist: json['artist'] as String? ?? 'Artiste inconnu',
        album: json['album'] as String? ?? 'Album inconnu',
        uri: json['uri']! as String,
        durationMs: json['durationMs'] as int?,
        favorite: json['favorite'] as bool? ?? false,
        lastPositionMs: json['lastPositionMs'] as int? ?? 0,
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
