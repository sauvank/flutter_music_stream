import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/remote_audio_entry.dart';
import '../models/server_profile.dart';
import '../services/remote_server_service.dart';
import '../services/download_queue_refresh.dart';
import 'download_request.dart';
import 'library_provider.dart';
import '../l10n/generated/app_localizations.dart';

class DownloadQueueProvider extends ChangeNotifier {
  DownloadQueueProvider(this._library);

  static const group = 'musicstream_audio';
  final LibraryProvider _library;
  late final FileDownloader _downloader = FileDownloader();
  final Set<String> _processing = {};
  final Map<String, DownloadRequest> _requests = {};
  Future<void> _ftpRequests = Future.value();
  List<TaskRecord> _records = const [];
  Future<void> _importChain = Future.value();
  Future<void> _enqueueChain = Future.value();
  late final _refresh = DownloadQueueRefresh(_reload, onError: (error) {
    debugPrint('Unable to refresh download queue: ${error.runtimeType}');
  });
  Future<void>? _reloadInFlight;
  bool _reloadPending = false;

  List<TaskRecord> get records => List.unmodifiable(_records);
  List<DownloadRequest> get requests => List.unmodifiable(_requests.values);

  bool startRequest(
      {required RemoteAudioEntry entry,
      required ServerProfile profile,
      required Future<String> Function() password,
      required RemoteServerService remote}) {
    final id = '${profile.id}:${entry.uri}';
    if (_requests[id]?.active == true) return false;
    final request = DownloadRequest(
        entry: entry,
        profile: profile,
        password: password,
        remote: remote,
        library: _library,
        enqueue: (files, headers) => enqueueAll(files, headers: headers));
    _requests[id] = request;
    void changed() {
      if (request.stage == DownloadRequestStage.complete &&
          profile.type != ServerType.ftp &&
          request.added > 0) {
        _requests.remove(id);
        request.removeListener(changed);
      }
      notifyListeners();
    }

    request.addListener(changed);
    notifyListeners();
    if (profile.type == ServerType.ftp) {
      _ftpRequests = _ftpRequests.then((_) => request.run());
    } else {
      unawaited(request.run());
    }
    return true;
  }

  void dismissRequest(String id) {
    final request = _requests[id];
    if (request == null || request.active) return;
    _requests.remove(id);
    request.dispose();
    notifyListeners();
  }

  Future<void> retryRequest(DownloadRequest request) async {
    if (request.active) return;
    request.stage = DownloadRequestStage.scanning;
    notifyListeners();
    if (request.profile.type == ServerType.ftp) {
      _ftpRequests = _ftpRequests.then((_) => request.run());
      await _ftpRequests;
    } else {
      await request.run();
    }
  }

  int get activeCount =>
      _records.where((record) => record.status.isNotFinalState).length +
      _requests.values.where((request) => request.active).length;

  bool isImporting(String taskId) => _processing.contains(taskId);

  /// Progress of the unfinished download of [url]: null when none is running,
  /// a value in 0..1 once bytes flow and a negative value while it waits.
  double? activeProgress(String url) {
    for (final record in _records) {
      if (record.task.url != url) continue;
      // A finished transfer is still being imported into the library.
      if (_processing.contains(record.task.taskId)) return 1;
      if (!record.status.isNotFinalState) continue;
      final progress = record.progress;
      return progress > 0 && progress <= 1 ? progress : -1;
    }
    return null;
  }

  /// Runs off the startup path: enqueues wait for it through [_enqueueChain],
  /// and the queue notifies listeners once its records are loaded.
  Future<void> initialize(AppLocalizations l10n) {
    final ready = _initialize(l10n);
    _enqueueChain = ready.catchError((Object _) {});
    return ready;
  }

  Future<void> _initialize(AppLocalizations l10n) async {
    await _downloader.configure(globalConfig: [
      (Config.holdingQueue, (3, 2, 3)),
    ], androidConfig: [
      (Config.runInForeground, Config.always)
    ]);
    _downloader.registerCallbacks(
      group: group,
      taskStatusCallback: _onStatus,
      taskProgressCallback: (_) => _requestReload(),
    );
    configureNotifications(l10n);
    await _downloader.start();
    await _reload();
    for (final record in _records) {
      if (record.status == TaskStatus.complete &&
          !_library.downloadedSourceUris.contains(record.task.url)) {
        _scheduleImport(record.task);
      }
    }
  }

  /// Uses the downloader's own `{numFinished}`-style tokens as arguments so
  /// the translations keep them in place.
  void configureNotifications(AppLocalizations l10n) {
    _downloader.configureNotificationForGroup(
      group,
      running: TaskNotification(
        l10n.notificationRunningTitle,
        '{numFinished} / {numTotal} · {progress}',
      ),
      complete: TaskNotification(
        l10n.notificationCompleteTitle,
        l10n.notificationCompleteBody('{numFinished}'),
      ),
      error: TaskNotification(
        l10n.notificationErrorTitle,
        l10n.notificationErrorBody('{numFailed}', '{numTotal}'),
      ),
      paused: TaskNotification(
        l10n.notificationPausedTitle,
        '{numFinished} / {numTotal}',
      ),
      progressBar: true,
      groupNotificationId: group,
    );
  }

