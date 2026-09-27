import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/models/lyrics_document.dart';
import 'package:music_reader_app/services/lyrics_translation_service.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory =
        await Directory.systemTemp.createTemp('musicstream-translation-');
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test('translates synchronized lines without changing their timestamps',
      () async {
    var requests = 0;
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        requests++;
        expect(options.queryParameters['langpair'], 'autodetect|fr');
        expect(options.queryParameters['q'], 'First ||| Second');
        handler.resolve(Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'responseStatus': 200,
            'responseData': {'translatedText': 'Premier ||| Deuxième'},
          },
        ));
      }));
    final service = LyricsTranslationService(
      dio: dio,
      documentsDirectory: () async => directory,
    );
    final original =
        LyricsDocument.parse('[00:01.00] First\n[00:02.00] Second');

    final translated = await service.translate('track-id', original, 'fr');
    final cached = await service.translate('track-id', original, 'fr');

    expect(translated.lines.map((line) => line.text), ['Premier', 'Deuxième']);
    expect(translated.lines.map((line) => line.time),
        original.lines.map((line) => line.time));
    expect(cached.lines.last.text, 'Deuxième');
    expect(requests, 1);
  });

  test('retries individual lines if the provider rewrites separators',
      () async {
    var requests = 0;
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        requests++;
        final query = options.queryParameters['q'] as String;
        handler.resolve(Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'responseStatus': 200,
            'responseData': {
              'translatedText': query.contains('|||')
                  ? 'Séparateur supprimé'
                  : query == 'First'
                      ? 'Premier'
                      : 'Deuxième',
            },
          },
        ));
      }));
    final service = LyricsTranslationService(
      dio: dio,
      documentsDirectory: () async => directory,
    );

    final translated = await service.translate('track-id',
        LyricsDocument.parse('[00:01.00] First\n[00:02.00] Second'), 'fr');

    expect(translated.lines.map((line) => line.text), ['Premier', 'Deuxième']);
    expect(requests, 3);
  });
}
