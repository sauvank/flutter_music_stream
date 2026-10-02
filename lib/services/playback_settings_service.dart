import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PlaybackSettingsService {
  static const _fadeDurationKey = 'playback_fade_duration_ms';
  static const _volumeKey = 'playback_volume';
  static const _queueKey = 'playback_queue_v1';
  static const defaultFadeDuration = Duration(milliseconds: 500);
  static const defaultVolume = 1.0;
  static const supportedFadeDurations = [
    Duration.zero,
    Duration(milliseconds: 250),
    defaultFadeDuration,
    Duration(seconds: 1),
  ];

  Future<Duration> loadFadeDuration() async {
    final milliseconds =
        (await SharedPreferences.getInstance()).getInt(_fadeDurationKey);
    final duration = Duration(
      milliseconds: milliseconds ?? defaultFadeDuration.inMilliseconds,
    );
    return supportedFadeDurations.contains(duration)
        ? duration
        : defaultFadeDuration;
  }

  Future<void> saveFadeDuration(Duration duration) async {
    if (!supportedFadeDurations.contains(duration)) {
      throw ArgumentError.value(
        duration,
        'duration',
        'Unsupported playback fade duration',
      );
    }
    await (await SharedPreferences.getInstance())
        .setInt(_fadeDurationKey, duration.inMilliseconds);
  }

  Future<double> loadVolume() async {
    final volume =
        (await SharedPreferences.getInstance()).getDouble(_volumeKey);
    if (volume == null || !volume.isFinite || volume < 0 || volume > 1) {
      return defaultVolume;
    }
    return volume;
  }

  Future<void> saveVolume(double volume) async {
    if (!volume.isFinite || volume < 0 || volume > 1) {
      throw ArgumentError.value(volume, 'volume', 'Volume must be from 0 to 1');
    }
    await (await SharedPreferences.getInstance()).setDouble(_volumeKey, volume);
  }

  /// The last queue as track ids, with the track that was playing.
  Future<({List<String> trackIds, String? currentId})?> loadQueue() async {
    final value = (await SharedPreferences.getInstance()).getString(_queueKey);
    if (value == null) return null;
    try {
      final json = (jsonDecode(value) as Map).cast<String, Object?>();
      return (
        trackIds: (json['trackIds']! as List<Object?>).cast<String>(),
        currentId: json['currentId'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveQueue(List<String> trackIds, String? currentId) async {
    await (await SharedPreferences.getInstance()).setString(
      _queueKey,
      jsonEncode({'trackIds': trackIds, 'currentId': currentId}),
    );
  }
}
