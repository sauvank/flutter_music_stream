import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/remote_audio_entry.dart';
import '../models/remote_audio_metadata.dart';
import 'audio_metadata_service.dart';

class RemoteAudioMetadataService {
  RemoteAudioMetadataService({
    Dio? dio,
    AudioMetadataService? metadataService,
  })  : _dio = dio ?? Dio(),
        _metadataService = metadataService ?? const AudioMetadataService();

  static const _sampleLimit = 8 * 1024 * 1024;
  final Dio _dio;
  final AudioMetadataService _metadataService;
  final Map<String, Future<RemoteAudioMetadata>> _cache = {};

  Future<RemoteAudioMetadata> load(
    RemoteAudioEntry entry, {
    Map<String, String> headers = const {},
  }) =>
      _cache.putIfAbsent(
        entry.uri.toString(),
        () => _load(entry, headers),
      );

  Future<RemoteAudioMetadata> _load(
    RemoteAudioEntry entry,
    Map<String, String> headers,
  ) async {
    final fallback = _fallback(entry.name);
    final cacheRoot = await getTemporaryDirectory();
    final directory =
        Directory(p.join(cacheRoot.path, 'remote_audio_metadata'));
    await directory.create(recursive: true);
    final key = sha256.convert(entry.uri.toString().codeUnits).toString();
    final sample =
        File(p.join(directory.path, '$key${p.extension(entry.name)}'));
    try {
      final response = await _dio.get<ResponseBody>(
        entry.uri.toString(),
        options: Options(
          responseType: ResponseType.stream,
          headers: {...headers, 'Range': 'bytes=0-${_sampleLimit - 1}'},
          validateStatus: (status) => status == 200 || status == 206,
        ),
      );
      final stream = response.data?.stream;
      if (stream == null) return fallback;
      final sink = sample.openWrite();
      var written = 0;
      await for (final chunk in stream) {
        final remaining = _sampleLimit - written;
        if (remaining <= 0) break;
        final bytes =
            chunk.length <= remaining ? chunk : chunk.sublist(0, remaining);
        sink.add(bytes);
        written += bytes.length;
        if (written >= _sampleLimit) break;
      }
      await sink.close();
      final metadata = await _metadataService.read(sample.path);
      String? artworkPath;
      final artwork = metadata.artworkBytes;
      if (artwork != null && artwork.isNotEmpty) {
        final file = File(p.join(
          directory.path,
          '$key.${metadata.artworkExtension ?? 'jpg'}',
        ));
        await file.writeAsBytes(artwork, flush: true);
        artworkPath = file.path;
      }
      return RemoteAudioMetadata(
        title: metadata.title ?? fallback.title,
        artist: metadata.artist ?? fallback.artist,
        album: metadata.album,
        artworkPath: artworkPath,
      );
    } catch (error) {
      debugPrint(
        'Remote audio metadata unavailable for ${entry.name}: '
        '${error.runtimeType}',
      );
      return fallback;
    } finally {
      if (await sample.exists()) await sample.delete();
    }
  }

  RemoteAudioMetadata _fallback(String filename) {
    var value =
        p.basenameWithoutExtension(filename).replaceAll('_', ' ').trim();
    value = value.replaceFirst(RegExp(r'^\d+\s*[-.]\s*'), '').trim();
    final separator = value.indexOf(' - ');
    if (separator > 0) {
      return RemoteAudioMetadata(
        title: value.substring(separator + 3).trim(),
        artist: value.substring(0, separator).trim(),
      );
    }
    return RemoteAudioMetadata(title: value, artist: 'Artiste inconnu');
  }
}
