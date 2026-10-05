import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/music_playlist.dart';
import '../models/music_track.dart';
import '../models/remote_audio_entry.dart';
import '../services/device_media_service.dart';
import '../services/library_service.dart';
import '../services/playlist_service.dart';
import '../services/sync/sync_journal.dart';
import '../services/sync/sync_payload.dart';

typedef LocalImportSummary = ({int added, int skipped, int failed});
typedef DeviceScanSummary = ({int added, int removed, int skipped});

enum TrackSort { title, artist, album, recent }

class LibraryProvider extends ChangeNotifier {
  LibraryProvider(
    this._service,
    this._playlistService, {
    DeviceMediaService? deviceMedia,
    SyncJournal? journal,
  })  : _deviceMedia = deviceMedia ?? DeviceMediaService(),
        _journal = journal ?? SyncJournal();
  final LibraryService _service;
  final PlaylistService _playlistService;
  final DeviceMediaService _deviceMedia;
  final SyncJournal _journal;
  bool deviceMediaEnabled = false;
  final List<MusicTrack> _tracks = [];
  final List<MusicPlaylist> _playlists = [];
  Set<String> _downloadedSourceUris = const {};
  Set<String> _hiddenDeviceUris = {};
  bool isImporting = false;
  bool isDeleting = false;
  String query = '';
  List<String> _recentSearches = const [];
  bool favoritesOnly = false;
  TrackSort sort = TrackSort.title;

  List<MusicTrack>? _allTracksCache;
  List<MusicTrack>? _tracksCache;
  List<MusicTrack>? _historyCache;
  List<MusicTrack>? _audiobooksCache;
  Map<String, MusicTrack>? _byIdCache;
  Map<String, MusicTrack>? _bySourceUriCache;

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
  int get deviceTrackCount =>
      _tracks.where((track) => track.source == MusicSource.deviceMedia).length;

  List<MusicTrack> get listeningHistory => _historyCache ??= List.unmodifiable(
        tracks.where((track) => track.lastPlayedAt != null).toList()
          ..sort((a, b) => b.lastPlayedAt!.compareTo(a.lastPlayedAt!)),
      );

  /// Music views; audiobooks live in [audiobooks] so a shuffle or an album
  /// never runs into an 18-hour book.
  List<MusicTrack> get tracks {
    final cached = _tracksCache;
    if (cached != null) return cached;
    final needle = _fold(query);
    final filtered = _tracks.where((track) {
      if (track.isAudiobook) return false;
      if (favoritesOnly && !track.favorite) return false;
      return needle.isEmpty ||
          _fold(track.title).contains(needle) ||
          _fold(track.artist).contains(needle) ||
          _fold(track.album).contains(needle);
    });
    return _tracksCache = List.unmodifiable(sortTracks(filtered, sort));
  }

  /// Audiobooks matching the search, the ones being listened to first.
  List<MusicTrack> get audiobooks => _audiobooksCache ??= List.unmodifiable(
        _tracks.where((track) {
          if (!track.isAudiobook) return false;
          final needle = _fold(query);
          return needle.isEmpty ||
              _fold(track.title).contains(needle) ||
              _fold(track.artist).contains(needle) ||
              _fold(track.album).contains(needle);
        }).toList()
          ..sort((a, b) {
            final left = a.lastPlayedAt?.millisecondsSinceEpoch ?? 0;
            final right = b.lastPlayedAt?.millisecondsSinceEpoch ?? 0;
            return right != left
                ? right.compareTo(left)
                : _fold(a.title).compareTo(_fold(b.title));
          }),
      );

  /// Sorts with precomputed accent-insensitive keys; ties keep album order.
  static List<MusicTrack> sortTracks(
    Iterable<MusicTrack> tracks,
    TrackSort sort,
  ) {
    if (sort == TrackSort.recent) {
      return tracks.toList()..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    }
    final keyed = [
      for (final track in tracks)
        (
          key: switch (sort) {
            TrackSort.artist =>
              '${_fold(track.artist)}\u0000${_fold(track.album)}',
            TrackSort.album => _fold(track.album),
            _ => _fold(track.title),
          },
          track: track,
        ),
    ];
    keyed.sort((a, b) {
      final byKey = a.key.compareTo(b.key);
      if (byKey != 0) return byKey;
      final disc = (a.track.discNumber ?? 0).compareTo(b.track.discNumber ?? 0);
      if (disc != 0) return disc;
      final number =
          (a.track.trackNumber ?? 0).compareTo(b.track.trackNumber ?? 0);
      return number != 0
          ? number
          : _fold(a.track.title).compareTo(_fold(b.track.title));
    });
    return [for (final item in keyed) item.track];
  }

