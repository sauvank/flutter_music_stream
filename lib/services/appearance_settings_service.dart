import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppearanceSettingsService {
  static const _themeModeKey = 'appearance_theme_mode';
  static const _localeKey = 'appearance_locale';
  static const supportedLanguageCodes = ['fr', 'en'];

  Future<ThemeMode> loadThemeMode() async {
    final name = (await SharedPreferences.getInstance()).getString(
      _themeModeKey,
    );
    return ThemeMode.values.where((mode) => mode.name == name).firstOrNull ??
        ThemeMode.system;
  }

  Future<void> saveThemeMode(ThemeMode mode) async =>
      (await SharedPreferences.getInstance())
          .setString(_themeModeKey, mode.name);

  /// The chosen app language, or null to follow the device.
  Future<Locale?> loadLocale() async {
    final code = (await SharedPreferences.getInstance()).getString(_localeKey);
    return supportedLanguageCodes.contains(code) ? Locale(code!) : null;
  }

  Future<void> saveLocale(Locale? locale) async {
    final preferences = await SharedPreferences.getInstance();
    if (locale == null) {
      await preferences.remove(_localeKey);
    } else {
      await preferences.setString(_localeKey, locale.languageCode);
    }
  }
}
