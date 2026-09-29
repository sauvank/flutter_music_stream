import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'library_service.dart';

/// Lists the audio files already present in the phone's shared storage.
///
/// Android only exposes other apps' media by path with READ_MEDIA_AUDIO
/// (READ_EXTERNAL_STORAGE up to Android 12); callers check it first.
class DeviceMediaService {
  DeviceMediaService({Future<Directory?> Function()? storageRoot})
      : _storageRoot = storageRoot ?? _defaultStorageRoot;

  final Future<Directory?> Function() _storageRoot;

  static Future<Directory?> _defaultStorageRoot() async {
    if (!Platform.isAndroid) return null;
    // The app-specific directory sits below the shared storage root:
    // <root>/Android/data/<package>/files.
    final appDirectory = await getExternalStorageDirectory();
    if (appDirectory == null) return null;
    final marker = '${p.separator}Android${p.separator}';
    final index = appDirectory.path.indexOf(marker);
    return index <= 0 ? null : Directory(appDirectory.path.substring(0, index));
  }

  /// Walks the tree one directory at a time so an unreadable folder is
  /// skipped instead of aborting the scan. App-private `Android/` data and
  /// hidden folders (thumbnails, trash) are ignored.
  Future<List<File>> listAudioFiles() async {
    final root = await _storageRoot();
    if (root == null || !await root.exists()) return const [];
    final files = <File>[];
    final pending = <Directory>[root];
    while (pending.isNotEmpty) {
      final directory = pending.removeLast();
      try {
        await for (final entity in directory.list(followLinks: false)) {
          final name = p.basename(entity.path);
          if (name.startsWith('.')) continue;
          if (entity is Directory) {
            if (directory.path == root.path && name == 'Android') continue;
            pending.add(entity);
          } else if (entity is File &&
              LibraryService.supportedExtensions.contains(
                p.extension(name).replaceFirst('.', '').toLowerCase(),
              )) {
            files.add(entity);
          }
        }
      } on FileSystemException {
        // Unreadable folder: keep scanning the rest.
      }
    }
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }
}
