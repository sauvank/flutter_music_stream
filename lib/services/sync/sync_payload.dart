import 'dart:convert';
import 'dart:math';

import '../../models/music_playlist.dart';
import '../../models/server_profile.dart';

enum SyncHistoryChangeKind {
  positionUploaded,
  positionDownloaded,
  favorites,
  plays,
  playlists,
  servers,
  noChanges,
}

class SyncHistoryChange {
  const SyncHistoryChange({
    required this.kind,
    this.label,
    this.positionMs,
    this.count = 1,
  });

  final SyncHistoryChangeKind kind;
  final String? label;
  final int? positionMs;
  final int count;

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        if (label != null) 'label': label,
        if (positionMs != null) 'positionMs': positionMs,
        if (count != 1) 'count': count,
      };

  factory SyncHistoryChange.fromJson(Map<String, Object?> json) =>
      SyncHistoryChange(
        kind: SyncHistoryChangeKind.values.byName(json['kind']! as String),
        label: json['label'] as String?,
        positionMs: json['positionMs'] as int?,
        count: json['count'] as int? ?? 1,
      );
}

class SyncHistoryEntry {
  const SyncHistoryEntry({
    required this.at,
    required this.changes,
    this.id = '',
    this.device = '',
  });

  final String id;
  final String device;
  final DateTime at;
  final List<SyncHistoryChange> changes;

  Map<String, Object?> toJson() => {
        if (id.isNotEmpty) 'id': id,
        if (device.isNotEmpty) 'device': device,
        'at': at.toIso8601String(),
        'changes': [for (final change in changes) change.toJson()],
      };

  factory SyncHistoryEntry.fromJson(Map<String, Object?> json) =>
      SyncHistoryEntry(
        id: json['id'] as String? ?? '',
        device: json['device'] as String? ?? '',
        at: DateTime.parse(json['at']! as String),
        changes: [
          for (final item in json['changes'] as List<Object?>? ?? const [])
            SyncHistoryChange.fromJson((item! as Map).cast<String, Object?>()),
        ],
      );
}

/// Listening state of one track, keyed by its content hash so the same
/// file matches across devices.
class SyncTrackState {
  const SyncTrackState({
    this.favorite = false,
    this.favoriteAt,
    this.playCount = 0,
    this.lastPlayedAt,
    this.positionMs,
    this.positionAt,
    this.playCountsByDevice = const {},
  });

  final bool favorite;

  /// When [favorite] last changed; null for states older than sync.
  final DateTime? favoriteAt;
  final int playCount;
  final DateTime? lastPlayedAt;

  /// Resume point of an audiobook and when it was last saved; the most
  /// recent save wins across devices.
  final int? positionMs;
  final DateTime? positionAt;
  final Map<String, int> playCountsByDevice;

  Map<String, Object?> toJson() => {
        'favorite': favorite,
        if (favoriteAt != null) 'favoriteAt': favoriteAt!.toIso8601String(),
        'playCount': playCount,
        if (playCountsByDevice.isNotEmpty)
          'playCountsByDevice': playCountsByDevice,
        if (lastPlayedAt != null)
          'lastPlayedAt': lastPlayedAt!.toIso8601String(),
        if (positionMs != null && positionAt != null) ...{
          'positionMs': positionMs,
          'positionAt': positionAt!.toIso8601String(),
        },
      };

  factory SyncTrackState.fromJson(Map<String, Object?> json) => SyncTrackState(
        favorite: json['favorite'] as bool? ?? false,
        favoriteAt: _date(json['favoriteAt']),
        playCount: json['playCount'] as int? ?? 0,
        lastPlayedAt: _date(json['lastPlayedAt']),
        positionMs: json['positionMs'] as int?,
        positionAt: _date(json['positionAt']),
        playCountsByDevice: {
          for (final entry
              in ((json['playCountsByDevice'] as Map?) ?? const {}).entries)
            entry.key as String: (entry.value as num).toInt(),
        },
      );

