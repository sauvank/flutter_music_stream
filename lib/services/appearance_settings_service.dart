import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppearanceSettingsService {
  static const _themeModeKey = 'appearance_theme_mode';

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
}
