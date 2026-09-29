import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/server_profile.dart';
import 'sync_crypto.dart';

class SyncSettings {
  const SyncSettings({
    required this.profileId,
    required this.kdf,
    this.lastSyncAt,
  });

  final String profileId;
  final SyncKdf kdf;
  final DateTime? lastSyncAt;

  SyncSettings copyWith({DateTime? lastSyncAt, SyncKdf? kdf}) => SyncSettings(
        profileId: profileId,
        kdf: kdf ?? this.kdf,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      );

  Map<String, Object?> toJson() => {
        'profileId': profileId,
        'kdf': kdf.toJson(),
        if (lastSyncAt != null) 'lastSyncAt': lastSyncAt!.toIso8601String(),
      };

  factory SyncSettings.fromJson(Map<String, Object?> json) => SyncSettings(
        profileId: json['profileId']! as String,
        kdf: SyncKdf.fromJson((json['kdf']! as Map).cast<String, Object?>()),
        lastSyncAt: DateTime.tryParse(json['lastSyncAt'] as String? ?? ''),
      );
}

/// The shared file, with the ETag needed to replace it safely.
typedef RemoteSyncFile = ({Map<String, Object?> envelope, String? etag});

/// Another device replaced the file between download and upload.
class SyncConflictException implements Exception {
  const SyncConflictException();
}

/// Stores sync settings and the derived key on this device, and moves the
/// encrypted file to and from the user's WebDAV server.
class SyncService {
  SyncService({Dio? dio, FlutterSecureStorage? secureStorage})
      : _dio = dio ?? Dio(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const fileName = 'musicstream-sync.json';
  static const _settingsKey = 'sync_settings_v1';
  static const _keyKey = 'sync_key_v1';

  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  Future<SyncSettings?> loadSettings() async {
    final value = (await SharedPreferences.getInstance()).getString(
      _settingsKey,
    );
    if (value == null) return null;
    try {
      return SyncSettings.fromJson(
          (jsonDecode(value) as Map).cast<String, Object?>());
    } on FormatException {
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

  /// Forgets sync on this device; the server file is left untouched.
  Future<void> clear() async {
    await (await SharedPreferences.getInstance()).remove(_settingsKey);
    await _secureStorage.delete(key: _keyKey);
  }

  static Uri fileUri(ServerProfile profile) {
    final base =
        profile.baseUrl.endsWith('/') ? profile.baseUrl : '${profile.baseUrl}/';
    return Uri.parse(base).resolve(fileName);
  }

  Future<RemoteSyncFile?> download(
    Uri uri,
    Map<String, String> headers,
  ) async {
    try {
      final response = await _dio.getUri<String>(
        uri,
        options: Options(headers: headers, responseType: ResponseType.plain),
      );
      final body = response.data;
      if (body == null || body.trim().isEmpty) return null;
      return (
        envelope: (jsonDecode(body) as Map).cast<String, Object?>(),
        etag: response.headers.value('etag'),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Uploads only if the file is still the one downloaded: `If-Match` its
  /// ETag, or `If-None-Match: *` when there was none. Servers without ETag
  /// support simply ignore the condition.
  Future<void> upload(
    Uri uri,
    Map<String, String> headers,
    Map<String, Object?> envelope, {
    required RemoteSyncFile? replacing,
  }) async {
    final condition = switch (replacing) {
      null => {'If-None-Match': '*'},
      (etag: final String etag, envelope: _) => {'If-Match': etag},
      _ => const <String, String>{},
    };
    try {
      await _dio.putUri<void>(
        uri,
        data: jsonEncode(envelope),
        options: Options(
          headers: {...headers, ...condition},
          contentType: 'application/json',
        ),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 412) {
        throw const SyncConflictException();
      }
      rethrow;
    }
  }
}