  Future<int> enqueueAll(
    List<RemoteAudioEntry> files, {
    Map<String, String> headers = const {},
  }) =>
      _serializeEnqueue(() => _enqueueAll(files, headers: headers));

  Future<T> _serializeEnqueue<T>(Future<T> Function() action) {
    final result = _enqueueChain.then((_) => action());
    _enqueueChain = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<int> _enqueueAll(
    List<RemoteAudioEntry> files, {
    required Map<String, String> headers,
  }) async {
    await _downloader.permissions.request(PermissionType.notifications);
    final records = await _downloader.database.allRecords(group: group);
    final activeUrls = records
        .where((record) => record.status.isNotFinalState)
        .map((record) => record.task.url)
        .toSet();
    final downloadedUrls = _library.downloadedSourceUris;
    var enqueued = 0;
    for (final file in files) {
      if (activeUrls.contains(file.uri.toString()) ||
          downloadedUrls.contains(file.uri.toString())) {
        continue;
      }
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
    if (task is DownloadTask && !await _downloader.pause(task)) {
      throw StateError('Pause unavailable');
    }
    await _reload();
  }

  Future<void> resume(String taskId) async {
    final record = _records.where((item) => item.taskId == taskId).firstOrNull;
    final task = record?.task;
    if (task is DownloadTask && !await _downloader.resume(task)) {
      throw StateError('Resume unavailable');
    }
    await _reload();
  }

  Future<void> retry(String taskId) => _serializeEnqueue(() => _retry(taskId));

  Future<void> _retry(String taskId) async {
    final record = _records.where((item) => item.taskId == taskId).firstOrNull;
    final task = record?.task;
    if (task is! DownloadTask) return;
    final records = await _downloader.database.allRecords(group: group);
    if (records.any(
        (item) => item.task.url == task.url && item.status.isNotFinalState)) {
      return;
    }
    if (_library.downloadedSourceUris.contains(task.url)) {
      return;
    }
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
    if (!await _downloader.enqueue(retry)) {
      throw StateError('Retry unavailable');
    }
    // The replacement owns this transfer now; don't leave a stale failure
    // behind or show it again in the next bulk retry.
    await _downloader.database.deleteRecordsWithIds([taskId]);
    await _reload();
  }

  bool get hasFailed => _records.any(_isFailed);

  /// Finished records that can be forgotten without losing an import:
  /// completed downloads already in the library, and canceled tasks.
  bool get hasClearable => _records.any(_isClearable);

  static bool _isFailed(TaskRecord record) =>
      record.status == TaskStatus.failed ||
      record.status == TaskStatus.notFound;

  bool _isClearable(TaskRecord record) =>
      record.status == TaskStatus.canceled ||
      (record.status == TaskStatus.complete &&
          _library.downloadedSourceUris.contains(record.task.url));

  Future<void> retryFailed() async {
    for (final record in _records.where(_isFailed).toList()) {
      await retry(record.taskId);
    }
  }

  Future<void> clearFinished() async {
    final ids = _records.where(_isClearable).map((record) => record.taskId);
    if (ids.isEmpty) return;
    await _downloader.database.deleteRecordsWithIds(ids.toList());
    await _reload();
  }

  Future<void> cancelAll() async {
    final ids = _records
        .where((record) => record.status.isNotFinalState)
        .map((record) => record.taskId)
        .toList();
    if (ids.isEmpty) return;
    await _downloader.cancelTasksWithIds(ids);
    await _reload();
  }

  void _onStatus(TaskStatusUpdate update) {
    _requestReload();
    if (update.status == TaskStatus.complete) _scheduleImport(update.task);
  }

  // Thousands of enqueued/status callbacks must not each scan the entire
  // persistent database and rebuild every consumer. Read after writes settle.
  void _requestReload() => _refresh.request();

  void _scheduleImport(Task task) {
    if (_library.downloadedSourceUris.contains(task.url)) return;
    if (!_processing.add(task.taskId)) return;
    notifyListeners();
    _importChain = _importChain.then((_) => _import(task)).whenComplete(() {
      _processing.remove(task.taskId);
      notifyListeners();
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
        sourceUri: task.url,
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to index background download: $error\n$stackTrace');
    }
    _requestReload();
  }

  Future<void> _reload() {
    if (_reloadInFlight != null) {
      _reloadPending = true;
      return _reloadInFlight!;
    }
    final reload = _performReload();
    _reloadInFlight = reload;
    return reload;
  }

  Future<void> _performReload() async {
    try {
      do {
        _reloadPending = false;
        final records = await _downloader.database.allRecords(group: group);
        records.sort(
          (a, b) => b.task.creationTime.compareTo(a.task.creationTime),
        );
        _records = records;
        notifyListeners();
      } while (_reloadPending);
    } finally {
      _reloadInFlight = null;
    }
  }

  @override
  void dispose() {
    _refresh.dispose();
    super.dispose();
  }
}
