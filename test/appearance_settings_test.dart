import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/providers/appearance_provider.dart';
import 'package:music_reader_app/services/appearance_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('follows the system theme until a mode is chosen', () async {
    SharedPreferences.setMockInitialValues({});
    final service = AppearanceSettingsService();
    expect(await service.loadThemeMode(), ThemeMode.system);

    final provider = AppearanceProvider(service);
    var notified = 0;
    provider.addListener(() => notified++);
    await provider.setThemeMode(ThemeMode.dark);
    await provider.setThemeMode(ThemeMode.dark);

    expect(provider.themeMode, ThemeMode.dark);
    expect(notified, 1);
    expect(await service.loadThemeMode(), ThemeMode.dark);
  });

  test('ignores an unknown stored theme', () async {
    SharedPreferences.setMockInitialValues({'appearance_theme_mode': 'sepia'});
    expect(await AppearanceSettingsService().loadThemeMode(), ThemeMode.system);
  });
}
