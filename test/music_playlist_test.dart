import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/models/music_playlist.dart';
import 'package:music_reader_app/models/music_track.dart';
import 'package:music_reader_app/providers/library_provider.dart';
import 'package:music_reader_app/services/library_service.dart';
import 'package:music_reader_app/services/playlist_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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

  test('reads playlists saved before descriptions existed', () {
    final decoded = MusicPlaylist.decodeAll(
      '[{"id":"p","name":"Old","trackIds":[],'
      '"createdAt":"2026-01-01T00:00:00.000Z",'
      '"updatedAt":"2026-01-01T00:00:00.000Z"}]',
    );

    expect(decoded.single.description, isEmpty);
    expect(decoded.single.toJson().containsKey('description'), isFalse);
  });

  test('edits playlist details and reorders its tracks', () async {
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
    await provider
        .addTracksToPlaylist(playlist!.id, ['a', 'missing', 'b', 'c']);

    await provider.updatePlaylistDetails(
      playlist.id,
      name: '  Soirée ',
      description: '  Pour les longues routes.  ',
    );
    expect(provider.playlists.single.name, 'Soirée');
    expect(provider.playlists.single.description, 'Pour les longues routes.');

    await provider.updatePlaylistDetails(playlist.id,
        name: '   ', description: 'Ignored');
    expect(provider.playlists.single.description, 'Pour les longues routes.');

    await provider.movePlaylistTrack(playlist.id, 2, 0);
    expect(provider.playlists.single.trackIds, ['c', 'a', 'b']);
    await provider.movePlaylistTrack(playlist.id, 0, 5);
    expect(provider.playlists.single.trackIds, ['c', 'a', 'b']);

    final reloaded =
        MusicPlaylist.decodeAll(MusicPlaylist.encodeAll(playlistService.saved));
    expect(reloaded.single.trackIds, ['c', 'a', 'b']);
    expect(reloaded.single.description, 'Pour les longues routes.');
  });

  test('sorts tracks without accent bias and remembers the choice', () async {
    MusicTrack track(String id, String title, String artist,
            {String album = 'Album', int? number}) =>
        MusicTrack(
          id: id,
          title: title,
          artist: artist,
          album: album,
          trackNumber: number,
          uri: 'file:///media/music/$id.mp3',
          addedAt: DateTime.utc(2026, 1, int.parse(id)),
          metadataRead: true,
        );
    final tracks = [
      track('1', 'Zèbre', 'Björk', number: 2),
      track('2', 'Écho', 'Björk', number: 1),
      track('3', 'avion', 'Air', album: 'Best of'),
    ];
    final provider = LibraryProvider(
        _MemoryLibraryService(tracks), _MemoryPlaylistService());
    await provider.load();

    expect(provider.tracks.map((t) => t.id), ['3', '2', '1']);
    await provider.setSort(TrackSort.artist);
    expect(provider.tracks.map((t) => t.id), ['3', '2', '1']);
    await provider.setSort(TrackSort.recent);
    expect(provider.tracks.map((t) => t.id), ['3', '2', '1']);
    await provider.setSort(TrackSort.album);
    expect(provider.tracks.map((t) => t.id), ['2', '1', '3']);

    final reloaded = LibraryProvider(
        _MemoryLibraryService(tracks), _MemoryPlaylistService());
    await reloaded.load();
    expect(reloaded.sort, TrackSort.album);
  });

  test('finds the imported copy of a server file', () async {
    final provider = LibraryProvider(
      _MemoryLibraryService([
        MusicTrack(
          id: 'local',
          title: 'Local',
          uri: 'file:///media/music/local.mp3',
          addedAt: DateTime.utc(2026),
          metadataRead: true,
          source: MusicSource.serverDownload,
          sourceUri: 'https://192.168.1.100/music/local.mp3',
        ),
      ]),
      _MemoryPlaylistService(),
    );
    await provider.load();

    expect(
      provider.trackForSourceUri('https://192.168.1.100/music/local.mp3')?.id,
      'local',
    );
    expect(
        provider.trackForSourceUri('https://192.168.1.100/other.mp3'), isNull);
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
