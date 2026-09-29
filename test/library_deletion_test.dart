import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/models/music_playlist.dart';
import 'package:music_reader_app/models/music_track.dart';
import 'package:music_reader_app/providers/library_provider.dart';
import 'package:music_reader_app/services/library_service.dart';
import 'package:music_reader_app/services/lyrics_service.dart';
import 'package:music_reader_app/services/playlist_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    root = await Directory.systemTemp.createTemp('musicstream-delete-');
  });

  tearDown(() async => root.delete(recursive: true));

  test('deletes one private copy, its artwork and lyrics, and playlist links',
      () async {
    final music = await Directory('${root.path}/music').create();
    final artwork = await Directory('${root.path}/artwork').create();
    final firstFile = File('${music.path}/first.mp3')
      ..writeAsStringSync('first');
    final secondFile = File('${music.path}/second.mp3')
      ..writeAsStringSync('second');
    final original = File('${root.path}/original.mp3')
      ..writeAsStringSync('original');
    final cover = File('${artwork.path}/first.jpg')..writeAsStringSync('cover');
    final first = _track('first', firstFile,
        artwork: cover, source: MusicSource.serverDownload);
    final second =
        _track('second', secondFile, source: MusicSource.localImport);
    final lyrics = LyricsService(documentsDirectory: () async => root);
    final sidecar = File('${root.path}/source.lrc')
      ..writeAsStringSync('[00:01.00] Example');
    await lyrics.importSidecar(first.id, sidecar);
    final service = LibraryService(
      lyricsService: lyrics,
      documentsDirectory: () async => root,
    );
    final playlists = PlaylistService();
    await service.save([first, second]);
    await playlists.save([
      MusicPlaylist(
        id: 'playlist',
        name: 'Favorites',
        trackIds: [first.id, second.id],
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    ]);
    final library = LibraryProvider(service, playlists);
    await library.load();
    expect(library.downloadedTracks.map((track) => track.id), [first.id]);
    expect(library.downloadedSourceUris, {'https://example.com/first.mp3'});

    expect(await library.deleteTracks([first.id]), 1);

    expect(await firstFile.exists(), isFalse);
    expect(await cover.exists(), isFalse);
    expect(await lyrics.load(first.id), isNull);
    expect(await original.exists(), isTrue);
    expect(await secondFile.exists(), isTrue);
    expect(library.allTracks.map((track) => track.id), [second.id]);
    expect(library.playlists.single.trackIds, [second.id]);
    expect(library.downloadedTracks, isEmpty);
    expect(library.downloadedSourceUris, isEmpty);

    expect(
        await library.deleteTracks(library.allTracks.map((track) => track.id)),
        1);
    expect(await secondFile.exists(), isFalse);
    expect(library.allTracks, isEmpty);
    expect(library.playlists.single.trackIds, isEmpty);
  });

  test('refuses to delete a file outside the private music directory',
      () async {
    final external = File('${root.path}/source.mp3')..writeAsStringSync('keep');
    final service = LibraryService(documentsDirectory: () async => root);

    await expectLater(
      service.deleteTrackFiles(_track('outside', external)),
      throwsStateError,
    );
    expect(await external.exists(), isTrue);
  });

  test('removes private copies no track references, keeping the library',
      () async {
    final music = await Directory('${root.path}/music').create();
    final artwork = await Directory('${root.path}/artwork').create();
    final kept = File('${music.path}/kept.mp3')..writeAsStringSync('kept');
    final cover = File('${artwork.path}/kept.jpg')..writeAsStringSync('cover');
    final orphan = File('${music.path}/orphan.flac')..writeAsStringSync('x');
    final orphanCover = File('${artwork.path}/orphan.jpg')
      ..writeAsStringSync('x');
    final service = LibraryService(documentsDirectory: () async => root);
    // A different path prefix for the same file must still count as kept.
    final moved = _track(
      'kept',
      File('/data/user/0/app/music/kept.mp3'),
      artwork: cover,
    );
    final other = _track('other', File('${music.path}/missing.mp3'));

    expect(await service.removeOrphanFiles([moved, other]), 2);
    expect(await kept.exists(), isTrue);
    expect(await cover.exists(), isTrue);
    expect(await orphan.exists(), isFalse);
    expect(await orphanCover.exists(), isFalse);
  });

  test('orphan cleanup releases the import lock for listeners', () async {
    final music = await Directory('${root.path}/music').create();
    final file = File('${music.path}/kept.mp3')..writeAsStringSync('kept');
    final service = LibraryService(documentsDirectory: () async => root);
    await service.save([_track('kept', file)]);
    final library = LibraryProvider(service, PlaylistService());
    await library.load();
    final busyStates = <bool>[];
    library.addListener(() => busyStates.add(library.isDeleting));

    await library.removeOrphanFiles();

    expect(library.isDeleting, isFalse);
    expect(busyStates.last, isFalse);
  });

  test('never cleans up without tracks or when most files look orphaned',
      () async {
    final music = await Directory('${root.path}/music').create();
    final files = [
      for (final name in ['a', 'b', 'c'])
        File('${music.path}/$name.mp3')..writeAsStringSync(name),
    ];
    final service = LibraryService(documentsDirectory: () async => root);

    expect(await service.removeOrphanFiles([]), 0);
    expect(
      await service.removeOrphanFiles(
          [_track('unrelated', File('${music.path}/z.mp3'))]),
      0,
    );
    for (final file in files) {
      expect(await file.exists(), isTrue);
    }
  });

  test('legacy tracks with unknown origin are excluded from bulk downloads',
      () async {
    final file = File('${root.path}/legacy.mp3')..writeAsStringSync('legacy');
    final service = LibraryService(documentsDirectory: () async => root);
    await service.save([_track('legacy', file)]);
    final library = LibraryProvider(service, PlaylistService());
    await library.load();

    expect(library.downloadedTracks, isEmpty);
    expect(library.allTracks, hasLength(1));
    expect(library.unknownSourceTracks.single.id, 'legacy');
  });
}

MusicTrack _track(String id, File file, {File? artwork, MusicSource? source}) =>
    MusicTrack(
      id: id,
      title: id,
      uri: file.uri.toString(),
      artworkUri: artwork?.uri.toString(),
      source: source,
      sourceUri: source == MusicSource.serverDownload
          ? 'https://example.com/first.mp3'
          : null,
      metadataRead: true,
      addedAt: DateTime.utc(2026),
    );
