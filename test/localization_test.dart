import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/l10n/l10n.dart';
import 'package:music_reader_app/models/music_track.dart';
import 'package:music_reader_app/providers/appearance_provider.dart';
import 'package:music_reader_app/services/appearance_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('every French message has an English translation', () {
    Map<String, Object?> read(String code) =>
        (jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync()) as Map)
            .cast<String, Object?>()
          ..removeWhere((key, _) => key.startsWith('@'));

    expect(read('en').keys.toSet(), read('fr').keys.toSet());
  });

  test('plurals follow each language rules', () {
    final fr = lookupAppLocalizations(const Locale('fr'));
    final en = lookupAppLocalizations(const Locale('en'));

    expect(fr.trackCount(0), '0 morceau');
    expect(fr.trackCount(2), '2 morceaux');
    expect(en.trackCount(1), '1 track');
    expect(en.trackCount(0), '0 tracks');
  });

  test('stored placeholders for missing tags are translated', () {
    final en = lookupAppLocalizations(const Locale('en'));

    expect(en.metadata(MusicTrack.unknownArtist), 'Unknown artist');
    expect(en.metadata(MusicTrack.unknownAlbum), 'Unknown album');
    expect(en.metadata('Björk'), 'Björk');
  });

  test('remembers the chosen language and can follow the device again',
      () async {
    SharedPreferences.setMockInitialValues({});
    final service = AppearanceSettingsService();
    final provider = AppearanceProvider(service);

    await provider.setLocale(const Locale('en'));
    expect(await service.loadLocale(), const Locale('en'));

    await provider.setLocale(null);
    expect(provider.locale, isNull);
    expect(await service.loadLocale(), isNull);
  });

  test('ignores an unsupported stored language', () async {
    SharedPreferences.setMockInitialValues({'appearance_locale': 'de'});
    expect(await AppearanceSettingsService().loadLocale(), isNull);
  });
}
