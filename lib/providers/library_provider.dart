import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/music_playlist.dart';
import '../models/music_track.dart';
import '../models/remote_audio_entry.dart';
import '../services/library_service.dart';
import '../services/playlist_service.dart';

typedef LocalImportSummary = ({int added, int skipped, int failed});

class LibraryProvider extends ChangeNotifier {
  LibraryProvider(this._service, this._playlistService);
  final LibraryService _service;
  final PlaylistService _playlistService;
  final List<MusicTrack> _tracks = [];
  final List<MusicPlaylist> _playlists = [];
  Set<String> _downloadedSourceUris = const {};
  bool isImporting = false;
  bool isDeleting = false;
  String query = '';
  bool favoritesOnly = false;

  List<MusicTrack>? _allTracksCache;
  List<MusicTrack>? _tracksCache;
  List<MusicTrack>? _historyCache;
  Map<String, MusicTrack>? _byIdCache;

  List<MusicTrack> get allTracks =>
      _allTracksCache ??= List.unmodifiable(_tracks);
  int get trackCount => _tracks.length;
  Set<String> get downloadedSourceUris => _downloadedSourceUris;
  List<MusicTrack> get downloadedTracks => List.unmodifiable(
        _tracks.where((track) => track.source == MusicSource.serverDownload),
      );
  List<MusicTrack> get unknownSourceTracks =>
      List.unmodifiable(_tracks.where((track) => track.source == null));
  List<MusicPlaylist> get playlists => List.unmodifiable(_playlists);

  List<MusicTrack> get listeningHistory => _historyCache ??= List.unmodifiable(
        tracks.where((track) => track.lastPlayedAt != null).toList()
          ..sort((a, b) => b.lastPlayedAt!.compareTo(a.lastPlayedAt!)),
      );

  List<MusicTrack> get tracks {
    final cached = _tracksCache;
    if (cached != null) return cached;
    final needle = query.trim().toLowerCase();
    return _tracksCache = List.unmodifiable(_tracks.where((track) {
      if (favoritesOnly && !track.favorite) return false;
      return needle.isEmpty ||
          track.title.toLowerCase().contains(needle) ||
          track.artist.toLowerCase().contains(needle) ||
          track.album.toLowerCase().contains(needle);
    }));
  }

  Map<String, MusicTrack> get _byId =>
      _byIdCache ??= {for (final track in _tracks) track.id: track};

  /// Every mutation ends with a notification, so derived views are rebuilt
  /// lazily on the next read instead of on every getter call.
  void _invalidateViews() {
    _allTracksCache = null;
    _tracksCache = null;
    _historyCache = null;
    _byIdCache = null;
  }

  @override
  void notifyListeners() {
    _invalidateViews();
    super.notifyListeners();
  }

  Future<void> load() async {
    final playlists = await _playlistService.load();
    _tracks
      ..clear()
      ..addAll(await _service.load());
    _playlists
      ..clear()
      ..addAll(playlists);
    _refreshDownloadedSourceUris();
    notifyListeners();
  }

  void _refreshDownloadedSourceUris() {
    _downloadedSourceUris = Set.unmodifiable(_tracks
        .where((track) => track.source == MusicSource.serverDownload)
        .map((track) => track.sourceUri)
        .nonNulls);
  }

  bool? isFavorite(String id) => _byId[id]?.favorite;

  /// Resolves ids in the given order, skipping tracks that no longer exist.
  List<MusicTrack> tracksByIds(Iterable<String> ids) {
    final byId = _byId;
    return ids.map((id) => byId[id]).nonNulls.toList();
  }

  List<MusicTrack> tracksForPlaylist(MusicPlaylist playlist) {
    final byId = _byId;
    return playlist.trackIds.map((id) => byId[id]).nonNulls.toList();
  }

