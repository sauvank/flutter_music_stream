import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/models/music_track.dart';
import 'package:music_reader_app/providers/library_provider.dart';
import 'package:music_reader_app/providers/sync_provider.dart';
import 'package:music_reader_app/services/library_service.dart';
import 'package:music_reader_app/services/playlist_service.dart';
import 'package:music_reader_app/services/sync/sync_account.dart';
import 'package:music_reader_app/services/sync/sync_crypto.dart';
import 'package:music_reader_app/services/sync/sync_journal.dart';
import 'package:music_reader_app/services/sync/sync_remote.dart';
import 'package:music_reader_app/services/sync/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('two devices of one account converge on favorites and playlists',
      () async {
    final server = _MemoryRemote();
    final a = await _Device.create(server);
    final b = await _Device.create(server);

    await a.library.toggleFavorite('shared');
    final playlist = await a.library.createPlaylist('Road trip');
    await a.library.addTrackToPlaylist(playlist!.id, 'shared');
    await a.sync.enable('correct horse battery');
    expect(server.body, isNot(contains('Road trip')));

    await b.sync.enable('correct horse battery');
    expect(b.library.allTracks.single.favorite, isTrue);
    expect(b.library.playlists.single.name, 'Road trip');

    // B changes its mind later; A adopts it on its next sync.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await b.library.toggleFavorite('shared');
    await b.library.deletePlaylist(playlist.id);
    await b.sync.syncNow();
    await a.sync.syncNow();

    expect(a.library.allTracks.single.favorite, isFalse);
    expect(a.library.playlists, isEmpty);
    expect(a.sync.settings?.lastSyncAt, isNotNull);

    // A later no-op sync still summarizes persisted deletion timestamps;
    // DateTime values must be converted before JSON comparison.
    await a.sync.syncNow();
    expect(a.sync.history, isNotEmpty);
  });

  test('PC audiobook pause reaches phone despite overlapping syncs', () async {
    final server = _MemoryRemote();
    final pc = await _Device.create(server);
    final phone = await _Device.create(server);
    await pc.sync.enable('correct horse battery');
    await phone.sync.enable('correct horse battery');

    // The PC starts a sync with its old bookmark. While its upload is still
    // running, the player saves a new position and requests the pause sync.
    server.blockNextUpload();
    final firstPcSync = pc.sync.syncNow();
    await server.uploadEntered!.future;
    await pc.library.savePosition('shared', const Duration(minutes: 2));
    await pc.sync.autoSync();
    server.releaseUpload();
    await firstPcSync;
    await server.waitForRevision(4);
    while (pc.sync.busy) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    final sentPosition = pc.sync.history.first.changes.firstWhere(
      (change) => change.kind == SyncHistoryChangeKind.positionUploaded,
    );
    expect(pc.sync.history.first.changes, hasLength(1));
    expect(sentPosition.label, 'Shared');
    expect(sentPosition.positionMs, const Duration(minutes: 2).inMilliseconds);

    // Opening the book on the phone must still inspect the PC bookmark when
    // the phone happens to be synchronizing at the same time.
    server.blockNextUpload();
    final phoneSync = phone.sync.syncNow();
    await server.uploadEntered!.future;
    final proposal = await phone.sync.positionProposal(
      phone.library.allTracks.single,
    );
    expect(proposal?.remoteMs, const Duration(minutes: 2).inMilliseconds);
    expect(proposal?.localMs, 0);
    server.releaseUpload();
    await phoneSync;
  });

  test('a wrong passphrase cannot join an existing account', () async {
    final server = _MemoryRemote();
    final a = await _Device.create(server);
    await a.sync.enable('correct horse battery');
    final b = await _Device.create(server);

    await expectLater(b.sync.enable('wrong passphrase'),
        throwsA(isA<SyncPassphraseException>()));
    expect(b.sync.enabled, isFalse);
    expect(b.sync.busy, isFalse);
  });

  test('a failed first sync leaves sync disabled', () async {
    final device = await _Device.create(_MemoryRemote()..failUploads = true);

    await expectLater(
        device.sync.enable('correct horse battery'), throwsStateError);
    expect(device.sync.enabled, isFalse);
    expect(device.sync.busy, isFalse);
  });

  test('signing out or switching account forgets the key', () async {
    final device = await _Device.create(_MemoryRemote());
    await device.sync.enable('correct horse battery');
    expect(device.sync.enabled, isTrue);

    device.account.switchTo(const SyncUser(uid: 'someone-else'));
    await Future<void>.delayed(Duration.zero);
    expect(device.sync.enabled, isFalse);
    expect(await device.service.loadKey(), isNull);

    device.account.switchTo(const SyncUser(uid: 'me'));
    await device.sync.enable('correct horse battery');
    await device.sync.signOut();
    expect(device.sync.user, isNull);
    expect(device.sync.settings, isNull);
  });

  test('legacy WebDAV settings are dropped', () async {
    SharedPreferences.setMockInitialValues({
      'sync_settings_v1': jsonEncode({
        'profileId': 'nas',
        'kdf': SyncKdf(salt: List.filled(16, 1)).toJson(),
      }),
    });
    expect(await SyncService().loadSettings(), isNull);
  });
}

