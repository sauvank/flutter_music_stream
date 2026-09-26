import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/music_track.dart';
import 'audio_metadata_service.dart';

class LibraryService {
  LibraryService({AudioMetadataService? metadataService})
      : _metadataService = metadataService ?? const AudioMetadataService();

  static const _libraryKey = 'music_library_v1';
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

  Future<List<MusicTrack>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final serialized = preferences.getString(_libraryKey);
    if (serialized == null || serialized.isEmpty) return [];
    try {
      final tracks = MusicTrack.decodeAll(serialized);
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

  Future<void> save(List<MusicTrack> tracks) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_libraryKey, MusicTrack.encodeAll(tracks));
  }

  Future<List<MusicTrack>> pickAndImport() async {
    final selection = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: supportedExtensions,
    );
    if (selection == null) return [];
    final root = await getApplicationDocumentsDirectory();
    final musicDirectory = Directory(p.join(root.path, 'music'));
    await musicDirectory.create(recursive: true);
    final imported = <MusicTrack>[];
    for (final picked in selection.files) {
      final sourcePath = picked.path;
      if (sourcePath == null) continue;
      final source = File(sourcePath);
      final id = (await sha256.bind(source.openRead()).first).toString();
      final safeName =
          '${id.substring(0, 16)}${p.extension(picked.name).toLowerCase()}';
      final destination = File(p.join(musicDirectory.path, safeName));
      if (!await destination.exists()) await source.copy(destination.path);
      imported.add(await _readMetadata(MusicTrack(
        id: id,
        title: _titleFromFilename(picked.name),
        uri: destination.uri.toString(),
        addedAt: DateTime.now().toUtc(),
      )));
    }
    return imported;
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
      ));
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
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
        metadataRead: true,
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
        metadataRead: true,
        addedAt: track.addedAt,
      );
}
