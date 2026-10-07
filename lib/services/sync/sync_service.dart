import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sync_crypto.dart';
import 'sync_payload.dart';

class SyncSettings {
  const SyncSettings({
    required this.uid,
    required this.kdf,
    this.lastSyncAt,
  });

  /// The account whose envelope this device joined.
  final String uid;
  final SyncKdf kdf;
  final DateTime? lastSyncAt;

  SyncSettings copyWith({DateTime? lastSyncAt, SyncKdf? kdf}) => SyncSettings(
        uid: uid,
        kdf: kdf ?? this.kdf,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      );

  Map<String, Object?> toJson() => {
        'uid': uid,
        'kdf': kdf.toJson(),
        if (lastSyncAt != null) 'lastSyncAt': lastSyncAt!.toIso8601String(),
      };

  /// Settings from the former WebDAV sync have no account and are dropped.
  factory SyncSettings.fromJson(Map<String, Object?> json) => SyncSettings(
        uid: json['uid']! as String,
        kdf: SyncKdf.fromJson((json['kdf']! as Map).cast<String, Object?>()),
        lastSyncAt: DateTime.tryParse(json['lastSyncAt'] as String? ?? ''),
      );
}

/// Keeps sync settings and the derived key on this device.
class SyncService {
  SyncService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _settingsKey = 'sync_settings_v1';
  static const _keyKey = 'sync_key_v1';
  static const _historyKey = 'sync_history_v1';
  static const _historyLimit = 30;

  final FlutterSecureStorage _secureStorage;

  Future<SyncSettings?> loadSettings() async {
    final value = (await SharedPreferences.getInstance()).getString(
      _settingsKey,
    );
    if (value == null) return null;
    try {
      return SyncSettings.fromJson(
          (jsonDecode(value) as Map).cast<String, Object?>());
    } catch (_) {
      // Unreadable or legacy WebDAV settings: start over cleanly.
      await clear();
      return null;
    }
  }

  Future<void> saveSettings(SyncSettings settings) async =>
      (await SharedPreferences.getInstance())
          .setString(_settingsKey, jsonEncode(settings.toJson()));

  /// The derived key, never the passphrase, stays in the system keystore.
  Future<List<int>?> loadKey() async {
    final value = await _secureStorage.read(key: _keyKey);
    return value == null ? null : base64Url.decode(value);
  }

  Future<void> saveKey(List<int> key) =>
      _secureStorage.write(key: _keyKey, value: base64UrlEncode(key));

  Future<List<SyncHistoryEntry>> loadHistory() async {
    final value =
        (await SharedPreferences.getInstance()).getString(_historyKey);
    if (value == null) return const [];
    try {
      return [
        for (final item in jsonDecode(value) as List<Object?>)
          SyncHistoryEntry.fromJson((item! as Map).cast<String, Object?>()),
      ];
    } catch (_) {
      await (await SharedPreferences.getInstance()).remove(_historyKey);
      return const [];
    }
  }

  Future<List<SyncHistoryEntry>> addHistory(SyncHistoryEntry entry) async {
    final entries = [entry, ...await loadHistory()];
    if (entries.length > _historyLimit) {
      entries.removeRange(_historyLimit, entries.length);
    }
    await (await SharedPreferences.getInstance()).setString(
      _historyKey,
      jsonEncode([for (final item in entries) item.toJson()]),
    );
    return entries;
  }

  Future<void> saveHistory(List<SyncHistoryEntry> entries) async {
    final values = entries.length > _historyLimit
        ? entries.take(_historyLimit).toList()
        : entries;
    await (await SharedPreferences.getInstance()).setString(
      _historyKey,
      jsonEncode([for (final item in values) item.toJson()]),
    );
  }

  /// Forgets sync on this device; the account's envelope is left untouched.
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_settingsKey);
    await preferences.remove(_historyKey);
    await _secureStorage.delete(key: _keyKey);
  }
}
