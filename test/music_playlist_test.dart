import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/models/music_playlist.dart';
import 'package:music_reader_app/models/music_track.dart';
import 'package:music_reader_app/providers/library_provider.dart';
import 'package:music_reader_app/services/library_service.dart';
import 'package:music_reader_app/services/playlist_service.dart';

void main() {
  test('playlists round-trip with their ordered track references', () {
    final playlists = [
      MusicPlaylist(
        id: 'playlist-id',
        name: 'Road trip',
        trackIds: const ['track-b', 'track-a'],
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      ),
    ];

    final decoded = MusicPlaylist.decodeAll(MusicPlaylist.encodeAll(playlists));

    expect(decoded.single.name, 'Road trip');
    expect(decoded.single.trackIds, ['track-b', 'track-a']);
    expect(decoded.single.updatedAt, DateTime.utc(2026, 1, 2));
  });

  test('library provider creates and modifies playlists', () async {
    final playlistService = _MemoryPlaylistService();
    final provider = LibraryProvider(_MemoryLibraryService(), playlistService);
    await provider.load();

    final playlist = await provider.createPlaylist('  Favorites  ');
    expect(playlist?.name, 'Favorites');

    await provider.addTrackToPlaylist(playlist!.id, 'track-id');
    await provider.addTrackToPlaylist(playlist.id, 'track-id');
    expect(provider.playlists.single.trackIds, ['track-id']);
    expect(provider.tracksForPlaylist(provider.playlists.single).single.id,
        'track-id');

    await provider.renamePlaylist(playlist.id, 'Evening');
    expect(provider.playlists.single.name, 'Evening');

    await provider.removeTrackFromPlaylist(playlist.id, 'track-id');
    expect(provider.playlists.single.trackIds, isEmpty);

    await provider.deletePlaylist(playlist.id);
    expect(provider.playlists, isEmpty);
    expect(playlistService.saved, isEmpty);
  });

  test('adds several tracks to a playlist once and in order', () async {
    final playlistService = _MemoryPlaylistService();
    final provider = LibraryProvider(
      _MemoryLibraryService([
        for (final id in ['a', 'b', 'c'])
          MusicTrack(
            id: id,
            title: id,
            uri: 'file:///media/music/$id.mp3',
            addedAt: DateTime.utc(2026),
            metadataRead: true,
          ),
      ]),
      playlistService,
    );
    await provider.load();
    final playlist = await provider.createPlaylist('Mix');
    await provider.addTrackToPlaylist(playlist!.id, 'b');

    final added =
        await provider.addTracksToPlaylist(playlist.id, ['c', 'b', 'a', 'c']);

    expect(added, 2);
    expect(provider.playlists.single.trackIds, ['b', 'c', 'a']);
    expect(playlistService.saved.single.trackIds, ['b', 'c', 'a']);
    expect(provider.tracksByIds(['c', 'missing', 'a']).map((t) => t.id),
        ['c', 'a']);
  });
}

class _MemoryLibraryService extends LibraryService {
  _MemoryLibraryService([this.tracks]);
  final List<MusicTrack>? tracks;

  @override
  Future<void> save(List<MusicTrack> tracks) async {}

  @override
  Future<List<MusicTrack>> load() async =>
      tracks ??
      [
        MusicTrack(
          id: 'track-id',
          title: 'Night Drive',
          uri: 'file:///media/music/night-drive.mp3',
          addedAt: DateTime.utc(2026, 1, 1),
        ),
      ];
}

class _MemoryPlaylistService extends PlaylistService {
  List<MusicPlaylist> saved = [];

  @override
  Future<List<MusicPlaylist>> load() async => List.of(saved);

  @override
  Future<void> save(List<MusicPlaylist> playlists) async {
    saved = List.of(playlists);
  }
}
