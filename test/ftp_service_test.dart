import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/services/ftp_service.dart';

void main() {
  test('parses an MLSD listing and keeps only folders and supported audio', () {
    final entries = FtpService().parseListing(
      Uri.parse('ftp://music.example.test/media/music/'),
      'type=dir; Album été\r\n'
      'type=file;size=4; track 01.mp3\r\n'
      'type=file;size=10; cover.jpg\r\n',
      mlsd: true,
    );

    expect(entries.map((entry) => entry.name), ['Album été', 'track 01.mp3']);
    expect(entries.first.isDirectory, isTrue);
    expect(
      entries.first.uri.pathSegments
          .where((segment) => segment.isNotEmpty)
          .last,
      'Album été',
    );
    expect(entries.last.size, 4);
    expect(entries.last.uri.userInfo, isEmpty);
    expect(entries.last.uri.pathSegments.last, 'track 01.mp3');
  });

  test('parses Unix LIST responses when MLSD is unavailable', () {
    final entries = FtpService().parseListing(
      Uri.parse('ftp://music.example.test/media/music/'),
      'drwxr-xr-x 2 user group 4096 Jan 01 12:00 Album\r\n'
      '-rw-r--r-- 1 user group 1234 Jan 01 12:00 chanson.flac\r\n',
      mlsd: false,
    );

    expect(entries, hasLength(2));
    expect(entries.first.isDirectory, isTrue);
    expect(entries.last.size, 1234);
  });
}
