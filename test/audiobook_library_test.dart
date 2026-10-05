import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/models/music_playlist.dart';
import 'package:music_reader_app/models/music_track.dart';
import 'package:music_reader_app/providers/library_provider.dart';
import 'package:music_reader_app/services/library_service.dart';
import 'package:music_reader_app/services/playlist_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('audiobooks are kept out of music views', () async {
    final library = LibraryProvider(_Books(), _NoPlaylists());
    await library.load();

    expect(library.tracks.map((track) => track.id), ['song']);
    expect(library.audiobooks.map((track) => track.id), ['recent', 'book']);
  });
}

class _Books extends LibraryService {
  @override
  Future<List<MusicTrack>> load() async => [
        MusicTrack(
          id: 'song',
          title: 'Song',
          uri: 'file:///music/song.mp3',
          addedAt: DateTime.utc(2026),
          metadataRead: true,
        ),
        MusicTrack(
          id: 'book',
          title: 'A book',
          uri: 'file:///books/book.m4b',
          addedAt: DateTime.utc(2026),
          metadataRead: true,
        ),
        MusicTrack(
          id: 'recent',
          title: 'Z book',
          genre: 'Audiobook',
          uri: 'file:///books/recent.mp3',
          addedAt: DateTime.utc(2026),
          lastPlayedAt: DateTime.utc(2026, 3),
          metadataRead: true,
        ),
      ];

  @override
  Future<void> save(List<MusicTrack> tracks) async {}
}

class _NoPlaylists extends PlaylistService {
  @override
  Future<List<MusicPlaylist>> load() async => [];

  @override
  Future<void> save(List<MusicPlaylist> playlists) async {}
}
