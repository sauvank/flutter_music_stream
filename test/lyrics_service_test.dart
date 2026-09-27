import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/models/music_track.dart';
import 'package:music_reader_app/services/lyrics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('musicstream-lyrics-');
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test('imports a local sidecar into private storage', () async {
    final source = File('${directory.path}/source.lrc');
    await source.writeAsString('[00:01.00] Demo line');
    final service = LyricsService(documentsDirectory: () async => directory);

    await service.importSidecar('track-id', source);
    await source.delete();

    final loaded = await service.load('track-id');
    expect(loaded?.lines.single.text, 'Demo line');
  });

  test('keeps remote track URIs out of cache filenames', () async {
    final source = File('${directory.path}/source.lrc');
    await source.writeAsString('[00:01.00] Demo line');
    final service = LyricsService(documentsDirectory: () async => directory);
    const trackId = 'remote:https://example.com/music/demo.mp3?mode=preview';

    await service.importSidecar(trackId, source);

    expect((await service.load(trackId))?.lines.single.text, 'Demo line');
    final stored = await Directory('${directory.path}/lyrics').list().toList();
    expect(stored, hasLength(1));
    expect(stored.single.path, isNot(contains('remote:')));
    expect(stored.single.path, isNot(contains('mode=')));
  });

  test('saves LRCLIB synchronized lyrics for offline use', () async {
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        expect(options.uri.path, '/api/get');
        expect(options.queryParameters['track_name'], 'Demo Song');
        expect(options.queryParameters['duration'], 120);
        expect(options.headers['User-Agent'], contains('MusicStream/'));
        handler.resolve(Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'instrumental': false,
            'syncedLyrics': '[00:01.00] Demo line',
            'plainLyrics': 'Demo line',
          },
        ));
      }));
    final service = LyricsService(
      dio: dio,
      documentsDirectory: () async => directory,
    );

    final result = await service.searchOnline(_track());

    expect(result?.synchronized, isTrue);
    expect((await service.load('track-id'))?.lines.single.text, 'Demo line');
  });

  test('falls back to plain lyrics when timing is unavailable', () async {
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        handler.resolve(Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'instrumental': false,
            'syncedLyrics': null,
            'plainLyrics': 'First line\nSecond line',
          },
        ));
      }));
    final service = LyricsService(
      dio: dio,
      documentsDirectory: () async => directory,
    );

    final result = await service.searchOnline(_track());

    expect(result?.synchronized, isFalse);
    expect(
        (await service.load('track-id'))?.plainText, 'First line\nSecond line');
  });

  test('reports LRCLIB rate limits without storing lyrics', () async {
    var requests = 0;
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        requests++;
        handler.resolve(Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: 429,
          headers: Headers.fromMap({
            'retry-after': ['30'],
          }),
        ));
      }));
    final service = LyricsService(
      dio: dio,
      documentsDirectory: () async => directory,
    );

    await expectLater(
      service.searchOnline(_track()),
      throwsA(isA<LyricsRateLimitException>().having(
        (error) => error.retryAfter,
        'retryAfter',
        '30',
      )),
    );
    await expectLater(service.searchOnline(_track()),
        throwsA(isA<LyricsRateLimitException>()));
    expect(requests, 1);
    expect(await service.load('track-id'), isNull);
  });
}

MusicTrack _track() => MusicTrack(
      id: 'track-id',
      title: 'Demo Song',
      artist: 'Demo Artist',
      album: 'Demo Album',
      durationMs: 120000,
      uri: 'file:///media/music/demo.mp3',
      addedAt: DateTime.utc(2026),
    );
