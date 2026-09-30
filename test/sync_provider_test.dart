import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/models/music_track.dart';
import 'package:music_reader_app/models/server_profile.dart';
import 'package:music_reader_app/providers/library_provider.dart';
import 'package:music_reader_app/providers/server_provider.dart';
import 'package:music_reader_app/providers/sync_provider.dart';
import 'package:music_reader_app/services/library_service.dart';
import 'package:music_reader_app/services/playlist_service.dart';
import 'package:music_reader_app/services/remote_server_service.dart';
import 'package:music_reader_app/services/server_profile_service.dart';
import 'package:music_reader_app/services/sync/sync_crypto.dart';
import 'package:music_reader_app/services/sync/sync_journal.dart';
import 'package:music_reader_app/services/sync/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const profile = ServerProfile(
    id: 'nas',
    name: 'NAS',
    baseUrl: 'https://192.168.1.100/dav/music',
    type: ServerType.webdav,
    username: 'user',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('two devices converge on favorites and playlists', () async {
    final server = _MemoryServer();
    final a = await _Device.create(server);
    final b = await _Device.create(server);

    await a.library.toggleFavorite('shared');
    final playlist = await a.library.createPlaylist('Road trip');
    await a.library.addTrackToPlaylist(playlist!.id, 'shared');
    await a.sync.enable(profile, 'correct horse battery');
    expect(server.body, isNot(contains('Road trip')));

    await b.sync.enable(profile, 'correct horse battery');
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
  });

  test('a server refusing writes leaves sync disabled', () async {
    final device = await _Device.create(_MemoryServer(), readOnly: true);

    await expectLater(device.sync.enable(profile, 'correct horse battery'),
        throwsA(isA<SyncWriteForbiddenException>()));
    expect(device.sync.enabled, isFalse);
    expect(device.sync.busy, isFalse);
  });

  test('a wrong passphrase cannot join an existing sync file', () async {
    final server = _MemoryServer();
    final a = await _Device.create(server);
    await a.sync.enable(profile, 'correct horse battery');
    final b = await _Device.create(server);

    await expectLater(b.sync.enable(profile, 'wrong passphrase'),
        throwsA(isA<SyncPassphraseException>()));
    expect(b.sync.enabled, isFalse);
    expect(b.sync.busy, isFalse);
  });
}

class _ReadOnlySyncService extends _MemorySyncService {
  _ReadOnlySyncService(super.server);

  @override
  Future<void> upload(
    Uri uri,
    Map<String, String> headers,
    Map<String, Object?> envelope, {
    required RemoteSyncFile? replacing,
  }) async =>
      throw const SyncWriteForbiddenException(403);
}

class _Device {
  _Device(this.library, this.sync);
  final LibraryProvider library;
  final SyncProvider sync;

  static Future<_Device> create(
    _MemoryServer server, {
    bool readOnly = false,
  }) async {
    // Each device keeps its own preferences; the test switches between them.
    final library = LibraryProvider(
      _MemoryLibraryService(),
      _MemoryPlaylistService(),
      journal: _MemoryJournal(),
    );
    await library.load();
    final servers = ServerProvider(
      _MemoryProfiles(),
      RemoteServerService(),
    );
    await servers.load();
    final sync = SyncProvider(
      readOnly ? _ReadOnlySyncService(server) : _MemorySyncService(server),
      library,
      servers,
      iterations: 1000,
    );
    await sync.load();
    return _Device(library, sync);
  }
}

class _MemoryServer {
  String? body;
  int version = 0;
}

class _MemorySyncService extends SyncService {
  _MemorySyncService(this.server);
  final _MemoryServer server;
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

  @override
  Future<RemoteSyncFile?> download(Uri uri, Map<String, String> headers) async {
    final body = server.body;
    if (body == null) return null;
    return (
      envelope: (jsonDecode(body) as Map).cast<String, Object?>(),
      etag: '${server.version}',
    );
  }

  @override
  Future<void> upload(
    Uri uri,
    Map<String, String> headers,
    Map<String, Object?> envelope, {
    required RemoteSyncFile? replacing,
  }) async {
    if ((replacing?.etag ?? 'none') !=
        (server.body == null ? 'none' : '${server.version}')) {
      throw const SyncConflictException();
    }
    server
      ..body = jsonEncode(envelope)
      ..version += 1;
  }
}

class _MemoryLibraryService extends LibraryService {
  List<MusicTrack> saved = [
    MusicTrack(
      id: 'shared',
      title: 'Shared',
      uri: 'file:///media/music/shared.mp3',
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

class _MemoryProfiles extends ServerProfileService {
  @override
  Future<List<ServerProfile>> load() async => [
        const ServerProfile(
          id: 'nas',
          name: 'NAS',
          baseUrl: 'https://192.168.1.100/dav/music',
          type: ServerType.webdav,
          username: 'user',
        ),
      ];
  @override
  Future<String> readPassword(String profileId) async => 'secret';
}
