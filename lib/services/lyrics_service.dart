import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/lyrics_document.dart';
import '../models/music_track.dart';

class LyricsService {
  static final shared = LyricsService();

  LyricsService({
    Dio? dio,
    Future<Directory> Function()? documentsDirectory,
    this.endpoint = 'https://lrclib.net/api/get',
  })  : _dio = dio ?? Dio(),
        _documentsDirectory =
            documentsDirectory ?? getApplicationDocumentsDirectory;

  final Dio _dio;
  final Future<Directory> Function() _documentsDirectory;
  final String endpoint;
  DateTime? _retryAt;
  bool _searching = false;

  Future<Directory> _lyricsDirectory() async =>
      Directory(p.join((await _documentsDirectory()).path, 'lyrics'));

  String _fileStem(String trackId) =>
      sha256.convert(utf8.encode(trackId)).toString();

  Future<LyricsDocument?> load(String trackId) async {
    final directory = await _lyricsDirectory();
    final stem = _fileStem(trackId);
    for (final extension in ['lrc', 'txt']) {
      final file = File(p.join(directory.path, '$stem.$extension'));
      if (!await file.exists()) continue;
      final document = LyricsDocument.parse(await file.readAsString());
      if (!document.isEmpty) return document;
    }
    return null;
  }

  Future<bool> importFile(String trackId) async {
    final selection = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['lrc'],
    );
    final source = selection?.files.singleOrNull?.path;
    if (source == null) return false;
    await importSidecar(trackId, File(source));
    return true;
  }

  Future<void> importSidecar(String trackId, File source) async {
    final content = await source.readAsString();
    if (LyricsDocument.parse(content).isEmpty) {
      throw const FormatException('Le fichier de paroles est vide.');
    }
    await _save(trackId, content, 'lrc');
  }

  Future<LyricsDocument?> searchOnline(MusicTrack track) async {
    if (track.artist == 'Artiste inconnu' || track.title.trim().isEmpty) {
      throw const FormatException(
        'Le titre et l’artiste sont nécessaires pour chercher des paroles.',
      );
    }
    final retryAt = _retryAt;
    if (retryAt != null && DateTime.now().isBefore(retryAt)) {
      final remaining = retryAt.difference(DateTime.now()).inSeconds + 1;
      throw LyricsRateLimitException(remaining.toString());
    }
    if (_searching) {
      throw StateError('Une recherche de paroles est déjà en cours.');
    }
    _searching = true;
    try {
      return await _searchOnline(track);
    } finally {
      _searching = false;
    }
  }

  Future<LyricsDocument?> _searchOnline(MusicTrack track) async {
    final parameters = <String, dynamic>{
      'track_name': track.title,
      'artist_name': track.artist,
      if (track.album != 'Album inconnu') 'album_name': track.album,
      if (track.durationMs != null &&
          track.durationMs! >= 1000 &&
          track.durationMs! <= 3600000)
        'duration': (track.durationMs! / 1000).round(),
    };
    final response = await _dio.get<Map<String, dynamic>>(
      endpoint,
      queryParameters: parameters,
      options: Options(
        headers: const {
          'User-Agent':
              'MusicStream/0.1 (https://github.com/sauvank/flutter_music_reade)',
        },
        receiveTimeout: const Duration(seconds: 20),
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode == 429) {
      final retryAfter = response.headers.value('retry-after');
      final seconds = int.tryParse(retryAfter ?? '');
      if (seconds != null) {
        _retryAt = DateTime.now().add(Duration(seconds: seconds));
      } else {
        try {
          _retryAt = HttpDate.parse(retryAfter!);
        } catch (_) {
          _retryAt = DateTime.now().add(const Duration(seconds: 30));
        }
      }
      throw LyricsRateLimitException(retryAfter);
    }
    if (response.statusCode != 200 || response.data == null) {
      throw StateError('LRCLIB est indisponible pour le moment.');
    }
    final data = response.data!;
    if (data['instrumental'] == true) return null;
    final synced = data['syncedLyrics'] as String?;
    if (synced != null && LyricsDocument.parse(synced).synchronized) {
      await _save(track.id, synced, 'lrc');
      return LyricsDocument.parse(synced);
    }
    final plain = data['plainLyrics'] as String?;
    if (plain == null || LyricsDocument.parse(plain).isEmpty) return null;
    await _save(track.id, plain, 'txt');
    return LyricsDocument.parse(plain);
  }

  Future<void> _save(String trackId, String content, String extension) async {
    final directory = await _lyricsDirectory();
    await directory.create(recursive: true);
    final stem = _fileStem(trackId);
    final other = extension == 'lrc' ? 'txt' : 'lrc';
    await File(p.join(directory.path, '$stem.$extension'))
        .writeAsString(content, flush: true);
    final otherFile = File(p.join(directory.path, '$stem.$other'));
    if (await otherFile.exists()) await otherFile.delete();
  }
}

class LyricsRateLimitException implements Exception {
  const LyricsRateLimitException(this.retryAfter);

  final String? retryAfter;

  @override
  String toString() {
    final seconds = int.tryParse(retryAfter ?? '');
    if (seconds != null) {
      return 'LRCLIB limite les demandes. Réessayez dans $seconds secondes.';
    }
    return retryAfter == null
        ? 'LRCLIB limite temporairement les demandes. Réessayez plus tard.'
        : 'LRCLIB limite les demandes. Réessayez après $retryAfter.';
  }
}
