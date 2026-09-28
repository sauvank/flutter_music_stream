import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/music_track.dart';
import 'audio_metadata_service.dart';
import 'lyrics_service.dart';

typedef ImportProgressCallback = void Function(int completed, int total);
typedef LocalImportResult = ({List<MusicTrack> tracks, int failed});

class LibraryService {
  LibraryService(
      {AudioMetadataService? metadataService,
      LyricsService? lyricsService,
      Future<Directory> Function()? documentsDirectory})
      : _metadataService = metadataService ?? const AudioMetadataService(),
        _lyricsService = lyricsService ?? LyricsService.shared,
        _documentsDirectory =
            documentsDirectory ?? getApplicationDocumentsDirectory;

  static const _libraryKey = 'music_library_v1';
  static const _positionsKey = 'music_positions_v1';
  static const _sortKey = 'library_sort_v1';
  static const supportedExtensions = <String>[
    'mp3',
    'm4a',
    'aac',
    'flac',
    'ogg',
    'opus',
    'wav'
  ];
  final AudioMetadataService _metadataService;
  final LyricsService _lyricsService;
  final Future<Directory> Function() _documentsDirectory;
  Future<void> _saveChain = Future.value();
  final Map<String, int> _positions = {};

  Future<void> deleteTrackFiles(MusicTrack track) async {
    final root = await _documentsDirectory();
    final musicDirectory = p.normalize(p.join(root.path, 'music'));
    final audioUri = Uri.parse(track.uri);
    if (audioUri.scheme != 'file' ||
        p.dirname(p.normalize(audioUri.toFilePath())) != musicDirectory) {
      throw StateError(
          'Le morceau ne se trouve pas dans le stockage de l’application.');
    }
    final audio = File.fromUri(audioUri);
    if (await audio.exists()) await audio.delete();

    final artworkUri = Uri.tryParse(track.artworkUri ?? '');
    if (artworkUri?.scheme == 'file' &&
        p.dirname(p.normalize(artworkUri!.toFilePath())) ==
            p.normalize(p.join(root.path, 'artwork'))) {
      final artwork = File.fromUri(artworkUri);
      if (await artwork.exists()) await artwork.delete();
    }
    await _lyricsService.delete(track.id);
  }

