import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:music_reader_app/models/remote_audio_entry.dart';
import 'package:music_reader_app/services/audio_metadata_service.dart';
import 'package:music_reader_app/services/remote_audio_metadata_service.dart';

class _InspectingMetadataService extends AudioMetadataService {
  _InspectingMetadataService(this.expectedLength);

  final int expectedLength;

  @override
  Future<AudioMetadata> read(String path) async {
    final file = File(path);
    expect(await file.length(), expectedLength);
    final input = await file.open();
    expect(utf8.decode(await input.read(4)), 'HEAD');
    await input.setPosition(expectedLength - 4);
    expect(utf8.decode(await input.read(4)), 'TAIL');
    await input.close();
    return AudioMetadata(
      title: 'Titre distant',
      artist: 'Artiste distant',
      album: 'Album distant',
      artworkBytes: Uint8List.fromList([1, 2, 3]),
      artworkExtension: 'png',
    );
  }
}

void main() {
  test('builds a sparse M4A sample from HTTP head and tail ranges', () async {
    const sampleLimit = 64 * 1024;
    const totalSize = sampleLimit * 3;
    final adapter = _RangeAdapter(totalSize);
    final dio = Dio()..httpClientAdapter = adapter;
    final temporary = await Directory.systemTemp.createTemp('remote_metadata_');
    addTearDown(() async {
      dio.close(force: true);
      await temporary.delete(recursive: true);
    });
    final uri = Uri.parse('https://music.example.test/sample.m4a');
    final service = RemoteAudioMetadataService(
      dio: dio,
      metadataService: _InspectingMetadataService(totalSize),
      cacheDirectory: () async => temporary,
      sampleLimit: sampleLimit,
    );

    final metadata = await service.load(RemoteAudioEntry(
      name: 'sample.m4a',
      uri: uri,
      isDirectory: false,
      size: totalSize,
    ));

    expect(metadata.title, 'Titre distant');
    expect(metadata.artist, 'Artiste distant');
    expect(metadata.album, 'Album distant');
    expect(adapter.requestedRanges, hasLength(2));
    expect(adapter.requestedRanges.first, startsWith('bytes=0-'));
    expect(adapter.requestedRanges.last, endsWith('-${totalSize - 1}'));
    expect(metadata.artworkPath, isNotNull);
    expect(await File(metadata.artworkPath!).readAsBytes(), [1, 2, 3]);
    final cachedFiles = await Directory(
      '${temporary.path}/remote_audio_metadata',
    ).list().toList();
    expect(cachedFiles, hasLength(1));
  });
}

class _RangeAdapter implements HttpClientAdapter {
  _RangeAdapter(this.totalSize);

  final int totalSize;
  final List<String> requestedRanges = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final range = options.headers['Range']! as String;
    requestedRanges.add(range);
    final match = RegExp(r'bytes=(\d+)-(\d+)').firstMatch(range)!;
    final start = int.parse(match.group(1)!);
    final requestedEnd = int.parse(match.group(2)!);
    final end = requestedEnd.clamp(start, totalSize - 1);
    final bytes = Uint8List(end - start + 1);
    if (start == 0) bytes.setRange(0, 4, utf8.encode('HEAD'));
    if (end == totalSize - 1) {
      bytes.setRange(bytes.length - 4, bytes.length, utf8.encode('TAIL'));
    }
    return ResponseBody.fromBytes(
      bytes,
      HttpStatus.partialContent,
      headers: {
        'content-range': ['bytes $start-$end/$totalSize'],
        Headers.contentLengthHeader: ['${bytes.length}'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
