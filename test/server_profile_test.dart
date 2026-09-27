import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/models/server_profile.dart';

void main() {
  test('server serialization never requires a password field', () {
    const profile = ServerProfile(
      id: 'server-id',
      name: 'Serveur de démonstration',
      baseUrl: 'https://music.example.test/library/',
      type: ServerType.webdav,
      username: 'user',
    );

    final encoded = ServerProfile.encodeAll([profile]);
    final decoded = ServerProfile.decodeAll(encoded).single;

    expect(encoded, isNot(contains('password')));
    expect(decoded.type, ServerType.webdav);
    expect(decoded.username, 'user');
  });

  test('serializes FTP profiles without credentials in the URL', () {
    const profile = ServerProfile(
      id: 'ftp-server',
      name: 'Archives musicales',
      baseUrl: 'ftp://music.example.test:2121/media/music/',
      type: ServerType.ftp,
      username: 'user',
    );

    final encoded = ServerProfile.encodeAll([profile]);
    final decoded = ServerProfile.decodeAll(encoded).single;

    expect(decoded.type, ServerType.ftp);
    expect(decoded.baseUrl, profile.baseUrl);
    expect(encoded, isNot(contains('private-password')));
  });
}
