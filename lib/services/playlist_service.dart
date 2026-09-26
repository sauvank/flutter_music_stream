import 'package:shared_preferences/shared_preferences.dart';

import '../models/music_playlist.dart';

class PlaylistService {
  static const _playlistsKey = 'music_playlists_v1';

  Future<List<MusicPlaylist>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final serialized = preferences.getString(_playlistsKey);
    if (serialized == null || serialized.isEmpty) return [];
    try {
      return MusicPlaylist.decodeAll(serialized);
    } on FormatException {
      return [];
    }
  }

  Future<void> save(List<MusicPlaylist> playlists) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _playlistsKey,
      MusicPlaylist.encodeAll(playlists),
    );
  }
}