  /// Latest favorite choice wins; per-device listening counters merge by max.
  static SyncTrackState merge(SyncTrackState a, SyncTrackState b) {
    final aAt = a.favoriteAt ?? DateTime.utc(0);
    final bAt = b.favoriteAt ?? DateTime.utc(0);
    final favoriteSource = bAt.isAfter(aAt) ? b : a;
    final positionSource = (b.positionAt ?? DateTime.utc(0))
            .isAfter(a.positionAt ?? DateTime.utc(0))
        ? b
        : a;
    final playCounts = <String, int>{...a.playCountsByDevice};
    for (final entry in b.playCountsByDevice.entries) {
      playCounts[entry.key] = max(playCounts[entry.key] ?? 0, entry.value);
    }
    final playCount = playCounts.isEmpty
        ? max(a.playCount, b.playCount)
        : max(
            max(a.playCount, b.playCount),
            playCounts.values.fold<int>(0, (sum, value) => sum + value),
          );
    final samePositionTime = a.positionAt != null &&
        b.positionAt != null &&
        a.positionAt!.isAtSameMomentAs(b.positionAt!);
    return SyncTrackState(
      positionMs: samePositionTime
          ? max(a.positionMs ?? 0, b.positionMs ?? 0)
          : positionSource.positionMs,
      positionAt: positionSource.positionAt,
      favorite: aAt.isAtSameMomentAs(bAt)
          ? (a.favorite && b.favorite)
          : favoriteSource.favorite,
      favoriteAt: favoriteSource.favoriteAt,
      playCount: playCount,
      playCountsByDevice: playCounts,
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
    this.history = const [],
  });

  final Map<String, SyncTrackState> tracks;
  final List<MusicPlaylist> playlists;

  /// Playlist id → deletion time, so a deletion wins over older copies.
  final Map<String, DateTime> deletedPlaylists;

  /// Servers by [SyncServer.key]; deletions by the same key.
  final Map<String, SyncServer> servers;
  final Map<String, DateTime> deletedServers;
  final List<SyncHistoryEntry> history;

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
        'history': [for (final entry in history) entry.toJson()],
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
        history: [
          for (final item in (json['history'] as List?) ?? const [])
            SyncHistoryEntry.fromJson((item as Map).cast<String, Object?>()),
        ],
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
      if (existing == null ||
          playlist.updatedAt.isAfter(existing.updatedAt) ||
          (playlist.updatedAt.isAtSameMomentAs(existing.updatedAt) &&
              jsonEncode(playlist.toJson()).compareTo(
                    jsonEncode(existing.toJson()),
                  ) >
                  0)) {
        playlists[playlist.id] = playlist;
      }
    }
    // A playlist edited after its deletion elsewhere is kept.
    playlists.removeWhere((id, playlist) {
      final deletedAt = deleted[id];
      return deletedAt != null && !playlist.updatedAt.isAfter(deletedAt);
    });
    final ordered = playlists.values.toList()
      ..sort((x, y) {
        final byDate = x.createdAt.compareTo(y.createdAt);
        return byDate != 0 ? byDate : x.id.compareTo(y.id);
      });
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
      final winner = entry.value.addedAt.isAfter(existing.addedAt) ||
              (entry.value.addedAt.isAtSameMomentAs(existing.addedAt) &&
                  jsonEncode(entry.value.toJson())
                          .compareTo(jsonEncode(existing.toJson())) >
                      0)
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
      history: _mergeHistory(a.history, b.history),
    );
  }

  SyncPayload withHistory(List<SyncHistoryEntry> value) => SyncPayload(
        tracks: tracks,
        playlists: playlists,
        deletedPlaylists: deletedPlaylists,
        servers: servers,
        deletedServers: deletedServers,
        history: value,
      );

  static List<SyncHistoryEntry> _mergeHistory(
    List<SyncHistoryEntry> a,
    List<SyncHistoryEntry> b,
  ) {
    final entries = <String, SyncHistoryEntry>{};
    for (final entry in [...a, ...b]) {
      final id = entry.id.isEmpty
          ? '${entry.at.toUtc().toIso8601String()}|${entry.device}|${entry.changes.map((c) => c.kind.name).join(',')}'
          : entry.id;
      entries[id] = entry;
    }
    final sorted = entries.values.toList()
      ..sort((left, right) {
        final byDate = right.at.compareTo(left.at);
        return byDate != 0 ? byDate : left.id.compareTo(right.id);
      });
    return List.unmodifiable(sorted.take(30));
  }
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

DateTime? _latest(DateTime? a, DateTime? b) {
  if (a == null) return b;
  if (b == null) return a;
  return b.isAfter(a) ? b : a;
}
