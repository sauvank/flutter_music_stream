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
        uri: 'file:///media/music/night-drive.mp3',
        favorite: true,
        lastPositionMs: 42000,
        addedAt: DateTime.utc(2026, 1, 1),
      ),
    ];

    final decoded = MusicTrack.decodeAll(MusicTrack.encodeAll(tracks));

    expect(decoded.single.id, 'track-id');
    expect(decoded.single.favorite, isTrue);
    expect(decoded.single.lastPositionMs, 42000);
  });
}
