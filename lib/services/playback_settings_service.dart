import 'package:shared_preferences/shared_preferences.dart';

class PlaybackSettingsService {
  static const _fadeDurationKey = 'playback_fade_duration_ms';
  static const _volumeKey = 'playback_volume';
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
}
