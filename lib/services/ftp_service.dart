import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/remote_audio_entry.dart';
import '../models/server_profile.dart';
import 'library_service.dart';

class FtpService {
  Future<List<RemoteAudioEntry>> list(
    ServerProfile profile,
    Uri directory,
    String password,
  ) async {
    final session = await _FtpSession.connect(profile, password);
    try {
      await session.changeDirectory(_decodedPath(directory));
      final listing = await session.readListing();
      return parseListing(directory, listing.body, mlsd: listing.mlsd);
    } finally {
      await session.close();
    }
  }

  Future<void> download(
    ServerProfile profile,
    Uri source,
    String password,
    String destinationPath, {
    void Function(int received, int total)? onProgress,
  }) async {
    final session = await _FtpSession.connect(profile, password);
    final destination = File(destinationPath);
    try {
      final decodedPath = _decodedPath(source);
      await session.changeDirectory(p.posix.dirname(decodedPath));
      await session.download(
        p.posix.basename(decodedPath),
        destination,
        onProgress: onProgress,
      );
    } catch (_) {
      if (await destination.exists()) await destination.delete();
      rethrow;
    } finally {
      await session.close();
    }
  }

  String _decodedPath(Uri uri) => '/${uri.pathSegments.join('/')}';

  List<RemoteAudioEntry> parseListing(
    Uri directory,
    String body, {
    required bool mlsd,
  }) {
    final entries = <RemoteAudioEntry>[];
    for (final rawLine in const LineSplitter().convert(body)) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final parsed = mlsd ? _parseMlsd(line) : _parseList(line);
      if (parsed == null || parsed.name == '.' || parsed.name == '..') continue;
      if (!parsed.directory && !_isAudio(parsed.name)) continue;
      final base = directory.path.endsWith('/')
          ? directory
          : directory.replace(path: '${directory.path}/');
      final uri = base.resolveUri(
        Uri(path: '${parsed.name}${parsed.directory ? '/' : ''}'),
      );
      entries.add(RemoteAudioEntry(
        name: parsed.name,
        uri: uri,
        isDirectory: parsed.directory,
        size: parsed.size,
      ));
    }
    entries.sort((left, right) {
      if (left.isDirectory != right.isDirectory) {
        return left.isDirectory ? -1 : 1;
      }
      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });
    return entries;
  }

  ({String name, bool directory, int? size})? _parseMlsd(String line) {
    final separator = line.indexOf(' ');
    if (separator < 0) return null;
    final facts = <String, String>{};
    for (final fact in line.substring(0, separator).split(';')) {
      final equals = fact.indexOf('=');
      if (equals > 0) {
        facts[fact.substring(0, equals).toLowerCase()] =
            fact.substring(equals + 1);
      }
    }
    final type = facts['type']?.toLowerCase();
    if (type == 'cdir' || type == 'pdir') return null;
    return (
      name: line.substring(separator + 1).trim(),
      directory: type == 'dir',
      size: int.tryParse(facts['size'] ?? ''),
    );
  }

  ({String name, bool directory, int? size})? _parseList(String line) {
    final dos = RegExp(
      r'^\d{2}-\d{2}-\d{2,4}\s+\d{2}:\d{2}(?:AM|PM)?\s+(<DIR>|\d+)\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(line);
    if (dos != null) {
      final marker = dos.group(1)!;
      final directory = marker.toUpperCase() == '<DIR>';
      return (
        name: dos.group(2)!.trim(),
        directory: directory,
        size: directory ? null : int.tryParse(marker),
      );
    }
    final parts = line.split(RegExp(r'\s+'));
    if (parts.length < 9) return null;
    return (
      name: parts.sublist(8).join(' '),
      directory: parts.first.startsWith('d'),
      size: int.tryParse(parts[4]),
    );
  }

  bool _isAudio(String name) => LibraryService.supportedExtensions
      .contains(p.extension(name).replaceFirst('.', '').toLowerCase());
}

class _FtpSession {
  _FtpSession._(this._socket, this._reader, this._host);

  final Socket _socket;
  final _FtpResponseReader _reader;
  final String _host;

  static Future<_FtpSession> connect(
    ServerProfile profile,
    String password,
  ) async {
    final uri = Uri.parse(profile.baseUrl);
    final socket = await Socket.connect(
      uri.host,
      uri.hasPort ? uri.port : 21,
      timeout: const Duration(seconds: 10),
    );
    final session = _FtpSession._(
      socket,
      _FtpResponseReader(socket),
      uri.host,
    );
    try {
      session._expect(await session._reader.read(), const {220});
      final user = profile.username.isEmpty ? 'anonymous' : profile.username;
      final userResponse = await session._command('USER $user');
      if (userResponse.code == 331) {
        session._expect(await session._command('PASS $password'), const {230});
      } else {
        session._expect(userResponse, const {230});
      }
      session._expect(await session._command('TYPE I'), const {200});
      final utf8Response = await session._command('OPTS UTF8 ON');
      if (utf8Response.code != 200 && utf8Response.code != 202) {
        // UTF-8 is optional; modern servers generally enable it by default.
      }
      return session;
    } catch (_) {
      socket.destroy();
      rethrow;
    }
  }