  Future<List<MusicTrack>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final serialized = preferences.getString(_libraryKey);
    if (serialized == null || serialized.isEmpty) return [];
    try {
      final tracks = serialized.length > 50000
          ? await compute(MusicTrack.decodeAll, serialized)
          : MusicTrack.decodeAll(serialized);
      _positions
        ..clear()
        ..addAll(_decodePositions(preferences.getString(_positionsKey)));
      if (_positions.isNotEmpty) {
        for (var index = 0; index < tracks.length; index++) {
          final position = _positions[tracks[index].id];
          if (position != null) {
            tracks[index] = tracks[index].copyWith(lastPositionMs: position);
          }
        }
      }
      var changed = false;
      for (var index = 0; index < tracks.length; index++) {
        if (tracks[index].metadataRead) continue;
        tracks[index] = await _readMetadata(tracks[index]);
        changed = true;
      }
      if (changed) await save(tracks);
      return tracks;
    } on FormatException {
      return [];
    }
  }

  Future<String?> loadSort() async =>
      (await SharedPreferences.getInstance()).getString(_sortKey);

  Future<void> saveSort(String value) async =>
      (await SharedPreferences.getInstance()).setString(_sortKey, value);

  Future<void> save(List<MusicTrack> tracks) {
    final snapshot = List<MusicTrack>.of(tracks);
    final result = _saveChain.then((_) => _write(snapshot));
    _saveChain = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// Persists a playback position without re-encoding the whole library.
  ///
  /// Positions live in a small side table that is folded back into the index
  /// on load and cleared by the next full [save], whose snapshot is newer.
  Future<void> savePosition(String id, int positionMs) {
    final result = _saveChain.then((_) async {
      _positions[id] = positionMs;
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_positionsKey, jsonEncode(_positions));
    });
    _saveChain = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<void> _write(List<MusicTrack> tracks) async {
    final preferences = await SharedPreferences.getInstance();
    final serialized = tracks.length > 100
        ? await compute(MusicTrack.encodeAll, tracks)
        : MusicTrack.encodeAll(tracks);
    await preferences.setString(_libraryKey, serialized);
    if (_positions.isNotEmpty || preferences.containsKey(_positionsKey)) {
      _positions.clear();
      await preferences.remove(_positionsKey);
    }
  }

  static Map<String, int> _decodePositions(String? value) {
    if (value == null || value.isEmpty) return const {};
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return const {};
      return {
        for (final entry in decoded.entries)
          if (entry.key is String && entry.value is int)
            entry.key as String: entry.value as int,
      };
    } on FormatException {
      return const {};
    }
  }

  Future<LocalImportResult?> pickAndImport({
    ImportProgressCallback? onProgress,
  }) async {
    final selection = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [...supportedExtensions, 'lrc'],
    );
    if (selection == null) return null;
    final selected = selection.files.where((picked) => picked.path != null);
    final sidecars = {
      for (final picked in selected)
        if (p.extension(picked.name).toLowerCase() == '.lrc')
          p.basenameWithoutExtension(picked.name).toLowerCase():
              File(picked.path!),
    };
    return _importSources(
        selected
            .where((picked) => supportedExtensions.contains(
                p.extension(picked.name).replaceFirst('.', '').toLowerCase()))
            .map((picked) => (
                  path: picked.path!,
                  name: picked.name,
                  sidecar: sidecars[
                      p.basenameWithoutExtension(picked.name).toLowerCase()],
                )),
        onProgress: onProgress);
  }

  Future<LocalImportResult?> pickDirectoryAndImport({
    ImportProgressCallback? onProgress,
  }) async {
    final selectedPath = await FilePicker.getDirectoryPath(
      dialogTitle: 'Choisir un dossier de musique',
    );
    if (selectedPath == null) return null;
    final directory = Directory(selectedPath);
    if (!await directory.exists()) return null;
    final files = <File>[];
    final sidecars = <String, File>{};
    await for (final entity
        in directory.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final extension =
          p.extension(entity.path).replaceFirst('.', '').toLowerCase();
      if (extension == 'lrc') {
        sidecars[p.withoutExtension(entity.path).toLowerCase()] = entity;
      } else if (supportedExtensions.contains(extension)) {
        files.add(entity);
      }
    }
    final sources = files
        .map((file) => (
              path: file.path,
              name: p.basename(file.path),
              sidecar: sidecars[p.withoutExtension(file.path).toLowerCase()],
            ))
        .toList();
    sources.sort((a, b) => a.path.compareTo(b.path));
    return _importSources(sources, onProgress: onProgress);
  }

  Future<LocalImportResult> _importSources(
    Iterable<({String path, String name, File? sidecar})> sources, {
    ImportProgressCallback? onProgress,
  }) async {
    final items = sources.toList();
    final root = await getApplicationDocumentsDirectory();
    final musicDirectory = Directory(p.join(root.path, 'music'));
    await musicDirectory.create(recursive: true);
    final imported = <MusicTrack>[];
    var failed = 0;
    onProgress?.call(0, items.length);
    for (var index = 0; index < items.length; index++) {
      try {
        imported.add(await _importSource(items[index], musicDirectory));
      } catch (error) {
        // One unreadable file must not abort the rest of the selection.
        failed++;
        debugPrint('Local import failed: ${error.runtimeType}');
      }
      onProgress?.call(index + 1, items.length);
    }
    return (tracks: imported, failed: failed);
  }

  Future<MusicTrack> _importSource(
    ({String path, String name, File? sidecar}) item,
    Directory musicDirectory,
  ) async {
    final source = File(item.path);
    final id = (await sha256.bind(source.openRead()).first).toString();
    final safeName =
        '${id.substring(0, 16)}${p.extension(item.name).toLowerCase()}';
    final destination = File(p.join(musicDirectory.path, safeName));
    if (!await destination.exists()) await source.copy(destination.path);
    if (item.sidecar != null) {
      try {
        await _lyricsService.importSidecar(id, item.sidecar!);
      } on FileSystemException {
        // A missing or unreadable sidecar must not prevent audio import.
      } on FormatException {
        // Invalid lyrics do not prevent audio import.
      }
    }
    return _readMetadata(MusicTrack(
      id: id,
      title: _titleFromFilename(item.name),
      uri: destination.uri.toString(),
      addedAt: DateTime.now().toUtc(),
      source: MusicSource.localImport,
    ));
  }

  Future<MusicTrack> importRemote({
    required String name,
    required Uri uri,
    Map<String, String> headers = const {},
  }) async {
    final root = await getApplicationDocumentsDirectory();
    final musicDirectory = Directory(p.join(root.path, 'music'));
    await musicDirectory.create(recursive: true);
    final temporary = File(p.join(
      musicDirectory.path,
      '.download-${DateTime.now().microsecondsSinceEpoch}',
    ));
    try {
      await Dio().download(
        uri.toString(),
        temporary.path,
        options: Options(headers: headers),
      );
      final id = (await sha256.bind(temporary.openRead()).first).toString();
      final extension = p.extension(name).toLowerCase();
      final destination = File(
        p.join(musicDirectory.path, '${id.substring(0, 16)}$extension'),
      );
      if (await destination.exists()) {
        await temporary.delete();
      } else {
        await temporary.rename(destination.path);
      }
      return _readMetadata(MusicTrack(
        id: id,
        title: _titleFromFilename(name),
        uri: destination.uri.toString(),
        addedAt: DateTime.now().toUtc(),
        source: MusicSource.serverDownload,
        sourceUri: uri.toString(),
      ));
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  Future<MusicTrack> importDownloadedFile({
    required String sourcePath,
    required String originalName,
    String? sourceUri,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException(
          'Le fichier téléchargé est introuvable.', sourcePath);
    }
    final id = (await sha256.bind(source.openRead()).first).toString();
    final root = await getApplicationDocumentsDirectory();
    final musicDirectory = Directory(p.join(root.path, 'music'));
    await musicDirectory.create(recursive: true);
    final extension = p.extension(originalName).toLowerCase();
    final destination = File(
      p.join(musicDirectory.path, '${id.substring(0, 16)}$extension'),
    );
    if (await destination.exists()) {
      await source.delete();
    } else {
      try {
        await source.rename(destination.path);
      } on FileSystemException {
        await source.copy(destination.path);
        await source.delete();
      }
    }
    return _readMetadata(MusicTrack(
      id: id,
      title: _titleFromFilename(originalName),
      uri: destination.uri.toString(),
      addedAt: DateTime.now().toUtc(),
      source: MusicSource.serverDownload,
      sourceUri: sourceUri,
    ));
  }

  String _titleFromFilename(String name) {
    final base = p.basenameWithoutExtension(name).replaceAll('_', ' ');
    return base.trim().isEmpty ? 'Piste sans titre' : base.trim();
  }

  Future<MusicTrack> _readMetadata(MusicTrack track) async {
    try {
      final file = File.fromUri(Uri.parse(track.uri));
      if (!await file.exists()) return _withMetadataRead(track);
      final metadata = await _metadataService.read(file.path);
      final artworkUri = await _saveArtwork(track.id, metadata);
      return MusicTrack(
        id: track.id,
        title: metadata.title ?? track.title,
        artist: metadata.artist ?? track.artist,
        album: metadata.album ?? track.album,
        genre: metadata.genre ?? track.genre,
        artworkUri: artworkUri ?? track.artworkUri,
        trackNumber: metadata.trackNumber ?? track.trackNumber,
        discNumber: metadata.discNumber ?? track.discNumber,
        uri: track.uri,
        durationMs: metadata.durationMs ?? track.durationMs,
        favorite: track.favorite,
        lastPositionMs: track.lastPositionMs,
        lastPlayedAt: track.lastPlayedAt,
        playCount: track.playCount,
        metadataRead: true,
        source: track.source,
        sourceUri: track.sourceUri,
        addedAt: track.addedAt,
      );
    } catch (_) {
      // A malformed or unsupported tag must never prevent importing its audio.
      return _withMetadataRead(track);
    }
  }

  Future<String?> _saveArtwork(String trackId, AudioMetadata metadata) async {
    final bytes = metadata.artworkBytes;
    if (bytes == null || bytes.isEmpty) return null;
    final root = await getApplicationDocumentsDirectory();
    final artworkDirectory = Directory(p.join(root.path, 'artwork'));
    await artworkDirectory.create(recursive: true);
    final artwork = File(p.join(
      artworkDirectory.path,
      '$trackId.${metadata.artworkExtension ?? 'jpg'}',
    ));
    await artwork.writeAsBytes(bytes, flush: true);
    return artwork.uri.toString();
  }

  MusicTrack _withMetadataRead(MusicTrack track) => MusicTrack(
        id: track.id,
        title: track.title,
        artist: track.artist,
        album: track.album,
        genre: track.genre,
        artworkUri: track.artworkUri,
        trackNumber: track.trackNumber,
        discNumber: track.discNumber,
        uri: track.uri,
        durationMs: track.durationMs,
        favorite: track.favorite,
        lastPositionMs: track.lastPositionMs,
        lastPlayedAt: track.lastPlayedAt,
        playCount: track.playCount,
        metadataRead: true,
        source: track.source,
        sourceUri: track.sourceUri,
        addedAt: track.addedAt,
      );
}
