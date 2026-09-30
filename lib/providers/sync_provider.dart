import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../models/server_profile.dart';
import '../services/sync/sync_crypto.dart';
import '../services/sync/sync_payload.dart';
import '../services/sync/sync_service.dart';
import 'library_provider.dart';
import 'server_provider.dart';

/// End-to-end encrypted sync of favorites, listening counts and playlists
/// through a file on one of the user's WebDAV servers. Manual only, so the
/// app never contacts a server by surprise.
class SyncProvider extends ChangeNotifier {
  SyncProvider(
    this._service,
    this._library,
    this._servers, {
    SyncCrypto? crypto,
    int iterations = SyncKdf.defaultIterations,
  })  : _crypto = crypto ?? SyncCrypto(),
        _iterations = iterations;

  final SyncService _service;
  final LibraryProvider _library;
  final ServerProvider _servers;
  final SyncCrypto _crypto;
  final int _iterations;

  SyncSettings? settings;
  bool busy = false;

  bool get enabled => settings != null;

  ServerProfile? get profile {
    final id = settings?.profileId;
    return _servers.profiles.where((profile) => profile.id == id).firstOrNull;
  }

  /// Profiles that can store the file: WebDAV accepts uploads.
  List<ServerProfile> get eligibleProfiles => _servers.profiles
      .where((profile) => profile.type == ServerType.webdav)
      .toList();

  Future<void> load() async {
    settings = await _service.loadSettings();
    notifyListeners();
  }

  /// Joins the sync file on [profile], or creates it. With an existing file
  /// the passphrase must open it, so every device shares one key.
  Future<void> enable(ServerProfile profile, String passphrase) =>
      _run(() async {
        final headers = await _headers(profile);
        final uri = SyncService.fileUri(profile);
        final remote = await _service.download(uri, headers);
        final kdf = remote == null
            ? SyncKdf(salt: SyncCrypto.newSalt(), iterations: _iterations)
            : SyncCrypto.kdfOf(remote.envelope);
        final key = await _deriveKey(passphrase, kdf);
        if (remote != null) await _crypto.open(remote.envelope, key: key);
        await _service.saveKey(key);
        settings = SyncSettings(profileId: profile.id, kdf: kdf);
        await _service.saveSettings(settings!);
        try {
          await _sync();
        } catch (_) {
          // Stays off until one sync succeeds, instead of looking active.
          await _service.clear();
          settings = null;
          rethrow;
        }
      });

  Future<void> syncNow() => _run(_sync);

  Future<void> disable() async {
    await _service.clear();
    settings = null;
    notifyListeners();
  }

  Future<void> _sync() async {
    final current = settings;
    final profile = this.profile;
    final key = await _service.loadKey();
    if (current == null || profile == null || key == null) {
      throw StateError('Sync is not configured');
    }
    final headers = await _headers(profile);
    final uri = SyncService.fileUri(profile);
    // One retry covers a device uploading between our download and upload.
    for (var attempt = 0;; attempt++) {
      final remote = await _service.download(uri, headers);
      var kdf = current.kdf;
      var remotePayload = const SyncPayload();
      if (remote != null) {
        kdf = SyncCrypto.kdfOf(remote.envelope);
        remotePayload = SyncPayload.fromJson(
          await _crypto.open(remote.envelope, key: key),
        );
      }
      final merged = SyncPayload.merge(remotePayload, _library.syncSnapshot());
      final envelope = await _crypto.seal(merged.toJson(), key: key, kdf: kdf);
      try {
        await _service.upload(uri, headers, envelope, replacing: remote);
      } on SyncConflictException {
        if (attempt == 0) continue;
        rethrow;
      }
      await _library.applySync(merged);
      settings = current.copyWith(
        kdf: kdf,
        lastSyncAt: DateTime.now().toUtc(),
      );
      await _service.saveSettings(settings!);
      return;
    }
  }

  Future<Map<String, String>> _headers(ServerProfile profile) async =>
      _servers.remoteService.authorizationHeaders(
        profile,
        await _servers.passwordFor(profile),
      );

  /// PBKDF2 takes seconds on a phone: keep it off the UI isolate.
  Future<List<int>> _deriveKey(String passphrase, SyncKdf kdf) {
    final salt = kdf.salt;
    final iterations = kdf.iterations;
    return Isolate.run(() => SyncCrypto()
        .deriveKey(passphrase, SyncKdf(salt: salt, iterations: iterations)));
  }

  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    busy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
