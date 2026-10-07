import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/remote_audio_entry.dart';
import '../models/remote_audio_metadata.dart';
import '../models/server_profile.dart';
import '../services/remote_audio_metadata_service.dart';
import '../services/remote_server_service.dart';
import '../services/server_profile_service.dart';
import '../services/server_scan_service.dart';
import '../services/sync/server_sync_journal.dart';
import '../services/sync/sync_payload.dart';
import '../models/music_track.dart';

class ServerProvider extends ChangeNotifier {
  ServerProvider(
    this._profilesService,
    this.remoteService, {
    RemoteAudioMetadataService? metadataService,
    ServerScanService? scanService,
    ServerSyncJournal? journal,
  })  : _metadataService = metadataService ?? RemoteAudioMetadataService(),
        _scanService = scanService ?? ServerScanService(),
        _journal = journal ?? ServerSyncJournal();

  final ServerProfileService _profilesService;
  final RemoteServerService remoteService;
  final RemoteAudioMetadataService _metadataService;
  final ServerScanService _scanService;
  final ServerSyncJournal _journal;
  final List<ServerProfile> profiles = [];
  final List<RemoteAudioEntry> entries = [];
  final List<Uri> _history = [];
  ServerProfile? selected;
  Uri? currentUri;
  String _password = '';
  bool loading = false;
  String? error;
  final Set<String> scanningProfileIds = {};
  final Map<Uri, Future<List<RemoteAudioEntry>>> _folderFiles = {};
  Future<void> _folderScanChain = Future.value();

  bool get canGoBack => _history.isNotEmpty;

  /// Folders from the server root to the current one.
  List<Uri> get breadcrumbs =>
      List.unmodifiable([..._history, if (currentUri != null) currentUri!]);

  /// Jumps back to an ancestor listed in [breadcrumbs].
  Future<void> goToLevel(int index) async {
    if (index < 0 || index >= _history.length) return;
    final target = _history[index];
    _history.removeRange(index, _history.length);
    await _open(target);
  }

  String get password => _password;

  Future<List<RemoteAudioEntry>> filesInFolder(Uri uri) {
    return _folderFiles.putIfAbsent(uri, () {
      final profile = selected!;
      final password = _password;
      final result = _folderScanChain
          .then((_) => remoteService.listRecursively(profile, uri, password));
      _folderScanChain = result.then<void>((_) {}, onError: (Object _) {});
      result.catchError((Object _) {
        _folderFiles.remove(uri);
        return <RemoteAudioEntry>[];
      });
      return result;
    });
  }

  Future<RemoteAudioMetadata> metadataFor(RemoteAudioEntry entry) {
    final profile = selected;
    if (profile == null) throw StateError('Aucun serveur connecté.');
    if (profile.type == ServerType.ftp) {
      return Future.value(RemoteAudioMetadata(
        title: _titleFromFilename(entry.name),
        artist: MusicTrack.unknownArtist,
      ));
    }
    return _metadataService.load(
      entry,
      headers: remoteService.authorizationHeaders(profile, _password),
    );
  }

  Future<void> load() async {
    profiles
      ..clear()
      ..addAll(await _profilesService.load());
    await _journal.load();
    notifyListeners();
  }

  String _keyOf(ServerProfile profile) =>
      serverSyncKey(profile.type, profile.baseUrl, profile.username);

  /// Servers and their passwords for sync, with when each was added here.
  /// Servers that predate sync get the current time the first time.
  Future<SyncPayload> syncSnapshot() async {
    final servers = <String, SyncServer>{};
    var journalChanged = false;
    for (final profile in profiles) {
      final key = _keyOf(profile);
      final addedAt = _journal.added.putIfAbsent(key, () {
        journalChanged = true;
        return _journal.nextTimestamp();
      });
      servers[key] = SyncServer(
        id: profile.id,
        name: profile.name,
        baseUrl: profile.baseUrl,
        type: profile.type,
        username: profile.username,
        password: await _profilesService.readPassword(profile.id),
        addedAt: addedAt,
      );
    }
    if (journalChanged) await _journal.save();
    return SyncPayload(
      servers: servers,
      deletedServers: Map.of(_journal.deleted),
    );
  }

  /// Adopts the merged server list: removes servers deleted elsewhere and
  /// adds the ones this device lacks. A server already here is kept, only
  /// receiving a password it was missing.
  Future<void> applySync(SyncPayload merged) async {
    var changed = false;
    final removed = profiles.where((profile) {
      final deletedAt = merged.deletedServers[_keyOf(profile)];
      final addedAt = _journal.added[_keyOf(profile)];
      return deletedAt != null &&
          (addedAt == null || !addedAt.isAfter(deletedAt));
    }).toList();
    for (final profile in removed) {
      profiles.removeWhere((item) => item.id == profile.id);
      if (selected?.id == profile.id) disconnect();
      await _profilesService.deletePassword(profile.id);
      await _scanService.forget(profile.id);
      _journal.added.remove(_keyOf(profile));
      changed = true;
    }
    for (final server in merged.servers.values) {
      _journal.observe(server.addedAt);
      final local = profiles
          .where((profile) => _keyOf(profile) == server.key)
          .firstOrNull;
      if (local == null) {
        profiles.add(server.profile);
        await _profilesService.writePassword(server.id, server.password);
        _journal.added[server.key] = server.addedAt;
        changed = true;
      } else if (server.password.isNotEmpty &&
          await _profilesService.readPassword(local.id) == '') {
        await _profilesService.writePassword(local.id, server.password);
      }
    }
    _journal.deleted
      ..clear()
      ..addAll(merged.deletedServers);
    for (final at in merged.deletedServers.values) {
      _journal.observe(at);
    }
    await _journal.save();
    if (changed) {
      await _profilesService.save(profiles);
      notifyListeners();
    }
  }

