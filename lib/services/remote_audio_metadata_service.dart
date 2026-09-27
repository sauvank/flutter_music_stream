import 'dart:async';
import 'dart:collection';
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
    Future<Directory> Function()? cacheDirectory,
    int maximumConcurrentRequests = 2,
  })  : _dio = dio ?? Dio(),
        _metadataService = metadataService ?? const AudioMetadataService(),
        _cacheDirectory = cacheDirectory ?? getTemporaryDirectory,
        _maximumConcurrentRequests = maximumConcurrentRequests {
    assert(maximumConcurrentRequests > 0);
  }

  static const _sampleLimit = 8 * 1024 * 1024;
  static const _tailExtensions = {'aac', 'm4a', 'm4b', 'mp4'};
  final Dio _dio;
  final AudioMetadataService _metadataService;
  final Future<Directory> Function() _cacheDirectory;
  final int _maximumConcurrentRequests;
  final Map<String, Future<RemoteAudioMetadata>> _cache = {};
  final Queue<Completer<void>> _waiting = Queue();
  int _activeRequests = 0;

  Future<RemoteAudioMetadata> load(
    RemoteAudioEntry entry, {
    Map<String, String> headers = const {},
  }) =>
      _cache.putIfAbsent(
        entry.uri.toString(),
        () => _withRequestSlot(() => _load(entry, headers)),
      );

  Future<RemoteAudioMetadata> _load(
    RemoteAudioEntry entry,
    Map<String, String> headers,
  ) async {
    final fallback = _fallback(entry.name);
    final cacheRoot = await _cacheDirectory();
    final directory =
        Directory(p.join(cacheRoot.path, 'remote_audio_metadata'));
    await directory.create(recursive: true);
    final key = sha256.convert(entry.uri.toString().codeUnits).toString();
    final sample =
        File(p.join(directory.path, '$key${p.extension(entry.name)}'));
    RandomAccessFile? output;
    try {
      output = await sample.open(mode: FileMode.write);
      final head = await _writeRange(
        entry.uri,
        headers,
        output,
        start: 0,
        end: _sampleLimit - 1,
        destinationOffset: 0,
        maximumBytes: _sampleLimit,
      );
      final fullSize = entry.size ?? head.totalSize;
      if (head.written == 0) return fallback;
      if (fullSize != null && fullSize > head.written) {
        await output.truncate(fullSize);
        final extension =
            p.extension(entry.name).replaceFirst('.', '').toLowerCase();
        if (head.rangesSupported &&
            _tailExtensions.contains(extension) &&
            fullSize > _sampleLimit * 2) {
          final tailStart = fullSize - _sampleLimit;
          await _writeRange(
            entry.uri,
            headers,
            output,
            start: tailStart,
            end: fullSize - 1,
            destinationOffset: tailStart,
            maximumBytes: _sampleLimit,
          );
        }
      }
      await output.close();
      output = null;
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
      await output?.close();
      if (await sample.exists()) await sample.delete();
    }
  }

  Future<({int written, int? totalSize, bool rangesSupported})> _writeRange(
    Uri uri,
    Map<String, String> headers,
    RandomAccessFile output, {
    required int start,
    required int end,
    required int destinationOffset,
    required int maximumBytes,
  }) async {
    final response = await _dio.get<ResponseBody>(
      uri.toString(),
      options: Options(
        responseType: ResponseType.stream,
        headers: {...headers, 'Range': 'bytes=$start-$end'},
        validateStatus: (status) => status == 200 || status == 206,
      ),
    );
    final stream = response.data?.stream;
    if (stream == null) {
      return (written: 0, totalSize: null, rangesSupported: false);
    }
    await output.setPosition(destinationOffset);
    final rangesSupported = response.statusCode == HttpStatus.partialContent;
    var written = 0;
    await for (final chunk in stream) {
      final remaining = maximumBytes - written;
      if (remaining <= 0) break;
      final length = chunk.length <= remaining ? chunk.length : remaining;
      await output.writeFrom(chunk, 0, length);
      written += length;
      if (!rangesSupported && written >= maximumBytes) break;
    }
    return (
      written: written,
      totalSize: _totalSize(response.headers.value('content-range')),
      rangesSupported: rangesSupported,
    );
  }

  int? _totalSize(String? contentRange) {
    final match = RegExp(r'/([0-9]+)$').firstMatch(contentRange ?? '');
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  Future<T> _withRequestSlot<T>(Future<T> Function() action) async {
    if (_activeRequests >= _maximumConcurrentRequests) {
      final turn = Completer<void>();
      _waiting.add(turn);
      await turn.future;
    }
    _activeRequests++;
    try {
      return await action();
    } finally {
      _activeRequests--;
      if (_waiting.isNotEmpty) _waiting.removeFirst().complete();
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
