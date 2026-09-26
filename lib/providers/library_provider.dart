import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/music_playlist.dart';
import '../models/music_track.dart';
import '../services/library_service.dart';
import '../services/playlist_service.dart';

class LibraryProvider extends ChangeNotifier {
  LibraryProvider(this._service, this._playlistService);
  final LibraryService _service;
  final PlaylistService _playlistService;
  final List<MusicTrack> _tracks = [];
  final List<MusicPlaylist> _playlists = [];
  bool isImporting = false;
  String query = '';
  bool favoritesOnly = false;

  List<MusicTrack> get allTracks => List.unmodifiable(_tracks);
  List<MusicPlaylist> get playlists => List.unmodifiable(_playlists);

  List<MusicTrack> get tracks {
    final needle = query.trim().toLowerCase();
    return _tracks.where((track) {
      if (favoritesOnly && !track.favorite) return false;
      return needle.isEmpty ||
          track.title.toLowerCase().contains(needle) ||
          track.artist.toLowerCase().contains(needle) ||
          track.album.toLowerCase().contains(needle);
    }).toList();
  }

  Future<void> load() async {
    final playlists = await _playlistService.load();
    _tracks
      ..clear()
      ..addAll(await _service.load());
    _playlists
      ..clear()
      ..addAll(playlists);
    notifyListeners();
  }

  List<MusicTrack> tracksForPlaylist(MusicPlaylist playlist) {
    final byId = {for (final track in _tracks) track.id: track};
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

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void toggleFavoritesFilter() {
    favoritesOnly = !favoritesOnly;
    notifyListeners();
  }

  Future<void> importFiles() async {
    isImporting = true;
    notifyListeners();
    try {
      final incoming = await _service.pickAndImport();
      for (final track in incoming) {
        if (_tracks.every((existing) => existing.id != track.id)) {
          _tracks.add(track);
        }
      }
      await _service.save(_tracks);
    } finally {
      isImporting = false;
      notifyListeners();
    }
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
      if (_tracks.any((existing) => existing.id == track.id)) return false;
      _tracks.add(track);
      await _service.save(_tracks);
      return true;
    } finally {
      isImporting = false;
      notifyListeners();
    }
  }

  Future<void> savePosition(String id, Duration position) async {
    final index = _tracks.indexWhere((track) => track.id == id);
    if (index == -1) return;
    _tracks[index] =
        _tracks[index].copyWith(lastPositionMs: position.inMilliseconds);
    await _service.save(_tracks);
  }
}
