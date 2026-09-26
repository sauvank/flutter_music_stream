import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/server_profile.dart';

class ServerProfileService {
  ServerProfileService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _profilesKey = 'server_profiles_v1';
  final FlutterSecureStorage _secureStorage;

  Future<List<ServerProfile>> load() async {
    final value =
        (await SharedPreferences.getInstance()).getString(_profilesKey);
    if (value == null || value.isEmpty) return [];
    try {
      return ServerProfile.decodeAll(value);
    } on FormatException {
      return [];
    }
  }

  Future<void> save(List<ServerProfile> profiles) async {
    await (await SharedPreferences.getInstance())
        .setString(_profilesKey, ServerProfile.encodeAll(profiles));
  }

  Future<void> writePassword(String profileId, String password) async {
    final key = 'server_password_$profileId';
    if (password.isEmpty) {
      await _secureStorage.delete(key: key);
    } else {
      await _secureStorage.write(key: key, value: password);
    }
  }

  Future<String> readPassword(String profileId) async =>
      await _secureStorage.read(key: 'server_password_$profileId') ?? '';

  Future<void> deletePassword(String profileId) =>
      _secureStorage.delete(key: 'server_password_$profileId');
}
