import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/services/playback_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('uses a 500 ms fade by default', () async {
    final service = PlaybackSettingsService();

    expect(
      await service.loadFadeDuration(),
      PlaybackSettingsService.defaultFadeDuration,
    );
  });

  test('persists a supported fade duration', () async {
    final service = PlaybackSettingsService();
    const duration = Duration(seconds: 1);

    await service.saveFadeDuration(duration);

    expect(await service.loadFadeDuration(), duration);
  });

  test('replaces an obsolete value with the default', () async {
    SharedPreferences.setMockInitialValues({
      'playback_fade_duration_ms': 750,
    });

    expect(
      await PlaybackSettingsService().loadFadeDuration(),
      PlaybackSettingsService.defaultFadeDuration,
    );
  });

  test('rejects an unsupported fade duration', () {
    expect(
      () => PlaybackSettingsService()
          .saveFadeDuration(const Duration(milliseconds: 750)),
      throwsArgumentError,
    );
  });
}
