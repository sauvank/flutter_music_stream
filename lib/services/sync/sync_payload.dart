import '../../models/music_playlist.dart';

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

/// Everything synced between devices. Audio files never leave the phone.
class SyncPayload {
  const SyncPayload({
    this.tracks = const {},
    this.playlists = const [],
    this.deletedPlaylists = const {},
  });

  final Map<String, SyncTrackState> tracks;
  final List<MusicPlaylist> playlists;

  /// Playlist id → deletion time, so a deletion wins over older copies.
  final Map<String, DateTime> deletedPlaylists;

  Map<String, Object?> toJson() => {
        'tracks': {
          for (final entry in tracks.entries) entry.key: entry.value.toJson(),
        },
        'playlists': [for (final playlist in playlists) playlist.toJson()],
        'deletedPlaylists': {
          for (final entry in deletedPlaylists.entries)
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
    return SyncPayload(
      tracks: tracks,
      playlists: ordered,
      deletedPlaylists: deleted,
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
