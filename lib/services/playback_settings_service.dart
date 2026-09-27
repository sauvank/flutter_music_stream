import 'package:shared_preferences/shared_preferences.dart';

class PlaybackSettingsService {
  static const _fadeDurationKey = 'playback_fade_duration_ms';
  static const defaultFadeDuration = Duration(milliseconds: 500);
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
}
