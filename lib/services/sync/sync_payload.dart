import '../../models/music_playlist.dart';
import '../../models/server_profile.dart';

/// Listening state of one track, keyed by its content hash so the same
/// file matches across devices.
class SyncTrackState {
  const SyncTrackState({
    this.favorite = false,
    this.favoriteAt,
    this.playCount = 0,
    this.lastPlayedAt,
  });

  final bool favorite;

  /// When [favorite] last changed; null for states older than sync.
  final DateTime? favoriteAt;
  final int playCount;
  final DateTime? lastPlayedAt;

  Map<String, Object?> toJson() => {
        'favorite': favorite,
        if (favoriteAt != null) 'favoriteAt': favoriteAt!.toIso8601String(),
        'playCount': playCount,
        if (lastPlayedAt != null)
          'lastPlayedAt': lastPlayedAt!.toIso8601String(),
      };

  factory SyncTrackState.fromJson(Map<String, Object?> json) => SyncTrackState(
        favorite: json['favorite'] as bool? ?? false,
        favoriteAt: _date(json['favoriteAt']),
        playCount: json['playCount'] as int? ?? 0,
        lastPlayedAt: _date(json['lastPlayedAt']),
      );

  /// Latest favorite choice wins; listening counters keep the maximum.
  static SyncTrackState merge(SyncTrackState a, SyncTrackState b) {
    final aAt = a.favoriteAt ?? DateTime.utc(0);
    final bAt = b.favoriteAt ?? DateTime.utc(0);
    final favoriteSource = bAt.isAfter(aAt) ? b : a;
    return SyncTrackState(
      favorite: favoriteSource.favorite,
      favoriteAt: favoriteSource.favoriteAt,
      playCount: a.playCount > b.playCount ? a.playCount : b.playCount,
      lastPlayedAt: _latest(a.lastPlayedAt, b.lastPlayedAt),
    );
  }
}

/// Identity of a server across devices: the same address, type and user is
/// the same server even if each device generated its own profile id.
String serverSyncKey(ServerType type, String baseUrl, String username) =>
    '${type.name}|${baseUrl.trim().toLowerCase()}|$username';

/// A server profile with its password, travelling only inside the encrypted
/// envelope.
class SyncServer {
  const SyncServer({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.type,
    required this.addedAt,
    this.username = '',
    this.password = '',
  });

  final String id;
  final String name;
  final String baseUrl;
  final ServerType type;
  final String username;
  final String password;
  final DateTime addedAt;

  String get key => serverSyncKey(type, baseUrl, username);

  ServerProfile get profile => ServerProfile(
        id: id,
        name: name,
        baseUrl: baseUrl,
        type: type,
        username: username,
      );

  SyncServer withPassword(String value) => SyncServer(
        id: id,
        name: name,
        baseUrl: baseUrl,
        type: type,
        addedAt: addedAt,
        username: username,
        password: value,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        'type': type.name,
        'username': username,
        'password': password,
        'addedAt': addedAt.toIso8601String(),
      };

  factory SyncServer.fromJson(Map<String, Object?> json) => SyncServer(
        id: json['id']! as String,
        name: json['name']! as String,
        baseUrl: json['baseUrl']! as String,
        type: ServerType.values.byName(json['type']! as String),
        username: json['username'] as String? ?? '',
        password: json['password'] as String? ?? '',
        addedAt: _date(json['addedAt']) ?? DateTime.utc(0),
      );
}

/// Everything synced between devices. Audio files never leave the phone.
class SyncPayload {
  const SyncPayload({
    this.tracks = const {},
    this.playlists = const [],
    this.deletedPlaylists = const {},
    this.servers = const {},
    this.deletedServers = const {},
  });

  final Map<String, SyncTrackState> tracks;
  final List<MusicPlaylist> playlists;

  /// Playlist id → deletion time, so a deletion wins over older copies.
  final Map<String, DateTime> deletedPlaylists;

  /// Servers by [SyncServer.key]; deletions by the same key.
  final Map<String, SyncServer> servers;
  final Map<String, DateTime> deletedServers;