class _Device {
  _Device(this.library, this.sync, this.account, this.service);
  final LibraryProvider library;
  final SyncProvider sync;
  final _FakeAccount account;
  final _MemorySyncService service;

  static Future<_Device> create(_MemoryRemote remote) async {
    // Each device keeps its own preferences; the test switches between them.
    final library = LibraryProvider(
      _MemoryLibraryService(),
      _MemoryPlaylistService(),
      journal: _MemoryJournal(),
    );
    await library.load();
    final account = _FakeAccount();
    final service = _MemorySyncService();
    final sync = SyncProvider(
      service,
      remote,
      account,
      library,
      iterations: 1000,
    );
    await sync.load();
    return _Device(library, sync, account, service);
  }
}

class _FakeAccount implements SyncAccount {
  final _changes = StreamController<SyncUser?>.broadcast();
  SyncUser? _user = const SyncUser(uid: 'me', email: 'me@example.com');

  void switchTo(SyncUser? user) {
    _user = user;
    _changes.add(user);
  }

  @override
  bool get available => true;
  @override
  SyncUser? get currentUser => _user;
  @override
  Stream<SyncUser?> get changes => _changes.stream;
  @override
  Future<void> signInWithGoogle() async => switchTo(const SyncUser(uid: 'me'));
  @override
  Future<void> signInWithEmail(String email, String password) async =>
      switchTo(SyncUser(uid: 'me', email: email));
  @override
  Future<void> createAccount(String email, String password) =>
      signInWithEmail(email, password);
  @override
  Future<void> sendPasswordReset(String email) async {}
  @override
  Future<void> signOut() async => switchTo(null);
}

/// Behaves like the Firestore document: one envelope per account, replaced
/// only when the revision still matches.
class _MemoryRemote implements SyncRemote {
  String? body;
  int revision = 0;
  bool failUploads = false;
  Completer<void>? uploadEntered;
  Completer<void>? _uploadRelease;

  void blockNextUpload() {
    uploadEntered = Completer<void>();
    _uploadRelease = Completer<void>();
  }

  void releaseUpload() {
    _uploadRelease?.complete();
    _uploadRelease = null;
  }

  Future<void> waitForRevision(int expected) async {
    for (var attempt = 0; attempt < 100; attempt++) {
      if (revision >= expected) return;
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    throw StateError('Revision $expected was not reached (current: $revision)');
  }

  @override
  Future<RemoteSyncFile?> download(String uid) async {
    final body = this.body;
    if (body == null) return null;
    return (
      envelope: (jsonDecode(body) as Map).cast<String, Object?>(),
      revision: revision,
    );
  }

  @override
  Future<void> upload(
    String uid,
    Map<String, Object?> envelope, {
    required RemoteSyncFile? replacing,
  }) async {
    if (failUploads) throw StateError('offline');
    final release = _uploadRelease;
    if (release != null) {
      uploadEntered?.complete();
      await release.future;
    }
    if ((replacing?.revision ?? -1) != (body == null ? -1 : revision)) {
      throw const SyncConflictException();
    }
    body = jsonEncode(envelope);
    revision++;
  }
}

class _MemorySyncService extends SyncService {
  SyncSettings? settings;
  List<int>? key;

  @override
  Future<SyncSettings?> loadSettings() async => settings;
  @override
  Future<void> saveSettings(SyncSettings value) async => settings = value;
  @override
  Future<List<int>?> loadKey() async => key;
  @override
  Future<void> saveKey(List<int> value) async => key = value;
  @override
  Future<void> clear() async {
    settings = null;
    key = null;
  }
}

class _MemoryLibraryService extends LibraryService {
  List<MusicTrack> saved = [
    MusicTrack(
      id: 'shared',
      title: 'Shared',
      uri: 'file:///media/music/shared.m4b',
      addedAt: DateTime.utc(2026),
      metadataRead: true,
      source: MusicSource.localImport,
    ),
  ];

  @override
  Future<List<MusicTrack>> load() async => List.of(saved);
  @override
  Future<void> save(List<MusicTrack> tracks) async => saved = List.of(tracks);
  @override
  Future<bool> loadDeviceMediaEnabled() async => false;
}

class _MemoryPlaylistService extends PlaylistService {
  @override
  Future<void> save(playlists) async {}
}

class _MemoryJournal extends SyncJournal {
  @override
  Future<void> load() async {}
  @override
  Future<void> save() async {}
}
