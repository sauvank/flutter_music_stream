import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/models/music_track.dart';

void main() {
  test('a music library round-trips without losing private state', () {
    final tracks = [
      MusicTrack(
        id: 'track-id',
        title: 'Night Drive',
        artist: 'Demo Artist',
        album: 'Demo Album',
        genre: 'Synthwave',
        artworkUri: 'file:///media/music/night-drive.jpg',
        trackNumber: 3,
        discNumber: 1,
        uri: 'file:///media/music/night-drive.mp3',
        durationMs: 195000,
        favorite: true,
        lastPositionMs: 42000,
        lastPlayedAt: DateTime.utc(2026, 2, 2),
        playCount: 4,
        metadataRead: true,
        addedAt: DateTime.utc(2026, 1, 1),
      ),
    ];

    final decoded = MusicTrack.decodeAll(MusicTrack.encodeAll(tracks));

    expect(decoded.single.id, 'track-id');
    expect(decoded.single.favorite, isTrue);
    expect(decoded.single.lastPositionMs, 42000);
    expect(decoded.single.lastPlayedAt, DateTime.utc(2026, 2, 2));
    expect(decoded.single.playCount, 4);
    expect(decoded.single.genre, 'Synthwave');
    expect(decoded.single.artworkUri, 'file:///media/music/night-drive.jpg');
    expect(decoded.single.trackNumber, 3);
    expect(decoded.single.discNumber, 1);
    expect(decoded.single.durationMs, 195000);
    expect(decoded.single.metadataRead, isTrue);
  });

  test('legacy tracks remain compatible and request one metadata migration',
      () {
    final track = MusicTrack.fromJson({
      'id': 'legacy-id',
      'title': 'Legacy song',
      'uri': 'file:///media/music/legacy.mp3',
      'addedAt': DateTime.utc(2025, 1, 1).toIso8601String(),
    });

    expect(track.artist, 'Artiste inconnu');
    expect(track.album, 'Album inconnu');
    expect(track.genre, 'Genre inconnu');
    expect(track.metadataRead, isFalse);
    expect(track.lastPlayedAt, isNull);
    expect(track.playCount, 0);
  });
}
