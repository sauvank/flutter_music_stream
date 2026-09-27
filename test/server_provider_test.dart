import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/models/server_profile.dart';
import 'package:music_reader_app/providers/server_provider.dart';
import 'package:music_reader_app/services/remote_server_service.dart';
import 'package:music_reader_app/services/server_profile_service.dart';

void main() {
  test('imports server profiles and stores the password separately', () async {
    final service = _MemoryServerProfileService();
    final provider = ServerProvider(service, RemoteServerService());

    final count = await provider.importProfilesFromJson(
      '''
      {
        "servers": [
          {
            "name": "Serveur musical",
            "baseUrl": "https://music.example.test/library/",
            "type": "webdav",
            "username": "user"
          }
        ]
      }
      ''',
      password: 'local-password',
    );

    expect(count, 1);
    expect(provider.profiles.single.name, 'Serveur musical');
    expect(service.saved.single.baseUrl, 'https://music.example.test/library/');
    expect(service.passwords.values.single, 'local-password');

    final duplicate = await provider.importProfilesFromJson(
      ServerProfile.encodeAll(provider.profiles),
    );
    expect(duplicate, 0);
  });

  test('imports a complete legacy ComicStream profile without prompting',
      () async {
    final service = _MemoryServerProfileService();
    final provider = ServerProvider(service, RemoteServerService());

    final count = await provider.importProfilesFromJson(
      '''
      [
        {
          "id": "legacy-server",
          "name": "Ancien serveur",
          "host": "music.example.test",
          "port": 8443,
          "path": "/dav/music",
          "isHttps": true,
          "serverType": "webdav",
          "username": "user",
          "password": "private-password",
          "isActive": true
        }
      ]
      ''',
    );

    expect(count, 1);
    expect(provider.profiles.single.baseUrl,
        'https://music.example.test:8443/dav/music/');
    expect(provider.profiles.single.type, ServerType.webdav);
    expect(service.passwords['legacy-server'], 'private-password');
    expect(ServerProfile.encodeAll(provider.profiles),
        isNot(contains('password')));
  });

  test('imports a legacy FTP profile without storing its password', () async {
    final service = _MemoryServerProfileService();
    final provider = ServerProvider(service, RemoteServerService());

    final count = await provider.importProfilesFromJson(
      '''
      {
        "name": "Archives musicales",
        "host": "music.example.test",
        "port": 2121,
        "path": "/media/music",
        "serverType": "ftp",
        "username": "user",
        "password": "private-password"
      }
      ''',
    );

    expect(count, 1);
    expect(provider.profiles.single.baseUrl,
        'ftp://music.example.test:2121/media/music/');
    expect(provider.profiles.single.type, ServerType.ftp);
    expect(service.passwords.values.single, 'private-password');
    expect(ServerProfile.encodeAll(provider.profiles),
        isNot(contains('private-password')));
  });
}

class _MemoryServerProfileService extends ServerProfileService {
  List<ServerProfile> saved = [];
  final Map<String, String> passwords = {};

  @override
  Future<void> save(List<ServerProfile> profiles) async {
    saved = List.of(profiles);
  }

  @override
  Future<void> writePassword(String profileId, String password) async {
    passwords[profileId] = password;
  }
}
