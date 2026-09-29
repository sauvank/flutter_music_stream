import 'package:flutter/material.dart';

import '../services/appearance_settings_service.dart';

class AppearanceProvider extends ChangeNotifier {
  AppearanceProvider(this._service, {ThemeMode themeMode = ThemeMode.system})
      : _themeMode = themeMode;

  final AppearanceSettingsService _service;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _service.saveThemeMode(mode);
  }
}
