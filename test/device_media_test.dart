import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/models/music_track.dart';
import 'package:music_reader_app/providers/library_provider.dart';
import 'package:music_reader_app/services/device_media_service.dart';
import 'package:music_reader_app/services/library_service.dart';
import 'package:music_reader_app/services/lyrics_service.dart';
import 'package:music_reader_app/services/playlist_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late Directory storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    root = await Directory.systemTemp.createTemp('musicstream-device-');
    storage = await Directory('${root.path}/storage').create();
  });

  tearDown(() async => root.delete(recursive: true));

  File audio(String path) =>
      File('${storage.path}/$path')..createSync(recursive: true);

  Future<LibraryProvider> provider({List<MusicTrack> tracks = const []}) async {
    final service = LibraryService(
      documentsDirectory: () async => root,
      lyricsService: LyricsService(documentsDirectory: () async => root),
    );
    await service.save(tracks);
    final library = LibraryProvider(
      service,
      PlaylistService(),
      deviceMedia: DeviceMediaService(storageRoot: () async => storage),
    );
    await library.load();
    return library;
  }

  test('lists audio files but skips app data and hidden folders', () async {
    audio('Music/Album/One.mp3');
    audio('Music/cover.jpg');
    audio('Android/data/other.app/files/cache.mp3');
    audio('.thumbnails/hidden.flac');
    audio('Download/Two.FLAC');

    final files = await DeviceMediaService(storageRoot: () async => storage)
        .listAudioFiles();

    expect(files.map((file) => file.path.substring(storage.path.length)),
        ['/Download/Two.FLAC', '/Music/Album/One.mp3']);
  });

  test('scans only when enabled and skips copies already imported', () async {
    audio('Music/Song.mp3');
    audio('Music/Other.mp3');
    final library = await provider(tracks: [
      MusicTrack(
        id: 'private',
        title: 'Song',
        uri: 'file:///media/music/song.mp3',
        addedAt: DateTime.utc(2026),
        metadataRead: true,
        source: MusicSource.localImport,
      ),
    ]);

    expect(await library.scanDeviceMedia(), isNull);
    await library.setDeviceMediaEnabled(true);
    final summary = await library.scanDeviceMedia();

    expect(summary, (added: 1, removed: 0, skipped: 1));
    expect(library.deviceTrackCount, 1);
    expect(library.allTracks.map((track) => track.title),
        containsAll(['Song', 'Other']));
    expect(await library.scanDeviceMedia(), (added: 0, removed: 0, skipped: 1));
  });

  test('a copy downloaded later shadows the phone file on the next scan',
      () async {
    final file = audio('Music/Song.mp3');
    MusicTrack song(String id, String uri, MusicSource source) => MusicTrack(
          id: id,
          title: 'Song',
          uri: uri,
          addedAt: DateTime.utc(2026),
          metadataRead: true,
          source: source,
        );
    final library = await provider(tracks: [
      song(LibraryService.deviceTrackId(file.path), file.uri.toString(),
          MusicSource.deviceMedia),
      song('download', 'file:///media/music/song.mp3',
          MusicSource.serverDownload),
    ]);
    await library.setDeviceMediaEnabled(true);

    expect((await library.scanDeviceMedia())?.removed, 1);
    expect(library.allTracks.single.id, 'download');
  });

  test('forgets vanished files, but not when the listing comes back empty',
      () async {
    final kept = audio('Music/Kept.mp3');
    final gone = audio('Music/Gone.mp3');
    final library = await provider();
    await library.setDeviceMediaEnabled(true);
    await library.scanDeviceMedia();
    final goneId = LibraryService.deviceTrackId(gone.path);
    final playlist = await library.createPlaylist('Mix');
    await library.addTracksToPlaylist(playlist!.id, [goneId]);

    await gone.delete();
    expect((await library.scanDeviceMedia())?.removed, 1);
    expect(library.playlists.single.trackIds, isEmpty);

    await kept.delete();
    expect((await library.scanDeviceMedia())?.removed, 0);
    expect(library.deviceTrackCount, 1);
  });

  test('deleting device tracks hides them without touching their files',
      () async {
    final file = audio('Music/Mine.mp3');
    final other = audio('Music/Other.mp3');
    final library = await provider();
    await library.setDeviceMediaEnabled(true);
    await library.scanDeviceMedia();
    final id = LibraryService.deviceTrackId(file.path);

    expect(await library.deleteTracks([id]), 1);
    expect(file.existsSync(), isTrue);
    expect(library.tracks.map((track) => track.id), isNot(contains(id)));

    expect((await library.scanDeviceMedia())?.added, 0);
    final reloaded = await provider();
    await reloaded.scanDeviceMedia();
    expect(reloaded.tracks.map((track) => track.id), isNot(contains(id)));
    expect(reloaded.deviceTrackCount, 1);

    await reloaded.setDeviceMediaEnabled(false);
    expect(reloaded.deviceTrackCount, 0);
    expect(file.existsSync(), isTrue);
    expect(other.existsSync(), isTrue);
  });

  test('disabling device media only forgets its tracks', () async {
    final file = audio('Music/Mine.mp3');
    final library = await provider();
    await library.setDeviceMediaEnabled(true);
    await library.scanDeviceMedia();

    await library.setDeviceMediaEnabled(false);
    expect(library.deviceTrackCount, 0);
    expect(file.existsSync(), isTrue);
  });

  test('device tracks keep their source through serialization', () {
    final track = MusicTrack(
      id: 'device-1',
      title: 'Mine',
      uri: 'file:///media/music/mine.mp3',
      addedAt: DateTime.utc(2026),
      source: MusicSource.deviceMedia,
    );

    expect(MusicTrack.decodeAll(MusicTrack.encodeAll([track])).single.source,
        MusicSource.deviceMedia);
  });
}
