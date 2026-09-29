import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/remote_audio_entry.dart';

class RemoteAlbumUpdate {
  const RemoteAlbumUpdate({required this.name, required this.trackCount});

  final String name;
  final int trackCount;
}

class ServerScanResult {
  const ServerScanResult({
    required this.baselineCreated,
    required this.totalTracks,
    required this.newAlbums,
  });

  final bool baselineCreated;
  final int totalTracks;
  final List<RemoteAlbumUpdate> newAlbums;

  int get newTrackCount => newAlbums.fold(
        0,
        (total, album) => total + album.trackCount,
      );
}

class ServerScanService {
  static const _keyPrefix = 'server_scan_snapshot_v1_';

  /// Stored name for files at the server root; translated when displayed.
  static const rootAlbumName = 'Racine du serveur';

  Future<ServerScanResult> compareAndSave(
    String profileId,
    List<RemoteAudioEntry> files,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$profileId';
    final previousValue = preferences.getString(key);
    final previous = _decodeSnapshot(previousValue);
    final fingerprints = <String>{};
    final newByAlbum = <String, int>{};
    for (final file in files.where((entry) => !entry.isDirectory)) {
      final fingerprint = _fingerprint(file.uri);
      fingerprints.add(fingerprint);
      if (previous != null && !previous.contains(fingerprint)) {
        final album = _albumName(file.uri);
        newByAlbum[album] = (newByAlbum[album] ?? 0) + 1;
      }
    }
    await preferences.setString(key, jsonEncode(fingerprints.toList()..sort()));
    final albums = newByAlbum.entries
        .map(
          (entry) => RemoteAlbumUpdate(
            name: entry.key,
            trackCount: entry.value,
          ),
        )
        .toList()
      ..sort((left, right) => left.name.compareTo(right.name));
    return ServerScanResult(
      baselineCreated: previous == null,
      totalTracks: fingerprints.length,
      newAlbums: albums,
    );
  }

  Future<void> forget(String profileId) async {
    await (await SharedPreferences.getInstance())
        .remove('$_keyPrefix$profileId');
  }

  Set<String>? _decodeSnapshot(String? value) {
    if (value == null) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List || decoded.any((item) => item is! String)) {
        return null;
      }
      return decoded.cast<String>().toSet();
    } on FormatException {
      return null;
    }
  }

  String _fingerprint(Uri uri) => sha256
      .convert(utf8.encode(uri.replace(query: '', fragment: '').toString()))
      .toString();

  String _albumName(Uri uri) {
    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty);
    final values = segments.toList();
    return values.length >= 2 ? values[values.length - 2] : rootAlbumName;
  }
}
