import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local timestamps needed to merge server lists between devices: when each
/// server was added here and when one was removed (keyed by
/// `serverSyncKey`). Best effort: a failed write only weakens merging.
class ServerSyncJournal {
  static const _addedKey = 'sync_server_added_v1';
  static const _deletedKey = 'sync_server_deleted_v1';

  final Map<String, DateTime> added = {};
  final Map<String, DateTime> deleted = {};

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      added
        ..clear()
        ..addAll(_decode(preferences.getString(_addedKey)));
      deleted
        ..clear()
        ..addAll(_decode(preferences.getString(_deletedKey)));
    } catch (error) {
      debugPrint('Server sync journal unavailable: $error');
    }
  }

  Future<void> save() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_addedKey, _encode(added));
      await preferences.setString(_deletedKey, _encode(deleted));
    } catch (error) {
      debugPrint('Server sync journal not saved: $error');
    }
  }

  static String _encode(Map<String, DateTime> values) => jsonEncode({
        for (final entry in values.entries)
          entry.key: entry.value.toIso8601String(),
      });

  static Map<String, DateTime> _decode(String? value) {
    if (value == null || value.isEmpty) return {};
    try {
      return {
        for (final entry in (jsonDecode(value) as Map).entries)
          entry.key as String: DateTime.parse(entry.value as String),
      };
    } on FormatException {
      return {};
    }
  }
}
