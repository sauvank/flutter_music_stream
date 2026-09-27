import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/models/server_profile.dart';
import 'package:music_reader_app/services/remote_server_service.dart';

void main() {
  test('WebDAV recognizes audio from href when display name has no extension',
      () async {
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        expect(options.method, 'PROPFIND');
        handler.resolve(Response<String>(
          requestOptions: options,
          statusCode: 207,
          data: '''
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/dav/music/</d:href>
    <d:propstat><d:prop><d:resourcetype><d:collection/></d:resourcetype></d:prop></d:propstat>
  </d:response>
  <d:response>
    <d:href>/dav/music/song.mp3</d:href>
    <d:propstat><d:prop><d:displayname>Song title</d:displayname><d:resourcetype/></d:prop></d:propstat>
  </d:response>
  <d:response>
    <d:href>/dav/music/notes.txt</d:href>
    <d:propstat><d:prop><d:displayname>Notes</d:displayname><d:resourcetype/></d:prop></d:propstat>
  </d:response>
</d:multistatus>
''',
        ));
      }));
    const profile = ServerProfile(
      id: 'server',
      name: 'Example',
      baseUrl: 'https://example.com/dav/music/',
      type: ServerType.webdav,
    );

    final entries = await RemoteServerService(dio: dio).list(
      profile,
      Uri.parse(profile.baseUrl),
      '',
    );

    expect(entries.map((entry) => entry.name), ['Song title']);
    expect(entries.single.uri.path, '/dav/music/song.mp3');
  });

  test('WebDAV retries without a trailing slash when only the root is listed',
      () async {
    final requestedPaths = <String>[];
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        requestedPaths.add(options.uri.path);
        final hasSlash = options.uri.path.endsWith('/');
        handler.resolve(Response<String>(
          requestOptions: options,
          statusCode: 207,
          data: '''<d:multistatus xmlns:d="DAV:">
  <d:response><d:href>/dav/music/</d:href></d:response>
  ${hasSlash ? '' : '<d:response><d:href>song.mp3</d:href><d:displayname>Song</d:displayname></d:response>'}
</d:multistatus>''',
        ));
      }));
    const profile = ServerProfile(
      id: 'server',
      name: 'Example',
      baseUrl: 'https://example.com/dav/music/',
      type: ServerType.webdav,
    );

    final entries = await RemoteServerService(dio: dio).list(
      profile,
      Uri.parse(profile.baseUrl),
      '',
    );

    expect(requestedPaths, ['/dav/music/', '/dav/music']);
    expect(entries.single.uri.path, '/dav/music/song.mp3');
  });

  test('WebDAV ignores a folder that names itself with different escaping',
      () async {
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        handler.resolve(Response<String>(
          requestOptions: options,
          statusCode: 207,
          data: '''<d:multistatus xmlns:d="DAV:">
  <d:response><d:href>/dav/Artist%20Name/</d:href>
    <d:resourcetype><d:collection/></d:resourcetype>
    <d:displayname>Artist Name</d:displayname>
  </d:response>
</d:multistatus>''',
        ));
      }));
    const profile = ServerProfile(
      id: 'server',
      name: 'Example',
      baseUrl: 'https://example.com/dav/Artist%2520Name/',
      type: ServerType.webdav,
    );

    final entries = await RemoteServerService(dio: dio).list(
      profile,
      Uri.parse(profile.baseUrl),
      '',
    );

    expect(entries, isEmpty);
  });

  test('WebDAV accepts a folder name containing a literal percent sign',
      () async {
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        handler.resolve(Response<String>(
          requestOptions: options,
          statusCode: 207,
          data: '''<d:multistatus xmlns:d="DAV:">
  <d:response><d:href>/dav/music/</d:href></d:response>
  <d:response><d:href>/dav/music/100%25real/</d:href>
    <d:resourcetype><d:collection/></d:resourcetype>
    <d:displayname>100%real</d:displayname>
  </d:response>
</d:multistatus>''',
        ));
      }));
    const profile = ServerProfile(
      id: 'server',
      name: 'Example',
      baseUrl: 'https://example.com/dav/music/',
      type: ServerType.webdav,
    );

    final entries = await RemoteServerService(dio: dio).list(
      profile,
      Uri.parse(profile.baseUrl),
      '',
    );

    expect(entries.single.name, '100%real');
  });
}
