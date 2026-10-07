import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sync_crypto.dart';

enum SyncHistoryChangeKind {
  positionUploaded,
  positionDownloaded,
  favorites,
  plays,
  playlists,
  servers,
  noChanges,
}

class SyncHistoryChange {
  const SyncHistoryChange({
    required this.kind,
    this.label,
    this.positionMs,
    this.count = 1,
  });

  final SyncHistoryChangeKind kind;
  final String? label;
  final int? positionMs;
  final int count;

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        if (label != null) 'label': label,
        if (positionMs != null) 'positionMs': positionMs,
        if (count != 1) 'count': count,
      };

  factory SyncHistoryChange.fromJson(Map<String, Object?> json) =>
      SyncHistoryChange(
        kind: SyncHistoryChangeKind.values.byName(json['kind']! as String),
        label: json['label'] as String?,
        positionMs: json['positionMs'] as int?,
        count: json['count'] as int? ?? 1,
      );
}

class SyncHistoryEntry {
  const SyncHistoryEntry({required this.at, required this.changes});

  final DateTime at;
  final List<SyncHistoryChange> changes;

  Map<String, Object?> toJson() => {
        'at': at.toIso8601String(),
        'changes': [for (final change in changes) change.toJson()],
      };

  factory SyncHistoryEntry.fromJson(Map<String, Object?> json) =>
      SyncHistoryEntry(
        at: DateTime.parse(json['at']! as String),
        changes: [
          for (final item in json['changes'] as List<Object?>? ?? const [])
            SyncHistoryChange.fromJson(
              (item! as Map).cast<String, Object?>(),
            ),
        ],
      );
}

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

  /// Forgets sync on this device; the account's envelope is left untouched.
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_settingsKey);
    await preferences.remove(_historyKey);
    await _secureStorage.delete(key: _keyKey);
  }
}
