import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/services/audio_metadata_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('metadata remains available after parsing on a background isolate',
      () async {
    final result = await const AudioMetadataService().read(
      'hosting/demo/Demo Album/01 Morning Scale.mp3',
    );
    expect(result.title, 'Morning Scale');
    expect(result.artist, 'MusicStream Demo');
    expect(result.durationMs, greaterThan(0));
  });

  test('missing files report asynchronous errors from metadata parsing',
      () async {
    await expectLater(
      const AudioMetadataService().read('missing-audio-fixture.mp3'),
      throwsA(isA<FileSystemException>()),
    );
  });
}
