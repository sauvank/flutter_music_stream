import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/models/remote_audio_entry.dart';
import 'package:music_reader_app/services/server_scan_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('creates a baseline before reporting later album additions', () async {
    final service = ServerScanService();
    final initial = [
      _entry('/music/Album A/01.mp3'),
      _entry('/music/Album A/02.mp3'),
    ];

    final baseline = await service.compareAndSave('server', initial);
    final update = await service.compareAndSave('server', [
      ...initial,
      _entry('/music/Album B/01.mp3'),
      _entry('/music/Album B/02.mp3'),
    ]);

    expect(baseline.baselineCreated, isTrue);
    expect(baseline.newAlbums, isEmpty);
    expect(update.baselineCreated, isFalse);
    expect(update.totalTracks, 4);
    expect(update.newTrackCount, 2);
    expect(update.newAlbums.single.name, 'Album B');
    expect(update.newAlbums.single.trackCount, 2);
  });

  test('does not report renamed query parameters as new files', () async {
    final service = ServerScanService();
    await service.compareAndSave('server', [
      _entry('/music/Album/01.mp3?token=first'),
    ]);

    final result = await service.compareAndSave('server', [
      _entry('/music/Album/01.mp3?token=second'),
    ]);

    expect(result.newAlbums, isEmpty);
  });

  test('replaces an invalid snapshot with a fresh baseline', () async {
    SharedPreferences.setMockInitialValues({
      'server_scan_snapshot_v1_server': '{invalid',
    });
    final service = ServerScanService();

    final result = await service.compareAndSave('server', [
      _entry('/music/Album/01.mp3'),
    ]);

    expect(result.baselineCreated, isTrue);
    expect(result.totalTracks, 1);
    expect(result.newAlbums, isEmpty);
  });
}

RemoteAudioEntry _entry(String path) => RemoteAudioEntry(
      name: Uri.parse(path).pathSegments.last,
      uri: Uri.parse('https://music.example.test$path'),
      isDirectory: false,
    );
