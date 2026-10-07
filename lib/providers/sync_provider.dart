import 'dart:async';
import 'dart:convert';
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
/// cipher text; the passphrase never leaves the device. Syncs when the sheet
/// asks, and for the current audiobook when the app is left or paused.
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
  List<SyncHistoryEntry> history = const [];
  bool busy = false;
  RemoteSyncFile? _preparedRemote;
  String? _preparedRemoteUid;
  bool _hasPreparedRemote = false;
  int _retryExponent = 0;

  /// False when this build has no sync backend configured.
  bool get available => _account.available;
  SyncUser? get user => _account.currentUser;

  /// Encryption is set up for the signed-in account on this device.
  bool get enabled => settings != null && settings!.uid == user?.uid;

  Future<void> load() async {
    settings = await _service.loadSettings();
    history = await _service.loadHistory();
    _accountChanges = _account.changes.listen((user) async {
      // Another account, or none: this device's key belongs to the old one.
      if (settings != null && settings!.uid != user?.uid) {
        await _service.clear();
        settings = null;
        history = const [];
        _preparedRemote = null;
        _hasPreparedRemote = false;
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

  /// Whether the signed-in account already owns an encrypted sync envelope.
  /// The setup UI uses this to confirm a newly created passphrase, while an
  /// existing account only asks for its passphrase once to unlock the data.
  Future<bool> accountHasSyncedData() async {
    final uid = _requireUser().uid;
    _preparedRemote = await _remote.download(uid);
    _preparedRemoteUid = uid;
    _hasPreparedRemote = true;
    return _preparedRemote != null;
  }

  Future<Map<String, Object?>?> pairingKeyPackage() async {
    if (!enabled) return null;
    final key = await _service.loadKey();
    if (key == null) return null;
    return {'key': base64UrlEncode(key), 'kdf': settings!.kdf.toJson()};
  }

  Future<void> acceptPairingKeyPackage(Map<String, Object?> value) async {
    final uid = _requireUser().uid;
    final key = base64Url.decode(value['key']! as String);
    final kdf =
        SyncKdf.fromJson((value['kdf']! as Map).cast<String, Object?>());
    final remote = await _remote.download(uid);
    if (remote == null) throw StateError('No sync envelope to unlock');
    await _crypto.open(remote.envelope, key: key);
    await _run(() async {
      await _service.saveKey(key);
      settings = SyncSettings(uid: uid, kdf: kdf);
      await _service.saveSettings(settings!);
      try {
        await _sync();
      } catch (_) {
        await _service.clear();
        settings = null;
        rethrow;
      }
    });
  }

  Future<void> signOut() => _run(() async {
        await _service.clear();
        settings = null;
        history = const [];
        await _account.signOut();
      });

  /// Joins the account's envelope, or creates it. With an existing one the
  /// passphrase must open it, so every device shares one key.
  Future<void> enable(String passphrase) => _run(() async {
        final uid = _requireUser().uid;
        final remote = _hasPreparedRemote && _preparedRemoteUid == uid
            ? _preparedRemote
            : await _remote.download(uid);
        _preparedRemote = null;
        _hasPreparedRemote = false;
        final kdf = remote == null
            ? SyncKdf(salt: SyncCrypto.newSalt(), iterations: _iterations)
            : SyncCrypto.kdfOf(remote.envelope);
        final key = await _deriveKey(passphrase, kdf);
        if (remote != null) await _crypto.open(remote.envelope, key: key);
        await _service.saveKey(key);
        settings = SyncSettings(uid: uid, kdf: kdf);
        await _service.saveSettings(settings!);
        try {
          await _sync(initialRemote: remote, useInitialRemote: true);
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
    // A background sync may be running just as the user opens the book. The
    // remote read is independent and must not make the resume prompt vanish.
    if (!enabled || !track.isAudiobook) return null;
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

  Timer? _autoTimer;
  String? _syncedSignature;
  bool _autoStarted = false;
  bool _autoSyncPending = false;

  /// Starts automatic sync: once now, then whenever favorites, playlists,
  /// servers or audiobook positions change, and when the app is left.
  void startAutoSync() {
    if (_autoStarted) return;
    _autoStarted = true;
    _library.addListener(_scheduleAuto);
    _servers?.addListener(_scheduleAuto);
    _scheduleAuto();
  }

  void _scheduleAuto() {
    if (!enabled) return;
    _autoTimer?.cancel();
    _autoTimer = Timer(const Duration(seconds: 3), () async {
      if (await _signature() != _syncedSignature) unawaited(autoSync());
    });
  }

  /// What sync would send, including encrypted server credentials, used to
  /// detect edits after each burst without touching the network while idle.
  Future<String> _signature() async {
    var payload = _library.syncSnapshot();
    if (_servers != null) {
      payload = SyncPayload.merge(payload, await _servers.syncSnapshot());
    }
    return jsonEncode(payload.toJson());
  }

  /// Quiet sync: leaving the app, pausing or a local change is the moment
  /// another device will want to continue from. Failures retry next time.
  Future<void> autoSync({Duration delay = Duration.zero}) async {
    if (!enabled) return;
    // Let the player persist its latest position first.
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (!enabled) return;
    // Never lose a pause/background publication merely because another sync
    // is finishing. _run starts this deferred pass once it becomes idle.
    if (busy) {
      _autoSyncPending = true;
      return;
    }
    try {
      await syncNow();
    } catch (_) {
      final seconds = (5 * (1 << _retryExponent.clamp(0, 6))).clamp(5, 300);
      _retryExponent = (_retryExponent + 1).clamp(0, 6);
      _autoTimer?.cancel();
      _autoTimer = Timer(Duration(seconds: seconds), () {
        unawaited(autoSync());
      });
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
    history = const [];
    notifyListeners();
  }

  SyncUser _requireUser() {
    final user = this.user;
    if (user == null) throw StateError('No sync account signed in');
    return user;
  }

  Future<void> _sync({
    RemoteSyncFile? initialRemote,
    bool useInitialRemote = false,
  }) async {
    final current = settings;
    final key = await _service.loadKey();
    final uid = _requireUser().uid;
    if (current == null || key == null || current.uid != uid) {
      throw StateError('Sync is not configured');
    }
    // Retries cover devices uploading between our download and upload.
    for (var attempt = 0;; attempt++) {
      final remote = attempt == 0 && useInitialRemote
          ? initialRemote
          : await _remote.download(uid);
      var kdf = current.kdf;
      var remotePayload = const SyncPayload();
      if (remote != null) {
        kdf = SyncCrypto.kdfOf(remote.envelope);
        remotePayload = SyncPayload.fromJson(
          await _crypto.open(remote.envelope, key: key),
        );
      }
      var localPayload = _library.syncSnapshot();
      final servers = _servers;
      if (servers != null) {
        localPayload =
            SyncPayload.merge(localPayload, await servers.syncSnapshot());
      }
      final changes = _describeChanges(remotePayload, localPayload);
      var merged = SyncPayload.merge(remotePayload, localPayload);
      if (remotePayload.history.isEmpty) {
        merged = merged.withHistory(
          SyncPayload.merge(
            SyncPayload(history: await _service.loadHistory()),
            merged,
          ).history,
        );
      }
      if (changes.isNotEmpty) {
        final at = DateTime.now().toUtc();
        final deviceId = _library.syncDeviceId;
        final label = switch (defaultTargetPlatform) {
          TargetPlatform.windows => 'PC Windows',
          TargetPlatform.linux => 'PC Linux',
          TargetPlatform.macOS => 'Mac',
          TargetPlatform.android => 'Android',
          TargetPlatform.iOS => 'iPhone/iPad',
          TargetPlatform.fuchsia => 'Appareil',
        };
        merged = merged.withHistory([
          SyncHistoryEntry(
            id: '$deviceId-${at.microsecondsSinceEpoch}',
            device: label,
            at: at,
            changes: changes,
          ),
          ...merged.history,
        ]);
      }
      final remoteCanonical = jsonEncode(remotePayload.toJson());
      final mergedCanonical = jsonEncode(merged.toJson());
      final envelope = await _crypto.seal(merged.toJson(), key: key, kdf: kdf);
      if (remote == null || remoteCanonical != mergedCanonical) {
        try {
          await _remote.upload(uid, envelope, replacing: remote);
        } on SyncConflictException {
          if (attempt < 2) continue;
          rethrow;
        }
      }
      await _library.applySync(merged);
      await _servers?.applySync(merged);
      settings = current.copyWith(
        kdf: kdf,
        lastSyncAt: DateTime.now().toUtc(),
      );
      await _service.saveSettings(settings!);
      history = merged.history;
      await _service.saveHistory(history);
      _retryExponent = 0;
      _syncedSignature = await _signature();
      return;
    }
  }

  List<SyncHistoryChange> _describeChanges(
    SyncPayload remote,
    SyncPayload local,
  ) {
    final changes = <SyncHistoryChange>[];
    var favorites = 0;
    var plays = 0;
    for (final id in {...remote.tracks.keys, ...local.tracks.keys}) {
      final remoteTrack = remote.tracks[id] ?? const SyncTrackState();
      final localTrack = local.tracks[id] ?? const SyncTrackState();
      if (remoteTrack.favorite != localTrack.favorite ||
          remoteTrack.favoriteAt != localTrack.favoriteAt) {
        favorites++;
      }
      if (remoteTrack.playCount != localTrack.playCount ||
          remoteTrack.lastPlayedAt != localTrack.lastPlayedAt) {
        plays++;
      }
      final remoteAt = remoteTrack.positionAt;
      final localAt = localTrack.positionAt;
      if (remoteAt == localAt) continue;
      final localIsNewer =
          localAt != null && (remoteAt == null || localAt.isAfter(remoteAt));
      final source = localIsNewer ? localTrack : remoteTrack;
      if (source.positionMs == null) continue;
      changes.add(SyncHistoryChange(
        kind: localIsNewer
            ? SyncHistoryChangeKind.positionUploaded
            : SyncHistoryChangeKind.positionDownloaded,
        label: _library.trackById(id)?.title ?? id,
        positionMs: source.positionMs,
      ));
    }
    if (favorites > 0) {
      changes.add(SyncHistoryChange(
        kind: SyncHistoryChangeKind.favorites,
        count: favorites,
      ));
    }
    if (plays > 0) {
      changes.add(SyncHistoryChange(
        kind: SyncHistoryChangeKind.plays,
        count: plays,
      ));
    }
    if (jsonEncode([for (final item in remote.playlists) item.toJson()]) !=
            jsonEncode([for (final item in local.playlists) item.toJson()]) ||
        jsonEncode(_encodedDates(remote.deletedPlaylists)) !=
            jsonEncode(_encodedDates(local.deletedPlaylists))) {
      changes.add(const SyncHistoryChange(
        kind: SyncHistoryChangeKind.playlists,
      ));
    }
    if (jsonEncode([
              for (final item in remote.servers.values) item.toJson(),
            ]) !=
            jsonEncode([
              for (final item in local.servers.values) item.toJson(),
            ]) ||
        jsonEncode(_encodedDates(remote.deletedServers)) !=
            jsonEncode(_encodedDates(local.deletedServers))) {
      changes.add(const SyncHistoryChange(
        kind: SyncHistoryChangeKind.servers,
      ));
    }
    return changes;
  }

  static Map<String, String> _encodedDates(Map<String, DateTime> values) => {
        for (final entry in values.entries)
          entry.key: entry.value.toIso8601String(),
      };

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
      if (_autoSyncPending) {
        _autoSyncPending = false;
        unawaited(autoSync());
      }
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _library.removeListener(_scheduleAuto);
    _servers?.removeListener(_scheduleAuto);
    _accountChanges?.cancel();
    super.dispose();
  }
}
