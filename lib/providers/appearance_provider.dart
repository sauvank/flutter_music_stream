import 'package:flutter/material.dart';

import '../services/appearance_settings_service.dart';

class AppearanceProvider extends ChangeNotifier {
  AppearanceProvider(
    this._service, {
    ThemeMode themeMode = ThemeMode.system,
    Locale? locale,
  })  : _themeMode = themeMode,
        _locale = locale;

  final AppearanceSettingsService _service;
  ThemeMode _themeMode;
  Locale? _locale;

  ThemeMode get themeMode => _themeMode;

  /// Null follows the device language.
  Locale? get locale => _locale;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _service.saveThemeMode(mode);
  }

  Future<void> setLocale(Locale? locale) async {
    if (locale == _locale) return;
    _locale = locale;
    notifyListeners();
    await _service.saveLocale(locale);
  }
}
