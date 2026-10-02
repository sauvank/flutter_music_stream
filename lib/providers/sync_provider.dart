import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../services/sync/sync_account.dart';
import '../services/sync/sync_crypto.dart';
import '../services/sync/sync_payload.dart';
import '../services/sync/sync_remote.dart';
import '../services/sync/sync_service.dart';
import 'library_provider.dart';

/// End-to-end encrypted sync of favorites, listening counts and playlists
/// through the user's account (Google or email). The backend only stores
/// cipher text; the passphrase never leaves the device. Manual only, so the
/// app never contacts the backend by surprise.
class SyncProvider extends ChangeNotifier {
  SyncProvider(
    this._service,
    this._remote,
    this._account,
    this._library, {
    SyncCrypto? crypto,
    int iterations = SyncKdf.defaultIterations,
  })  : _crypto = crypto ?? SyncCrypto(),
        _iterations = iterations;

  final SyncService _service;
  final SyncRemote _remote;
  final SyncAccount _account;
  final LibraryProvider _library;
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
      final merged = SyncPayload.merge(remotePayload, _library.syncSnapshot());
      final envelope = await _crypto.seal(merged.toJson(), key: key, kdf: kdf);
      try {
        await _remote.upload(uid, envelope, replacing: remote);
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
