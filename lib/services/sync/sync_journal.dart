import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local timestamps sync needs to merge changes from several devices:
/// when each favorite last changed and when playlists were deleted.
class SyncJournal {
  static const _favoritesKey = 'sync_favorite_times_v1';
  static const _positionsKey = 'sync_position_times_v1';
  static const _deletedPlaylistsKey = 'sync_deleted_playlists_v1';

  final Map<String, DateTime> favoriteTimes = {};
  final Map<String, DateTime> deletedPlaylists = {};

  /// When each audiobook's resume point last changed on this device.
  final Map<String, DateTime> positionTimes = {};

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    favoriteTimes
      ..clear()
      ..addAll(_decode(preferences.getString(_favoritesKey)));
    positionTimes
      ..clear()
      ..addAll(_decode(preferences.getString(_positionsKey)));
    deletedPlaylists
      ..clear()
      ..addAll(_decode(preferences.getString(_deletedPlaylistsKey)));
  }

  Future<void> save() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_favoritesKey, _encode(favoriteTimes));
    await preferences.setString(_positionsKey, _encode(positionTimes));
    await preferences.setString(
        _deletedPlaylistsKey, _encode(deletedPlaylists));
  }

  static String _encode(Map<String, DateTime> values) => jsonEncode({
        for (final entry in values.entries)
          entry.key: entry.value.toIso8601String(),
      });

  static Map<String, DateTime> _decode(String? value) {
    if (value == null || value.isEmpty) return {};
    try {
      return {
        for (final entry in (jsonDecode(value) as Map).entries)
          entry.key as String: DateTime.parse(entry.value as String),
      };
    } on FormatException {
      return {};
    }
  }
}
