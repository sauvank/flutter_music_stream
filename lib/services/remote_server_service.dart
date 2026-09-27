import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../models/remote_audio_entry.dart';
import '../models/server_profile.dart';
import 'library_service.dart';
import 'ftp_service.dart';

class RemoteServerService {
  RemoteServerService({Dio? dio, FtpService? ftpService})
      : _dio = dio ?? Dio(),
        _ftpService = ftpService ?? FtpService();
  final Dio _dio;
  final FtpService _ftpService;

  Future<List<RemoteAudioEntry>> list(
    ServerProfile profile,
    Uri uri,
    String password,
  ) =>
      switch (profile.type) {
        ServerType.webdav => _listWebDav(profile, uri, password),
        ServerType.http => _listHttp(profile, uri, password),
        ServerType.ftp => _ftpService.list(profile, uri, password),
      };

  Future<void> downloadFtp(
    ServerProfile profile,
    RemoteAudioEntry entry,
    String password,
    String destinationPath, {
    void Function(int received, int total)? onProgress,
  }) =>
      _ftpService.download(
        profile,
        entry.uri,
        password,
        destinationPath,
        onProgress: onProgress,
      );

  Future<List<RemoteAudioEntry>> listRecursively(
    ServerProfile profile,
    Uri root,
    String password, {
    int maximumEntries = 10000,
  }) async {
    final files = <RemoteAudioEntry>[];
    final pending = <Uri>[root];
    final visited = <String>{};
    while (pending.isNotEmpty) {
      final directory = pending.removeLast();
      final key = directory.replace(query: '', fragment: '').toString();
      if (!visited.add(key)) continue;
      final children = await list(profile, directory, password);
      for (final child in children) {
        if (child.isDirectory) {
          pending.add(child.uri);
        } else {
          files.add(child);
          if (files.length >= maximumEntries) {
            throw StateError('Le dossier contient trop de morceaux.');
          }
        }
      }
    }
    return files;
  }

  Map<String, String> authorizationHeaders(
    ServerProfile profile,
    String password,
  ) {
    if (profile.username.isEmpty) return const {};
    return {
      'Authorization':
          'Basic ${base64Encode(utf8.encode('${profile.username}:$password'))}',
    };
  }

  Future<List<RemoteAudioEntry>> _listWebDav(
    ServerProfile profile,
    Uri uri,
    String password,
  ) async {
    final response = await _dio.request<String>(
      uri.toString(),
      options: Options(
        method: 'PROPFIND',
        responseType: ResponseType.plain,
        headers: {
          ...authorizationHeaders(profile, password),
          'Depth': '1',
          'Content-Type': 'application/xml; charset=utf-8',
        },
      ),
      data:
          '<?xml version="1.0"?><propfind xmlns="DAV:"><prop><displayname/><resourcetype/><getcontentlength/></prop></propfind>',
    );
    final document = XmlDocument.parse(response.data ?? '');
    final entries = <RemoteAudioEntry>[];
    for (final node in document.descendants.whereType<XmlElement>().where(
          (element) => element.name.local == 'response',
        )) {
      final href = _firstLocal(node, 'href')?.innerText.trim();
      if (href == null || href.isEmpty) continue;
      final resolved = uri.resolve(href);
      if (_sameResource(resolved, uri)) continue;
      final isDirectory = node.descendants
          .whereType<XmlElement>()
          .any((element) => element.name.local == 'collection');
      final displayName = _firstLocal(node, 'displayname')?.innerText.trim();
      final name = displayName == null || displayName.isEmpty
          ? _nameFromUri(resolved)
          : displayName;
      if (!isDirectory && !_isAudio(name)) continue;
      entries.add(RemoteAudioEntry(
        name: name,
        uri: resolved,
        isDirectory: isDirectory,
        size: int.tryParse(
          _firstLocal(node, 'getcontentlength')?.innerText.trim() ?? '',
        ),
      ));
    }
    return _sorted(entries);
  }

  Future<List<RemoteAudioEntry>> _listHttp(
    ServerProfile profile,
    Uri uri,
    String password,
  ) async {
    final response = await _dio.get<String>(
      uri.toString(),
      options: Options(
        responseType: ResponseType.plain,
        headers: authorizationHeaders(profile, password),
      ),
    );
    final body = response.data ?? '';
    try {
      final decoded = jsonDecode(body);
      final values =
          decoded is List ? decoded : (decoded as Map)['files'] as List;
      return _sorted(values
          .map((value) {
            final item = (value as Map).cast<String, Object?>();
            final name = item['name']! as String;
            final isDirectory = item['isDirectory'] as bool? ?? false;
            return RemoteAudioEntry(
              name: name,
              uri: uri.resolve(item['url'] as String? ?? name),
              isDirectory: isDirectory,
              size: item['size'] as int?,
            );
          })
          .where((entry) => entry.isDirectory || _isAudio(entry.name))
          .toList());
    } on FormatException {
      return _parseAutoIndex(uri, body);
    } on TypeError {
      return _parseAutoIndex(uri, body);
    }
  }

  List<RemoteAudioEntry> _parseAutoIndex(Uri base, String html) {
    final link = RegExp('href=["\\\']([^"\\\']+)["\\\']', caseSensitive: false);
    final seen = <String>{};
    final entries = <RemoteAudioEntry>[];
    for (final match in link.allMatches(html)) {
      final href = match.group(1)!;
      if (href.startsWith('?') || href.startsWith('#') || href == '../') {
        continue;
      }
      final resolved = base.resolve(href);
      if (!seen.add(resolved.toString()) || _sameResource(resolved, base)) {
        continue;
      }
      final isDirectory = href.endsWith('/');
      final name = _nameFromUri(resolved);
      if (isDirectory || _isAudio(name)) {
        entries.add(RemoteAudioEntry(
            name: name, uri: resolved, isDirectory: isDirectory));
      }
    }
    return _sorted(entries);
  }

  XmlElement? _firstLocal(XmlElement root, String name) {
    for (final element in root.descendants.whereType<XmlElement>()) {
      if (element.name.local == name) return element;
    }
    return null;
  }

  bool _isAudio(String name) => LibraryService.supportedExtensions
      .contains(p.extension(name).replaceFirst('.', '').toLowerCase());

  String _nameFromUri(Uri uri) {
    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty);
    return segments.isEmpty ? uri.host : Uri.decodeComponent(segments.last);
  }

  bool _sameResource(Uri left, Uri right) =>
      left
          .replace(query: '', fragment: '')
          .toString()
          .replaceAll(RegExp(r'/+$'), '') ==
      right
          .replace(query: '', fragment: '')
          .toString()
          .replaceAll(RegExp(r'/+$'), '');

  List<RemoteAudioEntry> _sorted(List<RemoteAudioEntry> entries) => entries
    ..sort((left, right) {
      if (left.isDirectory != right.isDirectory) {
        return left.isDirectory ? -1 : 1;
      }
      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });
}