  Future<void> addProfile(ServerProfile profile, String password) async {
    profiles.add(profile);
    _journal.added[_keyOf(profile)] = _journal.nextTimestamp();
    await _journal.save();
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
      final typeName = map['type'] as String? ?? map['serverType'] as String?;
      final name = map['name'] as String?;
      if (typeName == null || name == null) {
        throw const FormatException('Champs de profil manquants');
      }
      final type = switch (typeName) {
        'webdav' => ServerType.webdav,
        'http' || 'httpDirectory' => ServerType.http,
        'ftp' => ServerType.ftp,
        _ => throw const FormatException('Type de serveur invalide'),
      };
      final baseUrl = _importedBaseUrl(map, type);
      if (baseUrl == null) {
        throw const FormatException('Champs de profil manquants');
      }
      final uri = Uri.tryParse(baseUrl);
      if (uri == null ||
          !(type == ServerType.ftp
              ? uri.scheme == 'ftp'
              : {'http', 'https'}.contains(uri.scheme)) ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty) {
        throw const FormatException('Adresse de serveur invalide');
      }
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
      _journal.added[_keyOf(profile)] = _journal.nextTimestamp();
      await _profilesService.writePassword(profile.id, importedPassword);
      imported++;
    }
    if (imported > 0) {
      await _journal.save();
      await _profilesService.save(profiles);
    }
    notifyListeners();
    return imported;
  }

  String? _importedBaseUrl(
    Map<String, Object?> map,
    ServerType type,
  ) {
    final current = map['baseUrl'] as String?;
    if (current != null) return current;
    final rawHost = map['host'] as String?;
    if (rawHost == null || rawHost.trim().isEmpty) return null;
    final isHttps = map['isHttps'] as bool? ?? false;
    final scheme = type == ServerType.ftp
        ? 'ftp'
        : isHttps
            ? 'https'
            : 'http';
    final host = rawHost
        .trim()
        .replaceFirst(RegExp(r'^(?:https?|ftp)://'), '')
        .replaceFirst(RegExp(r'/+$'), '');
    final defaultPort = type == ServerType.ftp
        ? 21
        : isHttps
            ? 443
            : 80;
    final port = map['port'] as int? ?? defaultPort;
    final portPart = port == defaultPort ? '' : ':$port';
    var path = map['path'] as String? ?? '/';
    if (!path.startsWith('/')) path = '/$path';
    if (!path.endsWith('/')) path = '$path/';
    return '$scheme://$host$portPart$path';
  }

  Future<String> passwordFor(ServerProfile profile) =>
      _profilesService.readPassword(profile.id);

  Future<void> deleteProfile(ServerProfile profile) async {
    profiles.removeWhere((item) => item.id == profile.id);
    if (selected?.id == profile.id) disconnect();
    _journal.added.remove(_keyOf(profile));
    _journal.deleted[_keyOf(profile)] = _journal.nextTimestamp();
    await _journal.save();
    await _profilesService.save(profiles);
    await _profilesService.deletePassword(profile.id);
    await _scanService.forget(profile.id);
    notifyListeners();
  }

  Future<ServerScanResult> scanForNewAlbums(ServerProfile profile) async {
    if (!scanningProfileIds.add(profile.id)) {
      throw StateError('Ce serveur est déjà en cours d’analyse.');
    }
    notifyListeners();
    try {
      final password = await _profilesService.readPassword(profile.id);
      final files = await remoteService.listRecursively(
        profile,
        _normalizedRoot(profile.baseUrl),
        password,
      );
      return _scanService.compareAndSave(profile.id, files);
    } finally {
      scanningProfileIds.remove(profile.id);
      notifyListeners();
    }
  }

  Future<void> connect(ServerProfile profile) async {
    _folderFiles.clear();
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
    _folderFiles.clear();
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

  /// Lists the profile's root without saving it. Returns null on success,
  /// otherwise the exception raised while connecting.
  Future<Object?> testConnection(ServerProfile profile, String password) async {
    try {
      await remoteService.list(
        profile,
        _normalizedRoot(profile.baseUrl),
        password,
      );
      return null;
    } catch (exception) {
      debugPrint('Server test failed: ${exception.runtimeType}');
      return exception;
    }
  }

  Uri _normalizedRoot(String value) {
    final uri = Uri.parse(value.trim());
    return uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');
  }

  String _titleFromFilename(String name) {
    final extension = name.lastIndexOf('.');
    var value = extension > 0 ? name.substring(0, extension) : name;
    value = value.replaceAll('_', ' ').trim();
    return value.replaceFirst(RegExp(r'^\d+\s*[-.]\s*'), '').trim();
  }
}
