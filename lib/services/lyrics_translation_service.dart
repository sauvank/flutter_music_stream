import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/lyrics_document.dart';

class LyricsTranslationService {
  static final shared = LyricsTranslationService();

  static const languages = <String, String>{
    'Français': 'fr',
    'English': 'en',
    'Español': 'es',
    'Deutsch': 'de',
    'Italiano': 'it',
    'Português': 'pt',
    '日本語': 'ja',
    '한국어': 'ko',
    '中文': 'zh',
    'Русский': 'ru',
    'العربية': 'ar',
  };

  LyricsTranslationService({
    Dio? dio,
    Future<Directory> Function()? documentsDirectory,
    this.endpoint = 'https://api.mymemory.translated.net/get',
  })  : _dio = dio ?? Dio(),
        _documentsDirectory =
            documentsDirectory ?? getApplicationDocumentsDirectory;

  final Dio _dio;
  final Future<Directory> Function() _documentsDirectory;
  final String endpoint;

  Future<LyricsDocument> translate(
      String trackId, LyricsDocument original, String language) async {
    if (!languages.values.contains(language)) {
      throw ArgumentError.value(language, 'language', 'Unsupported language');
    }
    if (original.isEmpty) return original;
    final source = original.synchronized
        ? original.lines.map((line) => line.text).toList()
        : original.plainText.split('\n');
    final signature = sha256
        .convert(utf8.encode(jsonEncode([trackId, language, source])))
        .toString();
    final directory = Directory(
        p.join((await _documentsDirectory()).path, 'lyrics', 'translations'));
    final cache = File(p.join(directory.path, '$signature.json'));
    if (await cache.exists()) {
      try {
        final decoded = jsonDecode(await cache.readAsString());
        if (decoded is List &&
            decoded.length == source.length &&
            decoded.every((item) => item is String)) {
          return _buildDocument(original, List<String>.from(decoded));
        }
      } catch (_) {
        // A damaged cache entry can be replaced by a fresh translation.
      }
    }

    final translated = List<String>.from(source);
    var batch = <int>[];
    var length = 0;
    Future<void> flush() async {
      if (batch.isEmpty) return;
      final answer = await _translateBatch(
          batch.map((index) => source[index]).join(' ||| '), language);
      final parts = answer.split('|||').map((part) => part.trim()).toList();
      if (parts.length == batch.length) {
        for (var i = 0; i < batch.length; i++) {
          translated[batch[i]] = parts[i];
        }
      } else {
        // Some translations rewrite the separator. Retry only this batch
        // line by line to keep synchronized timestamps aligned.
        for (final index in batch) {
          translated[index] = await _translateBatch(source[index], language);
        }
      }
      batch = <int>[];
      length = 0;
    }

    for (var i = 0; i < source.length; i++) {
      final line = source[i].trim();
      if (line.isEmpty) continue;
      if (line.length > 400) {
        throw const FormatException('Une ligne est trop longue à traduire.');
      }
      if (length + line.length + (batch.isEmpty ? 0 : 5) > 400) {
        await flush();
      }
      batch.add(i);
      length += line.length + (batch.length == 1 ? 0 : 5);
    }
    await flush();
    await directory.create(recursive: true);
    await cache.writeAsString(jsonEncode(translated), flush: true);
    return _buildDocument(original, translated);
  }

  LyricsDocument _buildDocument(LyricsDocument original, List<String> text) {
    if (original.synchronized) {
      return LyricsDocument(
        lines: List.generate(original.lines.length,
            (index) => LyricsLine(original.lines[index].time, text[index])),
        plainText: '',
      );
    }
    return LyricsDocument(lines: const [], plainText: text.join('\n'));
  }

  Future<String> _translateBatch(String text, String language) async {
    final response = await _dio.get<dynamic>(
      endpoint,
      queryParameters: {'q': text, 'langpair': 'autodetect|$language'},
      options: Options(receiveTimeout: const Duration(seconds: 12)),
    );
    if (response.statusCode != 200 || response.data is! Map) {
      throw StateError('Le service de traduction est indisponible.');
    }
    final data = response.data as Map;
    final status = data['responseStatus'];
    final translated = (data['responseData'] as Map?)?['translatedText'];
    if ((status != 200 && status != '200') || translated is! String) {
      throw StateError('Le service de traduction a refusé la demande.');
    }
    return translated.trim();
  }
}
