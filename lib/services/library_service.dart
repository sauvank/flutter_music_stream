import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/music_track.dart';

class LibraryService {
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

  Future<List<MusicTrack>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final serialized = preferences.getString(_libraryKey);
    if (serialized == null || serialized.isEmpty) return [];
    try {
      return MusicTrack.decodeAll(serialized);
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
      imported.add(MusicTrack(
        id: id,
        title: _titleFromFilename(picked.name),
        uri: destination.uri.toString(),
        addedAt: DateTime.now().toUtc(),
      ));
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
      return MusicTrack(
        id: id,
        title: _titleFromFilename(name),
        uri: destination.uri.toString(),
        addedAt: DateTime.now().toUtc(),
      );
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  String _titleFromFilename(String name) {
    final base = p.basenameWithoutExtension(name).replaceAll('_', ' ');
    return base.trim().isEmpty ? 'Piste sans titre' : base.trim();
  }
}
