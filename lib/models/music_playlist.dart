import 'dart:convert';

class MusicPlaylist {
  const MusicPlaylist({
    required this.id,
    required this.name,
    required this.trackIds,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
  });

  final String id;
  final String name;
  final String description;
  final List<String> trackIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  MusicPlaylist copyWith({
    String? name,
    String? description,
    List<String>? trackIds,
    DateTime? updatedAt,
  }) =>
      MusicPlaylist(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        trackIds: trackIds ?? this.trackIds,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now().toUtc(),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        if (description.isNotEmpty) 'description': description,
        'trackIds': trackIds,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory MusicPlaylist.fromJson(Map<String, Object?> json) => MusicPlaylist(
        id: json['id']! as String,
        name: json['name']! as String,
        description: json['description'] as String? ?? '',
        trackIds: (json['trackIds']! as List<Object?>).cast<String>(),
        createdAt: DateTime.parse(json['createdAt']! as String),
        updatedAt: DateTime.parse(json['updatedAt']! as String),
      );

  static String encodeAll(List<MusicPlaylist> playlists) =>
      jsonEncode(playlists.map((playlist) => playlist.toJson()).toList());

  static List<MusicPlaylist> decodeAll(String value) =>
      (jsonDecode(value) as List<Object?>)
          .map((item) =>
              MusicPlaylist.fromJson((item! as Map).cast<String, Object?>()))
          .toList();
}
