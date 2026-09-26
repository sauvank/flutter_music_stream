import 'dart:convert';

enum ServerType { webdav, http }

class ServerProfile {
  const ServerProfile({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.type,
    this.username = '',
  });

  final String id;
  final String name;
  final String baseUrl;
  final ServerType type;
  final String username;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        'type': type.name,
        'username': username,
      };

  factory ServerProfile.fromJson(Map<String, Object?> json) => ServerProfile(
        id: json['id']! as String,
        name: json['name']! as String,
        baseUrl: json['baseUrl']! as String,
        type: ServerType.values.byName(json['type']! as String),
        username: json['username'] as String? ?? '',
      );

  static String encodeAll(List<ServerProfile> profiles) =>
      jsonEncode(profiles.map((profile) => profile.toJson()).toList());

  static List<ServerProfile> decodeAll(String value) =>
      (jsonDecode(value) as List<Object?>)
          .map((item) =>
              ServerProfile.fromJson((item! as Map).cast<String, Object?>()))
          .toList();
}
