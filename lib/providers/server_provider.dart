import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/remote_audio_entry.dart';
import '../models/remote_audio_metadata.dart';
import '../models/server_profile.dart';
import '../services/remote_audio_metadata_service.dart';
import '../services/remote_server_service.dart';
import '../services/server_profile_service.dart';

class ServerProvider extends ChangeNotifier {
  ServerProvider(
    this._profilesService,
    this.remoteService, {
    RemoteAudioMetadataService? metadataService,
  }) : _metadataService = metadataService ?? RemoteAudioMetadataService();

  final ServerProfileService _profilesService;
  final RemoteServerService remoteService;
  final RemoteAudioMetadataService _metadataService;
  final List<ServerProfile> profiles = [];
  final List<RemoteAudioEntry> entries = [];
  final List<Uri> _history = [];
  ServerProfile? selected;
  Uri? currentUri;
  String _password = '';
  bool loading = false;
  String? error;

  bool get canGoBack => _history.isNotEmpty;
  String get password => _password;

  Future<RemoteAudioMetadata> metadataFor(RemoteAudioEntry entry) {
    final profile = selected;
    if (profile == null) throw StateError('Aucun serveur connecté.');
    return _metadataService.load(
      entry,
      headers: remoteService.authorizationHeaders(profile, _password),
    );
  }

  Future<void> load() async {
    profiles
      ..clear()
      ..addAll(await _profilesService.load());
    notifyListeners();
  }

  Future<void> addProfile(ServerProfile profile, String password) async {
    profiles.add(profile);
    await _profilesService.save(profiles);
    await _profilesService.writePassword(profile.id, password);
    notifyListeners();
  }

  Future<int> importProfilesFromJson(
    String jsonContent, {
    String password = '',
  }) async {
    final decoded = jsonDecode(jsonContent);
    final values = switch (decoded) {
      List<Object?> items => items,
      Map<String, Object?> map when map['servers'] is List<Object?> =>
        map['servers']! as List<Object?>,
      Map<String, Object?> map => <Object?>[map],
      _ => throw const FormatException('Format JSON invalide'),
    };
    var imported = 0;
    for (final value in values) {
      if (value is! Map) throw const FormatException('Profil JSON invalide');
      final map = value.cast<String, Object?>();
      final baseUrl = _importedBaseUrl(map);
      final typeName = map['type'] as String? ?? map['serverType'] as String?;
      final name = map['name'] as String?;
      if (baseUrl == null || typeName == null || name == null) {
        throw const FormatException('Champs de profil manquants');
      }
      final uri = Uri.tryParse(baseUrl);
      if (uri == null ||
          !{'http', 'https'}.contains(uri.scheme) ||
          uri.host.isEmpty) {
        throw const FormatException('Adresse de serveur invalide');
      }
      final type = switch (typeName) {
        'webdav' => ServerType.webdav,
        'http' || 'httpDirectory' => ServerType.http,
        _ => throw const FormatException('Type de serveur invalide'),
      };
      final username = map['username'] as String? ?? '';
      final importedPassword = map['password'] as String? ?? password;
      final duplicate = profiles.any((profile) =>
          profile.baseUrl == baseUrl &&
          profile.type == type &&
          profile.username == username);
      if (duplicate) continue;
      final profile = ServerProfile(
        id: map['id'] as String? ?? const Uuid().v4(),
        name: name,
        baseUrl: baseUrl,
        type: type,
        username: username,
      );
      profiles.add(profile);
      await _profilesService.writePassword(profile.id, importedPassword);
      imported++;
    }
    if (imported > 0) await _profilesService.save(profiles);
    notifyListeners();
    return imported;
  }

  String? _importedBaseUrl(Map<String, Object?> map) {
    final current = map['baseUrl'] as String?;
    if (current != null) return current;
    final rawHost = map['host'] as String?;
    if (rawHost == null || rawHost.trim().isEmpty) return null;
    final isHttps = map['isHttps'] as bool? ?? false;
    final scheme = isHttps ? 'https' : 'http';
    final host = rawHost
        .trim()
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'/+$'), '');
    final port = map['port'] as int? ?? (isHttps ? 443 : 80);
    final portPart =
        (isHttps && port == 443) || (!isHttps && port == 80) ? '' : ':$port';
    var path = map['path'] as String? ?? '/';
    if (!path.startsWith('/')) path = '/$path';
    if (!path.endsWith('/')) path = '$path/';
    return '$scheme://$host$portPart$path';
  }

  Future<void> deleteProfile(ServerProfile profile) async {
    profiles.removeWhere((item) => item.id == profile.id);
    if (selected?.id == profile.id) disconnect();
    await _profilesService.save(profiles);
    await _profilesService.deletePassword(profile.id);
    notifyListeners();
  }

  Future<void> connect(ServerProfile profile) async {
    selected = profile;
    _password = await _profilesService.readPassword(profile.id);
    _history.clear();
    await _open(_normalizedRoot(profile.baseUrl));
  }

  Future<void> openDirectory(RemoteAudioEntry entry) async {
    if (!entry.isDirectory || currentUri == null) return;
    _history.add(currentUri!);
    await _open(entry.uri);
  }

  Future<void> goBack() async {
    if (_history.isEmpty) return;
    await _open(_history.removeLast());
  }

  void disconnect() {
    selected = null;
    currentUri = null;
    _password = '';
    entries.clear();
    _history.clear();
    error = null;
    notifyListeners();
  }

  Future<void> _open(Uri uri) async {
    final profile = selected;
    if (profile == null) return;
    loading = true;
    error = null;
    currentUri = uri;
    notifyListeners();
    try {
      entries
        ..clear()
        ..addAll(await remoteService.list(profile, uri, _password));
    } catch (exception) {
      error = 'Connexion impossible. Vérifiez l’adresse et les identifiants.';
      debugPrint('Server listing failed: ${exception.runtimeType}');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Uri _normalizedRoot(String value) {
    final uri = Uri.parse(value.trim());
    return uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');
  }
}