  Map<String, Object?> toJson() => {
        'tracks': {
          for (final entry in tracks.entries) entry.key: entry.value.toJson(),
        },
        'playlists': [for (final playlist in playlists) playlist.toJson()],
        'deletedPlaylists': {
          for (final entry in deletedPlaylists.entries)
            entry.key: entry.value.toIso8601String(),
        },
        'servers': [for (final server in servers.values) server.toJson()],
        'deletedServers': {
          for (final entry in deletedServers.entries)
            entry.key: entry.value.toIso8601String(),
        },
      };

  factory SyncPayload.fromJson(Map<String, Object?> json) => SyncPayload(
        tracks: {
          for (final entry in ((json['tracks'] as Map?) ?? const {}).entries)
            entry.key as String: SyncTrackState.fromJson(
                (entry.value as Map).cast<String, Object?>()),
        },
        playlists: [
          for (final item in (json['playlists'] as List?) ?? const [])
            MusicPlaylist.fromJson((item as Map).cast<String, Object?>()),
        ],
        deletedPlaylists: {
          for (final entry
              in ((json['deletedPlaylists'] as Map?) ?? const {}).entries)
            entry.key as String: DateTime.parse(entry.value as String),
        },
        servers: {
          for (final item in (json['servers'] as List?) ?? const [])
            ...() {
              final server =
                  SyncServer.fromJson((item as Map).cast<String, Object?>());
              return {server.key: server};
            }(),
        },
        deletedServers: {
          for (final entry
              in ((json['deletedServers'] as Map?) ?? const {}).entries)
            entry.key as String: DateTime.parse(entry.value as String),
        },
      );

  static SyncPayload merge(SyncPayload a, SyncPayload b) {
    final tracks = <String, SyncTrackState>{...a.tracks};
    for (final entry in b.tracks.entries) {
      final existing = tracks[entry.key];
      tracks[entry.key] = existing == null
          ? entry.value
          : SyncTrackState.merge(existing, entry.value);
    }
    final deleted = <String, DateTime>{...a.deletedPlaylists};
    for (final entry in b.deletedPlaylists.entries) {
      deleted[entry.key] = _latest(deleted[entry.key], entry.value)!;
    }
    final playlists = <String, MusicPlaylist>{
      for (final playlist in a.playlists) playlist.id: playlist,
    };
    for (final playlist in b.playlists) {
      final existing = playlists[playlist.id];
      if (existing == null || playlist.updatedAt.isAfter(existing.updatedAt)) {
        playlists[playlist.id] = playlist;
      }
    }
    // A playlist edited after its deletion elsewhere is kept.
    playlists.removeWhere((id, playlist) {
      final deletedAt = deleted[id];
      return deletedAt != null && !playlist.updatedAt.isAfter(deletedAt);
    });
    final ordered = playlists.values.toList()
      ..sort((x, y) => x.createdAt.compareTo(y.createdAt));
    final deletedServers = <String, DateTime>{...a.deletedServers};
    for (final entry in b.deletedServers.entries) {
      deletedServers[entry.key] =
          _latest(deletedServers[entry.key], entry.value)!;
    }
    final servers = <String, SyncServer>{...a.servers};
    for (final entry in b.servers.entries) {
      final existing = servers[entry.key];
      if (existing == null) {
        servers[entry.key] = entry.value;
        continue;
      }
      final winner = entry.value.addedAt.isAfter(existing.addedAt)
          ? entry.value
          : existing;
      final loser = identical(winner, existing) ? entry.value : existing;
      servers[entry.key] = winner.password.isEmpty && loser.password.isNotEmpty
          ? winner.withPassword(loser.password)
          : winner;
    }
    // A server added again after its deletion elsewhere is kept.
    servers.removeWhere((key, server) {
      final deletedAt = deletedServers[key];
      return deletedAt != null && !server.addedAt.isAfter(deletedAt);
    });
    return SyncPayload(
      tracks: tracks,
      playlists: ordered,
      deletedPlaylists: deleted,
      servers: servers,
      deletedServers: deletedServers,
    );
  }
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

DateTime? _latest(DateTime? a, DateTime? b) {
  if (a == null) return b;
  if (b == null) return a;
  return b.isAfter(a) ? b : a;
}
