import 'package:flutter/foundation.dart';

import '../models/music_track.dart';
import '../services/library_service.dart';

class LibraryProvider extends ChangeNotifier {
  LibraryProvider(this._service);
  final LibraryService _service;
  final List<MusicTrack> _tracks = [];
  bool isImporting = false;
  String query = '';
  bool favoritesOnly = false;

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
    _tracks
      ..clear()
      ..addAll(await _service.load());
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

  Future<void> savePosition(String id, Duration position) async {
    final index = _tracks.indexWhere((track) => track.id == id);
    if (index == -1) return;
    _tracks[index] =
        _tracks[index].copyWith(lastPositionMs: position.inMilliseconds);
    await _service.save(_tracks);
  }
}
