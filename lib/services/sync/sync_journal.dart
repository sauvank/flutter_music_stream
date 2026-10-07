import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Local timestamps sync needs to merge changes from several devices:
/// when each favorite last changed and when playlists were deleted.
class SyncJournal {
  static const _favoritesKey = 'sync_favorite_times_v1';
  static const _positionsKey = 'sync_position_times_v1';
  static const _deletedPlaylistsKey = 'sync_deleted_playlists_v1';
  static const _clockKey = 'sync_lamport_clock_v1';
  static const _deviceIdKey = 'sync_actor_id_v1';
  static const _playCountsKey = 'sync_play_counts_v1';

  final Map<String, DateTime> favoriteTimes = {};
  final Map<String, DateTime> deletedPlaylists = {};

  /// When each audiobook's resume point last changed on this device.
  final Map<String, DateTime> positionTimes = {};
  final Map<String, Map<String, int>> playCounts = {};
  DateTime? _clock;
  String deviceId = '';

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
    final clock = preferences.getString(_clockKey);
    _clock = clock == null ? null : DateTime.tryParse(clock);
    deviceId = preferences.getString(_deviceIdKey) ?? _newDeviceId();
    await preferences.setString(_deviceIdKey, deviceId);
    playCounts
      ..clear()
      ..addAll(_decodeCounters(preferences.getString(_playCountsKey)));
  }

  Future<void> save() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_favoritesKey, _encode(favoriteTimes));
    await preferences.setString(_positionsKey, _encode(positionTimes));
    await preferences.setString(
        _deletedPlaylistsKey, _encode(deletedPlaylists));
    if (_clock != null) {
      await preferences.setString(_clockKey, _clock!.toIso8601String());
    }
    await preferences.setString(_playCountsKey, jsonEncode(playCounts));
  }

  DateTime nextTimestamp() {
    final now = DateTime.now().toUtc();
    _clock = _clock == null || now.isAfter(_clock!)
        ? now
        : _clock!.add(const Duration(microseconds: 1));
    return _clock!;
  }

  void observe(DateTime value) {
    if (_clock == null || value.isAfter(_clock!)) _clock = value;
  }

  static String _newDeviceId() => List.generate(
        16,
        (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();

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

  static Map<String, Map<String, int>> _decodeCounters(String? value) {
    if (value == null || value.isEmpty) return {};
    try {
      final decoded = jsonDecode(value) as Map;
      return {
        for (final entry in decoded.entries)
          entry.key as String: (entry.value as Map).map(
            (key, value) => MapEntry(key as String, (value as num).toInt()),
          ),
      };
    } catch (_) {
      return {};
    }
  }
}
