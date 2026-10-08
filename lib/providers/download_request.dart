import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/remote_audio_entry.dart';
import '../models/server_profile.dart';
import '../services/remote_server_service.dart';
import 'library_provider.dart';

enum DownloadRequestStage { scanning, queueing, transferring, complete, failed }

/// Owns preparation independently of the screen/selected server. Credentials
/// stay in memory; only the native HTTP queue persists accepted transfers.
class DownloadRequest extends ChangeNotifier {
  DownloadRequest({
    required this.entry,
    required this.profile,
    required Future<String> Function() password,
    required RemoteServerService remote,
    required LibraryProvider library,
    required Future<int> Function(List<RemoteAudioEntry>, Map<String, String>)
        enqueue,
  })  : _password = password,
        _remote = remote,
        _library = library,
        _enqueue = enqueue;

  final RemoteAudioEntry entry;
  final ServerProfile profile;
  final Future<String> Function() _password;
  final RemoteServerService _remote;
  final LibraryProvider _library;
  final Future<int> Function(List<RemoteAudioEntry>, Map<String, String>)
      _enqueue;
  DownloadRequestStage stage = DownloadRequestStage.scanning;
  Object? error;
  int total = 0;
  int added = 0;
  int skipped = 0;
  int failed = 0;
  String? currentFile;
  double? progress;
  Timer? _progressTimer;
  bool _running = false;

  bool get active =>
      stage != DownloadRequestStage.complete &&
      stage != DownloadRequestStage.failed;
  String get id => '${profile.id}:${entry.uri}';

  Future<void> run() async {
    if (_running) return;
    _running = true;
    error = null;
    added = skipped = failed = total = 0;
    progress = null;
    stage = DownloadRequestStage.scanning;
    notifyListeners();
    try {
      final password = await _password();
      final files = entry.isDirectory
          ? await _remote.listRecursively(profile, entry.uri, password)
          : [entry];
      total = files.length;
      stage = profile.type == ServerType.ftp
          ? DownloadRequestStage.transferring
          : DownloadRequestStage.queueing;
      notifyListeners();
      if (profile.type == ServerType.ftp) {
        await _downloadFtp(files, password);
      } else if (files.isNotEmpty) {
        added = await _enqueue(
            files, _remote.authorizationHeaders(profile, password));
      }
      stage = DownloadRequestStage.complete;
      progress = 1;
    } catch (e) {
      error = e;
      stage = DownloadRequestStage.failed;
    } finally {
      _progressTimer?.cancel();
      _progressTimer = null;
      _running = false;
      notifyListeners();
    }
  }

  Future<void> _downloadFtp(
      List<RemoteAudioEntry> files, String password) async {
    final directory =
        await (await getTemporaryDirectory()).createTemp('musicstream-ftp-');
    try {
      for (var index = 0; index < files.length; index++) {
        final file = files[index];
        if (_library.downloadedSourceUris.contains(file.uri.toString())) {
          skipped++;
          continue;
        }
        currentFile = file.name;
        progress = index / files.length;
        notifyListeners();
        final temporary =
            File(p.join(directory.path, '$index${p.extension(file.name)}'));
        try {
          await _remote.downloadFtp(profile, file, password, temporary.path,
              onProgress: (received, size) {
            progress =
                (index + (size > 0 ? received / size : 0)) / files.length;
            _progressTimer ??= Timer(const Duration(milliseconds: 300), () {
              _progressTimer = null;
              notifyListeners();
            });
          });
          final imported = await _library.importDownloadedFile(
              sourcePath: temporary.path,
              originalName: file.name,
              sourceUri: file.uri.toString());
          imported ? added++ : skipped++;
        } catch (_) {
          failed++;
        } finally {
          if (await temporary.exists()) await temporary.delete();
        }
        progress = (index + 1) / files.length;
        notifyListeners();
      }
    } finally {
      await directory.delete(recursive: true);
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }
}