  Future<MusicPlaylist?> createPlaylist(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) return null;
    final now = DateTime.now().toUtc();
    final playlist = MusicPlaylist(
      id: const Uuid().v4(),
      name: normalized,
      trackIds: const [],
      createdAt: now,
      updatedAt: now,
    );
    _playlists.add(playlist);
    await _playlistService.save(_playlists);
    notifyListeners();
    return playlist;
  }

  Future<void> renamePlaylist(String id, String name) async {
    final normalized = name.trim();
    final index = _playlists.indexWhere((playlist) => playlist.id == id);
    if (index == -1 || normalized.isEmpty) return;
    _playlists[index] = _playlists[index].copyWith(name: normalized);
    await _playlistService.save(_playlists);
    notifyListeners();
  }

  Future<void> deletePlaylist(String id) async {
    _playlists.removeWhere((playlist) => playlist.id == id);
    await _playlistService.save(_playlists);
    notifyListeners();
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackId) async {
    final index =
        _playlists.indexWhere((playlist) => playlist.id == playlistId);
    if (index == -1 || _playlists[index].trackIds.contains(trackId)) return;
    _playlists[index] = _playlists[index].copyWith(
      trackIds: [..._playlists[index].trackIds, trackId],
    );
    await _playlistService.save(_playlists);
    notifyListeners();
  }

  /// Adds every track missing from the playlist in one save, keeping order.
  Future<int> addTracksToPlaylist(
    String playlistId,
    Iterable<String> trackIds,
  ) async {
    final index =
        _playlists.indexWhere((playlist) => playlist.id == playlistId);
    if (index == -1) return 0;
    final existing = _playlists[index].trackIds.toSet();
    final missing = trackIds.where(existing.add).toList();
    if (missing.isEmpty) return 0;
    _playlists[index] = _playlists[index].copyWith(
      trackIds: [..._playlists[index].trackIds, ...missing],
    );
    await _playlistService.save(_playlists);
    notifyListeners();
    return missing.length;
  }

  Future<void> removeTrackFromPlaylist(
    String playlistId,
    String trackId,
  ) async {
    final index =
        _playlists.indexWhere((playlist) => playlist.id == playlistId);
    if (index == -1) return;
    _playlists[index] = _playlists[index].copyWith(
      trackIds: _playlists[index]
          .trackIds
          .where((candidate) => candidate != trackId)
          .toList(),
    );
    await _playlistService.save(_playlists);
    notifyListeners();
  }

  Future<int> deleteTracks(Iterable<String> ids) async {
    if (isDeleting || isImporting) return 0;
    isDeleting = true;
    notifyListeners();
    final removedIds = <String>{};
    try {
      for (final id in ids.toSet()) {
        final track = _byId[id];
        if (track == null) continue;
        await _service.deleteTrackFiles(track);
        _tracks.removeWhere((candidate) => candidate.id == id);
        _byIdCache?.remove(id);
        removedIds.add(id);
      }
      return removedIds.length;
    } finally {
      try {
        if (removedIds.isNotEmpty) {
          _refreshDownloadedSourceUris();
          await _service.save(_tracks);
          for (var index = 0; index < _playlists.length; index++) {
            final playlist = _playlists[index];
            if (playlist.trackIds.any(removedIds.contains)) {
              _playlists[index] = playlist.copyWith(
                trackIds: playlist.trackIds
                    .where((id) => !removedIds.contains(id))
                    .toList(),
              );
            }
          }
          await _playlistService.save(_playlists);
        }
      } finally {
        isDeleting = false;
        notifyListeners();
      }
    }
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void toggleFavoritesFilter() {
    favoritesOnly = !favoritesOnly;
    notifyListeners();
  }

  /// Progress of the running local import, or `null` when none is running.
  ({int completed, int total})? importProgress;

  Future<LocalImportSummary?> importFiles() =>
      _importLocal(_service.pickAndImport);

  Future<LocalImportSummary?> importDirectory() =>
      _importLocal(_service.pickDirectoryAndImport);

  Future<LocalImportSummary?> _importLocal(
    Future<LocalImportResult?> Function({ImportProgressCallback? onProgress})
        pick,
  ) async {
    if (isImporting || isDeleting) return null;
    isImporting = true;
    notifyListeners();
    try {
      final result = await pick(onProgress: (completed, total) {
        importProgress = (completed: completed, total: total);
        notifyListeners();
      });
      if (result == null) return null;
      final added = _addNewTracks(result.tracks);
      if (added > 0) await _service.save(_tracks);
      return (
        added: added,
        skipped: result.tracks.length - added,
        failed: result.failed,
      );
    } finally {
      isImporting = false;
      importProgress = null;
      notifyListeners();
    }
  }

  int _addNewTracks(Iterable<MusicTrack> incoming) {
    final byId = _byId;
    var added = 0;
    for (final track in incoming) {
      if (byId.containsKey(track.id)) continue;
      _tracks.add(track);
      byId[track.id] = track;
      added++;
    }
    if (added > 0) {
      _allTracksCache = null;
      _tracksCache = null;
      _historyCache = null;
    }
    return added;
  }

  Future<void> toggleFavorite(String id) async {
    final index = _tracks.indexWhere((track) => track.id == id);
    if (index == -1) return;
    _tracks[index] =
        _tracks[index].copyWith(favorite: !_tracks[index].favorite);
    await _service.save(_tracks);
    notifyListeners();
  }

  Future<bool> importRemote({
    required String name,
    required Uri uri,
    Map<String, String> headers = const {},
  }) async {
    isImporting = true;
    notifyListeners();
    try {
      final track = await _service.importRemote(
        name: name,
        uri: uri,
        headers: headers,
      );
      if (_addNewTracks([track]) == 0) return false;
      _refreshDownloadedSourceUris();
      await _service.save(_tracks);
      return true;
    } finally {
      isImporting = false;
      notifyListeners();
    }
  }

  Future<({int added, int skipped, int failed})> importRemoteFiles({
    required List<RemoteAudioEntry> files,
    Map<String, String> headers = const {},
    void Function(int completed, int total)? onProgress,
  }) async {
    var added = 0;
    var skipped = 0;
    var failed = 0;
    isImporting = true;
    notifyListeners();
    try {
      for (var index = 0; index < files.length; index++) {
        final file = files[index];
        try {
          final track = await _service.importRemote(
            name: file.name,
            uri: file.uri,
            headers: headers,
          );
          if (_addNewTracks([track]) == 0) {
            skipped++;
          } else {
            added++;
          }
        } catch (_) {
          failed++;
        }
        onProgress?.call(index + 1, files.length);
      }
      if (added > 0) await _service.save(_tracks);
      if (added > 0) _refreshDownloadedSourceUris();
      return (added: added, skipped: skipped, failed: failed);
    } finally {
      isImporting = false;
      notifyListeners();
    }
  }

  Future<bool> importDownloadedFile({
    required String sourcePath,
    required String originalName,
    String? sourceUri,
  }) async {
    final track = await _service.importDownloadedFile(
      sourcePath: sourcePath,
      originalName: originalName,
      sourceUri: sourceUri,
    );
    if (_addNewTracks([track]) == 0) return false;
    _refreshDownloadedSourceUris();
    await _service.save(_tracks);
    notifyListeners();
    return true;
  }

  Future<void> savePosition(String id, Duration position) async {
    final index = _tracks.indexWhere((track) => track.id == id);
    if (index == -1) return;
    _tracks[index] =
        _tracks[index].copyWith(lastPositionMs: position.inMilliseconds);
    _invalidateViews();
    await _service.savePosition(id, position.inMilliseconds);
  }

  Future<void> recordPlayed(String id) async {
    final index = _tracks.indexWhere((track) => track.id == id);
    if (index == -1) return;
    final track = _tracks[index];
    _tracks[index] = track.copyWith(
      lastPlayedAt: DateTime.now().toUtc(),
      playCount: track.playCount + 1,
    );
    await _service.save(_tracks);
    notifyListeners();
  }
}
