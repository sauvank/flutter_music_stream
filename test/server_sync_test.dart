import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/models/server_profile.dart';
import 'package:music_reader_app/providers/server_provider.dart';
import 'package:music_reader_app/services/remote_server_service.dart';
import 'package:music_reader_app/services/server_profile_service.dart';
import 'package:music_reader_app/services/sync/sync_payload.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ServerProfile profile(String id, {String url = 'https://music.test/dav/'}) =>
      ServerProfile(
        id: id,
        name: 'Maison',
        baseUrl: url,
        type: ServerType.webdav,
        username: 'user',
      );

  test('payload keeps one entry per address and survives a JSON round trip',
      () {
    final early = DateTime.utc(2026, 1, 1);
    final late = DateTime.utc(2026, 2, 1);
    SyncServer server(String id, DateTime at, String password) => SyncServer(
          id: id,
          name: 'Maison',
          baseUrl: 'https://MUSIC.test/dav/',
          type: ServerType.webdav,
          username: 'user',
          password: password,
          addedAt: at,
        );
    final a = SyncPayload(servers: {
      server('a', early, 'secret').key: server('a', early, 'secret'),
    });
    final b = SyncPayload(servers: {
      server('b', late, '').key: server('b', late, ''),
    });

    final merged = SyncPayload.merge(a, b);
    final restored = SyncPayload.fromJson(merged.toJson());

    expect(restored.servers, hasLength(1));
    // The later copy wins but never loses a password the other one had.
    expect(restored.servers.values.single.id, 'b');
    expect(restored.servers.values.single.password, 'secret');
  });

  test('a deletion beats an older copy but not a later re-add', () {
    final added = DateTime.utc(2026, 1, 1);
    final deleted = DateTime.utc(2026, 1, 5);
    final server = SyncServer(
      id: 'a',
      name: 'Maison',
      baseUrl: 'https://music.test/dav/',
      type: ServerType.webdav,
      addedAt: added,
    );
    final withServer = SyncPayload(servers: {server.key: server});
    final withDeletion = SyncPayload(deletedServers: {server.key: deleted});

    expect(SyncPayload.merge(withServer, withDeletion).servers, isEmpty);

    final readded = SyncServer(
      id: 'a',
      name: 'Maison',
      baseUrl: 'https://music.test/dav/',
      type: ServerType.webdav,
      addedAt: DateTime.utc(2026, 1, 9),
    );
    final again = SyncPayload(servers: {readded.key: readded});
    expect(SyncPayload.merge(withDeletion, again).servers, hasLength(1));
  });

  test('a server and its password reach another device, and deletions follow',
      () async {
    final first = _device();
    final second = _device();
    await first.provider.addProfile(profile('first-id'), 'p@ss');

    var merged = SyncPayload.merge(
      await second.provider.syncSnapshot(),
      await first.provider.syncSnapshot(),
    );
    await second.provider.applySync(merged);

    expect(second.provider.profiles.single.baseUrl, 'https://music.test/dav/');
    expect(
        second.service.passwords[second.provider.profiles.single.id], 'p@ss');

    // Syncing again on the first device must not duplicate anything.
    await first.provider.applySync(merged);
    expect(first.provider.profiles, hasLength(1));

    await second.provider.deleteProfile(second.provider.profiles.single);
    merged = SyncPayload.merge(
      await first.provider.syncSnapshot(),
      await second.provider.syncSnapshot(),
    );
    await first.provider.applySync(merged);
    expect(first.provider.profiles, isEmpty);
  });
}

_Device _device() {
  final service = _MemoryService();
  return _Device(
    ServerProvider(service, RemoteServerService()),
    service,
  );
}

class _Device {
  _Device(this.provider, this.service);
  final ServerProvider provider;
  final _MemoryService service;
}

class _MemoryService extends ServerProfileService {
  final Map<String, String> passwords = {};
  List<ServerProfile> saved = [];

  @override
  Future<List<ServerProfile>> load() async => saved;

  @override
  Future<void> save(List<ServerProfile> profiles) async =>
      saved = List.of(profiles);

  @override
  Future<String> readPassword(String profileId) async =>
      passwords[profileId] ?? '';

  @override
  Future<void> writePassword(String profileId, String password) async =>
      passwords[profileId] = password;

  @override
  Future<void> deletePassword(String profileId) async =>
      passwords.remove(profileId);
}