  static const _accents = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a', 'å': 'a', //
    'ç': 'c', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
    'î': 'i', 'ï': 'i', 'í': 'i', 'ì': 'i', 'ñ': 'n', //
    'ô': 'o', 'ö': 'o', 'ó': 'o', 'ò': 'o', 'õ': 'o', 'ø': 'o', //
    'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u', 'ÿ': 'y', 'œ': 'oe', 'æ': 'ae',
  };

  static String _fold(String value) {
    final lower = value.trim().toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_accents[char] ?? char);
    }
    return buffer.toString();
  }

  Future<void> setSort(TrackSort value) async {
    if (sort == value) return;
    sort = value;
    notifyListeners();
    await _service.saveSort(value.name);
  }

  Map<String, MusicTrack> get _byId =>
      _byIdCache ??= {for (final track in _tracks) track.id: track};

  /// Every mutation ends with a notification, so derived views are rebuilt
  /// lazily on the next read instead of on every getter call.
  void _invalidateViews() {
    _allTracksCache = null;
    _tracksCache = null;
    _historyCache = null;
    _audiobooksCache = null;
    _byIdCache = null;
    _bySourceUriCache = null;
  }

  @override
  void notifyListeners() {
    _invalidateViews();
    super.notifyListeners();
  }

  Future<void> load() async {
    final playlists = await _playlistService.load();
    final savedSort = await _service.loadSort();
    _recentSearches = await _service.loadRecentSearches();
    sort = TrackSort.values
            .where((value) => value.name == savedSort)
            .firstOrNull ??
        TrackSort.title;
    _tracks
      ..clear()
      ..addAll(await _service.load());
    _playlists
      ..clear()
      ..addAll(playlists);
    deviceMediaEnabled = await _service.loadDeviceMediaEnabled();
    _hiddenDeviceUris = await _service.loadHiddenDeviceUris();
    await _journal.load();
    _refreshDownloadedSourceUris();
    notifyListeners();
  }

  /// Turning the device source off only forgets its tracks: their files
  /// belong to the phone and stay where they are.
  Future<void> setDeviceMediaEnabled(bool enabled) async {
    if (isImporting || isDeleting) return;
    deviceMediaEnabled = enabled;
    await _service.saveDeviceMediaEnabled(enabled);
    if (!enabled) {
      await _forgetTracks({
        for (final track in _tracks)
          if (track.source == MusicSource.deviceMedia) track.id,
      });
    }
    notifyListeners();
  }

  /// Adds audio files found in shared storage and forgets those that
  /// disappeared. Files matching a private track (same title and artist,
  /// durations within two seconds) are skipped to avoid obvious duplicates.
  Future<DeviceScanSummary?> scanDeviceMedia() async {
    if (!deviceMediaEnabled || isImporting || isDeleting) return null;
    isImporting = true;
    notifyListeners();
    try {
      final files = await _deviceMedia.listAudioFiles();
      final known = {
        for (final track in _tracks)
          if (track.source == MusicSource.deviceMedia) track.uri: track,
      };
      final found = {for (final file in files) file.uri.toString()};
      final fresh = files.where((file) {
        final uri = file.uri.toString();
        return !known.containsKey(uri) && !_hiddenDeviceUris.contains(uri);
      });
      final private = <String, List<int?>>{};
      for (final track in _tracks) {
        if (track.source == MusicSource.deviceMedia) continue;
        private.putIfAbsent(_duplicateKey(track), () => []).add(
              track.durationMs,
            );
      }
      bool duplicate(MusicTrack track) =>
          private[_duplicateKey(track)]?.any((duration) =>
              duration == null ||
              track.durationMs == null ||
              (duration - track.durationMs!).abs() <= 2000) ??
          false;

      var added = 0;
      var skipped = 0;
      final pending = fresh.toList();
      importProgress = (completed: 0, total: pending.length);
      notifyListeners();
      for (var index = 0; index < pending.length; index++) {
        try {
          final track = await _service.readDeviceTrack(pending[index]);
          if (duplicate(track)) {
            // Reading the tags already saved its artwork.
            await _service.deletePrivateExtras(track);
            skipped++;
          } else {
            added += _addNewTracks([track]);
          }
        } catch (error) {
          skipped++;
          debugPrint('Device media read failed: ${error.runtimeType}');
        }
        importProgress = (completed: index + 1, total: pending.length);
        notifyListeners();
        // Tag parsing is synchronous; let frames through between files.
        await Future<void>.delayed(Duration.zero);
      }
      // An empty listing more likely means lost access than a wiped phone,
      // so it never removes tracks.
      final missing = files.isEmpty
          ? <String>{}
          : {
              for (final entry in known.entries)
                if (!found.contains(entry.key)) entry.value.id,
            };
      if (files.isNotEmpty && !_hiddenDeviceUris.every(found.contains)) {
        _hiddenDeviceUris = _hiddenDeviceUris.where(found.contains).toSet();
        await _service.saveHiddenDeviceUris(_hiddenDeviceUris);
      }
      if (missing.isNotEmpty) {
        await _forgetTracks(missing);
      } else if (added > 0) {
        await _service.save(_tracks);
      }
      return (added: added, removed: missing.length, skipped: skipped);
    } finally {
      isImporting = false;
      importProgress = null;
      notifyListeners();
    }
  }

  static String _duplicateKey(MusicTrack track) =>
      '${track.title.trim().toLowerCase()}|${track.artist.trim().toLowerCase()}';

  /// Removes tracks from the index and playlists, with the artwork and
  /// lyrics the app cached for them, without touching their audio files.
  Future<void> _forgetTracks(Set<String> ids) async {
    if (ids.isEmpty) return;
    for (final track in _tracks.where((track) => ids.contains(track.id))) {
      try {
        await _service.deletePrivateExtras(track);
      } on FileSystemException {
        // Left for the orphan cleanup.
      }
    }
    _tracks.removeWhere((track) => ids.contains(track.id));
    _byIdCache = null;
    _allTracksCache = null;
    _tracksCache = null;
    _historyCache = null;
    _bySourceUriCache = null;
    await _service.save(_tracks);
    var playlistsChanged = false;
    for (var index = 0; index < _playlists.length; index++) {
      final playlist = _playlists[index];
      if (playlist.trackIds.any(ids.contains)) {
        _playlists[index] = playlist.copyWith(
          trackIds: playlist.trackIds.where((id) => !ids.contains(id)).toList(),
        );
        playlistsChanged = true;
      }
    }
    if (playlistsChanged) await _playlistService.save(_playlists);
  }

  /// Runs before downloads resume so no import is moving files meanwhile.
  Future<void> removeOrphanFiles() async {
    if (isImporting || isDeleting) return;
    isDeleting = true;
    try {
      final removed = await _service.removeOrphanFiles(_tracks);
      if (removed > 0) debugPrint('Removed $removed orphan library files');
    } catch (error) {
      debugPrint('Orphan cleanup failed: ${error.runtimeType}');
    } finally {
      isDeleting = false;
      notifyListeners();
    }
  }

  void _refreshDownloadedSourceUris() {
    _downloadedSourceUris = Set.unmodifiable(_tracks
        .where((track) => track.source == MusicSource.serverDownload)
        .map((track) => track.sourceUri)
        .nonNulls);
  }

  bool? isFavorite(String id) => _byId[id]?.favorite;

  /// The imported copy of a server file, used to play it offline.
  MusicTrack? trackForSourceUri(String sourceUri) => (_bySourceUriCache ??= {
        for (final track in _tracks)
          if (track.sourceUri != null) track.sourceUri!: track,
      })[sourceUri];

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

  Future<void> updatePlaylistDetails(
    String id, {
    required String name,
    required String description,
  }) async {
    final normalized = name.trim();
    final index = _playlists.indexWhere((playlist) => playlist.id == id);
    if (index == -1 || normalized.isEmpty) return;
    _playlists[index] = _playlists[index].copyWith(
      name: normalized,
      description: description.trim(),
    );
    await _playlistService.save(_playlists);
    notifyListeners();
  }

  /// Moves a track using indexes of [tracksForPlaylist].
  Future<void> movePlaylistTrack(
    String playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    final index =
        _playlists.indexWhere((playlist) => playlist.id == playlistId);
    if (index == -1) return;
    final ids =
        tracksForPlaylist(_playlists[index]).map((track) => track.id).toList();
    // References to tracks this device lacks (synced from another phone)
    // stay at the end instead of being dropped.
    final visible = ids.toSet();
    final absent = _playlists[index]
        .trackIds
        .where((id) => !visible.contains(id))
        .toList();
    if (oldIndex < 0 ||
        oldIndex >= ids.length ||
        newIndex < 0 ||
        newIndex >= ids.length ||
        oldIndex == newIndex) {
      return;
    }
    ids.insert(newIndex, ids.removeAt(oldIndex));
    _playlists[index] =
        _playlists[index].copyWith(trackIds: [...ids, ...absent]);
    notifyListeners();
    await _playlistService.save(_playlists);
  }

  Future<void> deletePlaylist(String id) async {
    _playlists.removeWhere((playlist) => playlist.id == id);
    _journal.deletedPlaylists[id] = DateTime.now().toUtc();
    await _journal.save();
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

  /// Returns the track's former position so the removal can be undone.
  Future<int?> removeTrackFromPlaylist(
    String playlistId,
    String trackId,
  ) async {
    final index =
        _playlists.indexWhere((playlist) => playlist.id == playlistId);
    if (index == -1) return null;
    final position = _playlists[index].trackIds.indexOf(trackId);
    if (position == -1) return null;
    _playlists[index] = _playlists[index].copyWith(
      trackIds: _playlists[index]
          .trackIds
          .where((candidate) => candidate != trackId)
          .toList(),
    );
    // Notify first: a swiped row must leave the list in the same frame.
    notifyListeners();
    await _playlistService.save(_playlists);
    return position;
  }

  /// Puts a removed track back at [position] in the stored order.
  Future<void> restoreTrackToPlaylist(
    String playlistId,
    String trackId,
    int position,
  ) async {
    final index =
        _playlists.indexWhere((playlist) => playlist.id == playlistId);
    if (index == -1 || _playlists[index].trackIds.contains(trackId)) return;
    final ids = [..._playlists[index].trackIds];
    ids.insert(position.clamp(0, ids.length), trackId);
    _playlists[index] = _playlists[index].copyWith(trackIds: ids);
    notifyListeners();
    await _playlistService.save(_playlists);
  }

  /// Deletes app-owned tracks with their files. Device media tracks are only
  /// hidden: their files belong to the phone and later scans skip them.
  Future<int> deleteTracks(Iterable<String> ids) async {
    if (isDeleting || isImporting) return 0;
    isDeleting = true;
    notifyListeners();
    final removedIds = <String>{};
    var hiddenChanged = false;
    try {
      for (final id in ids.toSet()) {
        final track = _byId[id];
        if (track == null) continue;
        if (track.source == MusicSource.deviceMedia) {
          try {
            await _service.deletePrivateExtras(track);
          } on FileSystemException {
            // Left for the orphan cleanup.
          }
          hiddenChanged = _hiddenDeviceUris.add(track.uri) || hiddenChanged;
        } else {
          await _service.deleteTrackFiles(track);
        }
        _tracks.removeWhere((candidate) => candidate.id == id);
        _byIdCache?.remove(id);
        removedIds.add(id);
      }
      return removedIds.length;
    } finally {
      try {
        if (hiddenChanged) {
          await _service.saveHiddenDeviceUris(_hiddenDeviceUris);
        }
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

  /// Latest searches first, used as suggestions when the field is empty.
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  /// Playlists whose name or description matches the search, ignoring
  /// case and accents.
  List<MusicPlaylist> get matchingPlaylists {
    final needle = _fold(query);
    if (needle.isEmpty) return playlists;
    return _playlists
        .where((playlist) =>
            _fold(playlist.name).contains(needle) ||
            _fold(playlist.description).contains(needle))
        .toList();
  }

  Future<void> rememberSearch(String value) async {
    final search = value.trim();
    if (search.length < 2) return;
    final folded = _fold(search);
    _recentSearches = [
      search,
      ..._recentSearches.where((item) => _fold(item) != folded),
    ].take(8).toList();
    notifyListeners();
    await _service.saveRecentSearches(_recentSearches);
  }

  Future<void> clearRecentSearches() async {
    _recentSearches = const [];
    notifyListeners();
    await _service.saveRecentSearches(const []);
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

  Future<LocalImportSummary?> importDirectory({String? dialogTitle}) =>
      _importLocal(({onProgress}) => _service.pickDirectoryAndImport(
            onProgress: onProgress,
            dialogTitle: dialogTitle,
          ));

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
      _bySourceUriCache = null;
    }
    return added;
  }

  Future<void> toggleFavorite(String id) async {
    final index = _tracks.indexWhere((track) => track.id == id);
    if (index == -1) return;
    _tracks[index] =
        _tracks[index].copyWith(favorite: !_tracks[index].favorite);
    _journal.favoriteTimes[id] = DateTime.now().toUtc();
    await _service.save(_tracks);
    await _journal.save();
    notifyListeners();
  }

  /// State shared with other devices. Device media tracks are left out:
  /// their path-based ids mean nothing on another phone.
  SyncPayload syncSnapshot() => SyncPayload(
        tracks: {
          for (final track in _tracks)
            if (track.source != MusicSource.deviceMedia &&
                (track.favorite ||
                    track.playCount > 0 ||
                    _journal.positionTimes.containsKey(track.id) ||
                    _journal.favoriteTimes.containsKey(track.id)))
              track.id: SyncTrackState(
                favorite: track.favorite,
                favoriteAt: _journal.favoriteTimes[track.id],
                playCount: track.playCount,
                lastPlayedAt: track.lastPlayedAt,
                positionMs: _journal.positionTimes.containsKey(track.id)
                    ? track.lastPositionMs
                    : null,
                positionAt: _journal.positionTimes[track.id],
              ),
        },
        playlists: List.of(_playlists),
        deletedPlaylists: Map.of(_journal.deletedPlaylists),
      );

  /// Adopts a merged sync state. Entries for tracks missing here are kept
  /// in the shared file by the caller, not applied.
  Future<void> applySync(SyncPayload merged) async {
    var tracksChanged = false;
    for (var index = 0; index < _tracks.length; index++) {
      final track = _tracks[index];
      final state = merged.tracks[track.id];
      if (state == null || track.source == MusicSource.deviceMedia) continue;
      final playCount =
          state.playCount > track.playCount ? state.playCount : track.playCount;
      final lastPlayedAt = switch ((track.lastPlayedAt, state.lastPlayedAt)) {
        (final local?, final remote?) => remote.isAfter(local) ? remote : local,
        (final local, final remote) => local ?? remote,
      };
      if (state.favorite != track.favorite ||
          playCount != track.playCount ||
          lastPlayedAt != track.lastPlayedAt) {
        _tracks[index] = track.copyWith(
          favorite: state.favorite,
          playCount: playCount,
          lastPlayedAt: lastPlayedAt,
        );
        tracksChanged = true;
      }
      if (state.favoriteAt != null) {
        _journal.favoriteTimes[track.id] = state.favoriteAt!;
      }
    }
    _playlists
      ..clear()
      ..addAll(merged.playlists);
    _journal.deletedPlaylists
      ..clear()
      ..addAll(merged.deletedPlaylists);
    if (tracksChanged) {
      _invalidateViews();
      await _service.save(_tracks);
    }
    await _playlistService.save(_playlists);
    await _journal.save();
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
    if (_tracks[index].isAudiobook) {
      _journal.positionTimes[id] = DateTime.now().toUtc();
      await _journal.save();
    }
    await _service.savePosition(id, position.inMilliseconds);
  }

  /// When this device last saved the resume point of [id], if it ever did.
  DateTime? positionTime(String id) => _journal.positionTimes[id];

  /// Adopts a resume point chosen from another device.
  Future<void> adoptSyncedPosition(
      String id, int positionMs, DateTime at) async {
    final index = _tracks.indexWhere((track) => track.id == id);
    if (index == -1) return;
    _tracks[index] = _tracks[index].copyWith(lastPositionMs: positionMs);
    _journal.positionTimes[id] = at;
    _invalidateViews();
    await _journal.save();
    await _service.savePosition(id, positionMs);
    notifyListeners();
  }

  /// Marks the local resume point as the newest, so the next sync keeps it.
  Future<void> touchPosition(String id) async {
    _journal.positionTimes[id] = DateTime.now().toUtc();
    await _journal.save();
  }

  MusicTrack? trackById(String id) =>
      _tracks.where((track) => track.id == id).firstOrNull;

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
