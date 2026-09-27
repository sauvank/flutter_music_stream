import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/remote_audio_entry.dart';
import 'library_provider.dart';

class DownloadQueueProvider extends ChangeNotifier {
  DownloadQueueProvider(this._library);

  static const group = 'musicstream_audio';
  final LibraryProvider _library;
  final FileDownloader _downloader = FileDownloader();
  final Set<String> _processing = {};
  List<TaskRecord> _records = const [];
  Future<void> _importChain = Future.value();

  List<TaskRecord> get records => List.unmodifiable(_records);
  int get activeCount =>
      _records.where((record) => record.status.isNotFinalState).length;

  Future<void> initialize() async {
    _downloader.registerCallbacks(
      group: group,
      taskStatusCallback: _onStatus,
      taskProgressCallback: (_) => _reload(),
    );
    _downloader.configureNotificationForGroup(
      group,
      running: const TaskNotification(
        'Téléchargement de musique',
        '{numFinished} / {numTotal} · {progress}',
      ),
      complete: const TaskNotification(
        'Téléchargement terminé',
        '{numFinished} morceau(x) disponible(s) hors ligne',
      ),
      error: const TaskNotification(
        'Téléchargement incomplet',
        '{numFailed} échec(s) sur {numTotal}',
      ),
      paused: const TaskNotification(
        'Téléchargement en pause',
        '{numFinished} / {numTotal}',
      ),
      progressBar: true,
      groupNotificationId: group,
    );
    await _downloader.start();
    await _reload();
    for (final record in _records) {
      if (record.status == TaskStatus.complete) _scheduleImport(record.task);
    }
  }

  Future<int> enqueueAll(
    List<RemoteAudioEntry> files, {
    Map<String, String> headers = const {},
  }) async {
    await _downloader.permissions.request(PermissionType.notifications);
    final records = await _downloader.database.allRecords(group: group);
    final activeUrls = records
        .where((record) => record.status.isNotFinalState)
        .map((record) => record.task.url)
        .toSet();
    var enqueued = 0;
    for (final file in files) {
      if (activeUrls.contains(file.uri.toString())) continue;
      final extension = p.extension(file.name).toLowerCase();
      final digest =
          sha256.convert(utf8.encode(file.uri.toString())).toString();
      final task = DownloadTask(
        url: file.uri.toString(),
        filename: '${digest.substring(0, 24)}$extension',
        directory: 'background_downloads',
        baseDirectory: BaseDirectory.applicationDocuments,
        headers: headers,
        group: group,
        updates: Updates.statusAndProgress,
        retries: 3,
        allowPause: true,
        displayName: file.name,
        metaData: jsonEncode({'originalName': file.name}),
      );
      if (await _downloader.enqueue(task)) {
        enqueued++;
        activeUrls.add(file.uri.toString());
      }
    }
    await _reload();
    return enqueued;
  }

  Future<void> cancel(String taskId) async {
    await _downloader.cancelTaskWithId(taskId);
    await _reload();
  }

  Future<void> pause(String taskId) async {
    final record = _records.where((item) => item.taskId == taskId).firstOrNull;
    final task = record?.task;
    if (task is DownloadTask) await _downloader.pause(task);
    await _reload();
  }

  Future<void> resume(String taskId) async {
    final record = _records.where((item) => item.taskId == taskId).firstOrNull;
    final task = record?.task;
    if (task is DownloadTask) await _downloader.resume(task);
    await _reload();
  }

  Future<void> retry(String taskId) async {
    final record = _records.where((item) => item.taskId == taskId).firstOrNull;
    final task = record?.task;
    if (task is! DownloadTask) return;
    final retry = DownloadTask(
      url: task.url,
      filename: task.filename,
      headers: task.headers,
      httpRequestMethod: task.httpRequestMethod,
      post: task.post,
      directory: task.directory,
      baseDirectory: task.baseDirectory,
      group: task.group,
      updates: task.updates,
      requiresWiFi: task.requiresWiFi,
      retries: task.retries,
      allowPause: task.allowPause,
      priority: task.priority,
      metaData: task.metaData,
      displayName: task.displayName,
    );
    await _downloader.enqueue(retry);
    await _reload();
  }

  void _onStatus(TaskStatusUpdate update) {
    _reload();
    if (update.status == TaskStatus.complete) _scheduleImport(update.task);
  }

  void _scheduleImport(Task task) {
    if (!_processing.add(task.taskId)) return;
    _importChain = _importChain.then((_) => _import(task)).whenComplete(() {
      _processing.remove(task.taskId);
    });
  }

  Future<void> _import(Task task) async {
    final path = await task.filePath();
    if (!await File(path).exists()) return;
    var originalName = task.displayName;
    try {
      final metadata = jsonDecode(task.metaData) as Map<String, dynamic>;
      originalName = metadata['originalName'] as String? ?? originalName;
    } catch (_) {
      // Older queued tasks can safely use their display name.
    }
    try {
      await _library.importDownloadedFile(
        sourcePath: path,
        originalName: originalName,
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to index background download: $error\n$stackTrace');
    }
    await _reload();
  }

  Future<void> _reload() async {
    _records = await _downloader.database.allRecords(group: group);
    _records.sort((a, b) => b.task.creationTime.compareTo(a.task.creationTime));
    notifyListeners();
  }
}