  Future<void> changeDirectory(String path) async {
    final normalized = path.isEmpty ? '/' : path;
    _expect(await _command('CWD $normalized'), const {250});
  }

  Future<({String body, bool mlsd})> readListing() async {
    final data = await _openPassiveDataSocket();
    var response = await _command('MLSD');
    var mlsd = response.code == 125 || response.code == 150;
    if (!mlsd) {
      data.destroy();
      final fallbackData = await _openPassiveDataSocket();
      response = await _command('LIST');
      _expect(response, const {125, 150});
      final body = await _readData(fallbackData);
      _expect(await _reader.read(), const {226, 250});
      return (body: body, mlsd: false);
    }
    final body = await _readData(data);
    _expect(await _reader.read(), const {226, 250});
    return (body: body, mlsd: true);
  }

  Future<void> download(
    String filename,
    File destination, {
    void Function(int received, int total)? onProgress,
  }) async {
    var total = 0;
    final sizeResponse = await _command('SIZE $filename');
    if (sizeResponse.code == 213) {
      total = int.tryParse(sizeResponse.message.trim()) ?? 0;
    }
    final data = await _openPassiveDataSocket();
    _expect(await _command('RETR $filename'), const {125, 150});
    final sink = destination.openWrite();
    var received = 0;
    try {
      await for (final bytes in data.timeout(const Duration(seconds: 45))) {
        sink.add(bytes);
        received += bytes.length;
        onProgress?.call(received, total);
      }
      await sink.flush();
    } finally {
      await sink.close();
      data.destroy();
    }
    _expect(await _reader.read(), const {226, 250});
  }

  Future<Socket> _openPassiveDataSocket() async {
    final epsv = await _command('EPSV');
    if (epsv.code == 229) {
      final match = RegExp(r'\(\|\|\|(\d+)\|\)').firstMatch(epsv.raw);
      if (match != null) {
        return Socket.connect(
          _host,
          int.parse(match.group(1)!),
          timeout: const Duration(seconds: 10),
        );
      }
    }
    final pasv = await _command('PASV');
    _expect(pasv, const {227});
    final match = RegExp(
      r'\((\d+),(\d+),(\d+),(\d+),(\d+),(\d+)\)',
    ).firstMatch(pasv.raw);
    if (match == null) throw const FormatException('Réponse FTP PASV invalide');
    final port = int.parse(match.group(5)!) * 256 + int.parse(match.group(6)!);
    return Socket.connect(_host, port, timeout: const Duration(seconds: 10));
  }

  Future<String> _readData(Socket socket) async {
    final bytes = <int>[];
    await for (final chunk in socket.timeout(const Duration(seconds: 45))) {
      bytes.addAll(chunk);
    }
    socket.destroy();
    return utf8.decode(bytes, allowMalformed: true);
  }

  Future<_FtpResponse> _command(String command) async {
    _socket.write('$command\r\n');
    await _socket.flush();
    return _reader.read().timeout(const Duration(seconds: 15));
  }

  void _expect(_FtpResponse response, Set<int> accepted) {
    if (!accepted.contains(response.code)) {
      throw FileSystemException('Réponse FTP inattendue (${response.code})');
    }
  }

  Future<void> close() async {
    try {
      await _command('QUIT');
    } catch (_) {
      // The connection may already have been closed by the server.
    } finally {
      await _reader.cancel();
      _socket.destroy();
    }
  }
}

class _FtpResponseReader {
  _FtpResponseReader(Socket socket) : _iterator = StreamIterator(socket);

  final StreamIterator<List<int>> _iterator;
  final List<int> _buffer = [];

  Future<void> cancel() => _iterator.cancel();

  Future<_FtpResponse> read() async {
    final first = await _readLine();
    if (first.length < 3) throw const FormatException('Réponse FTP invalide');
    final code = int.tryParse(first.substring(0, 3));
    if (code == null) throw const FormatException('Réponse FTP invalide');
    final lines = [first];
    if (first.length > 3 && first[3] == '-') {
      while (true) {
        final line = await _readLine();
        lines.add(line);
        if (line.startsWith('$code ')) break;
      }
    }
    return _FtpResponse(code, lines.join('\n'));
  }

  Future<String> _readLine() async {
    while (true) {
      final newline = _buffer.indexOf(10);
      if (newline >= 0) {
        final line = utf8
            .decode(
              _buffer.sublist(0, newline),
              allowMalformed: true,
            )
            .trim();
        _buffer.removeRange(0, newline + 1);
        return line;
      }
      if (!await _iterator.moveNext()) {
        throw const SocketException('Connexion FTP interrompue');
      }
      _buffer.addAll(_iterator.current);
    }
  }
}

class _FtpResponse {
  const _FtpResponse(this.code, this.raw);

  final int code;
  final String raw;

  String get message => raw.length > 4 ? raw.substring(4) : '';
}
