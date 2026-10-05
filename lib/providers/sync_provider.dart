import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../models/music_track.dart';
import '../services/sync/sync_account.dart';
import '../services/sync/sync_crypto.dart';
import '../services/sync/sync_payload.dart';
import '../services/sync/sync_remote.dart';
import '../services/sync/sync_service.dart';
import 'library_provider.dart';
import 'server_provider.dart';

/// An audiobook position saved more recently on another device.
class PositionProposal {
  const PositionProposal({
    required this.remoteMs,
    required this.remoteAt,
    required this.localMs,
    this.localAt,
  });

  final int remoteMs;
  final DateTime remoteAt;
  final int localMs;
  final DateTime? localAt;
}

/// End-to-end encrypted sync of favorites, listening counts, playlists and
/// servers (with their passwords)
/// through the user's account (Google or email). The backend only stores
/// cipher text; the passphrase never leaves the device. Manual only, so the
/// app never contacts the backend by surprise.
class SyncProvider extends ChangeNotifier {
  SyncProvider(
    this._service,
    this._remote,
    this._account,
    this._library, {
    ServerProvider? servers,
    SyncCrypto? crypto,
    int iterations = SyncKdf.defaultIterations,
  })  : _servers = servers,
        _crypto = crypto ?? SyncCrypto(),
        _iterations = iterations;

  final SyncService _service;
  final SyncRemote _remote;
  final SyncAccount _account;
  final LibraryProvider _library;
  final ServerProvider? _servers;
  final SyncCrypto _crypto;
  final int _iterations;
  StreamSubscription<SyncUser?>? _accountChanges;

  SyncSettings? settings;
  bool busy = false;

  /// False when this build has no sync backend configured.
  bool get available => _account.available;
  SyncUser? get user => _account.currentUser;

  /// Encryption is set up for the signed-in account on this device.
  bool get enabled => settings != null && settings!.uid == user?.uid;

  Future<void> load() async {
    settings = await _service.loadSettings();
    _accountChanges = _account.changes.listen((user) async {
      // Another account, or none: this device's key belongs to the old one.
      if (settings != null && settings!.uid != user?.uid) {
        await _service.clear();
        settings = null;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> signInWithGoogle() => _run(_account.signInWithGoogle);

  Future<void> signInWithEmail(String email, String password) =>
      _run(() => _account.signInWithEmail(email, password));

  Future<void> createAccount(String email, String password) =>
      _run(() => _account.createAccount(email, password));

  Future<void> sendPasswordReset(String email) =>
      _account.sendPasswordReset(email);

  Future<void> signOut() => _run(() async {
        await _service.clear();
        settings = null;
        await _account.signOut();
      });

  /// Joins the account's envelope, or creates it. With an existing one the
  /// passphrase must open it, so every device shares one key.
  Future<void> enable(String passphrase) => _run(() async {
        final uid = _requireUser().uid;
        final remote = await _remote.download(uid);
        final kdf = remote == null
            ? SyncKdf(salt: SyncCrypto.newSalt(), iterations: _iterations)
            : SyncCrypto.kdfOf(remote.envelope);
        final key = await _deriveKey(passphrase, kdf);
        if (remote != null) await _crypto.open(remote.envelope, key: key);
        await _service.saveKey(key);
        settings = SyncSettings(uid: uid, kdf: kdf);
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

  /// Compares an audiobook's local resume point with the synced one when it
  /// is opened. Returns null when sync is off, offline, or nothing newer and
  /// meaningfully different exists, so playback is never blocked.
  Future<PositionProposal?> positionProposal(MusicTrack track) async {
    if (!enabled || !track.isAudiobook || busy) return null;
    try {
      final key = await _service.loadKey();
      if (key == null) return null;
      final remote = await _remote
          .download(_requireUser().uid)
          .timeout(const Duration(seconds: 5));
      if (remote == null) return null;
      final payload = SyncPayload.fromJson(
        await _crypto.open(remote.envelope, key: key),
      );
      final state = payload.tracks[track.id];
      final remoteAt = state?.positionAt;
      final remoteMs = state?.positionMs;
      if (remoteAt == null || remoteMs == null) return null;
      final localAt = _library.positionTime(track.id);
      if (localAt != null && !remoteAt.isAfter(localAt)) return null;
      if ((remoteMs - track.lastPositionMs).abs() < 15000) return null;
      return PositionProposal(
        remoteMs: remoteMs,
        remoteAt: remoteAt,
        localMs: track.lastPositionMs,
        localAt: localAt,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> adoptRemotePosition(String id, PositionProposal proposal) =>
      _library.adoptSyncedPosition(id, proposal.remoteMs, proposal.remoteAt);

  /// Makes this device's position the newest one and publishes it.
  Future<void> keepLocalPosition(String id) async {
    await _library.touchPosition(id);
    try {
      await syncNow();
    } catch (_) {
      // Stays local; the next manual sync publishes it.
    }
  }

  /// Forgets the key on this device and keeps the account signed in.
  Future<void> disable() async {
    await _service.clear();
    settings = null;
    notifyListeners();
  }

  SyncUser _requireUser() {
    final user = this.user;
    if (user == null) throw StateError('No sync account signed in');
    return user;
  }

  Future<void> _sync() async {
    final current = settings;
    final key = await _service.loadKey();
    final uid = _requireUser().uid;
    if (current == null || key == null || current.uid != uid) {
      throw StateError('Sync is not configured');
    }
    // One retry covers a device uploading between our download and upload.
    for (var attempt = 0;; attempt++) {
      final remote = await _remote.download(uid);
      var kdf = current.kdf;
      var remotePayload = const SyncPayload();
      if (remote != null) {
        kdf = SyncCrypto.kdfOf(remote.envelope);
        remotePayload = SyncPayload.fromJson(
          await _crypto.open(remote.envelope, key: key),
        );
      }
      var merged = SyncPayload.merge(remotePayload, _library.syncSnapshot());
      final servers = _servers;
      if (servers != null) {
        merged = SyncPayload.merge(merged, await servers.syncSnapshot());
      }
      final envelope = await _crypto.seal(merged.toJson(), key: key, kdf: kdf);
      try {
        await _remote.upload(uid, envelope, replacing: remote);
      } on SyncConflictException {
        if (attempt == 0) continue;
        rethrow;
      }
      await _library.applySync(merged);
      await _servers?.applySync(merged);
      settings = current.copyWith(
        kdf: kdf,
        lastSyncAt: DateTime.now().toUtc(),
      );
      await _service.saveSettings(settings!);
      return;
    }
  }

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

  @override
  void dispose() {
    _accountChanges?.cancel();
    super.dispose();
  }
}
