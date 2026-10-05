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
        source: MusicSource.serverDownload,
        sourceUri: 'https://example.com/music/night-drive.mp3',
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
    expect(decoded.single.source, MusicSource.serverDownload);
    expect(
        decoded.single.sourceUri, 'https://example.com/music/night-drive.mp3');
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
    expect(track.sourceUri, isNull);
  });

  test('audiobooks keep chapters and report progress', () {
    final book = MusicTrack(
      id: 'book',
      title: 'Livre',
      uri: 'file:///media/livre.m4b',
      addedAt: DateTime.utc(2026),
      durationMs: 10000,
      lastPositionMs: 2500,
      chapters: const [
        TrackChapter(startMs: 0, title: 'Intro'),
        TrackChapter(startMs: 4000, title: 'Un'),
      ],
    );
    final restored = MusicTrack.decodeAll(MusicTrack.encodeAll([book])).single;

    expect(restored.isAudiobook, isTrue);
    expect(restored.chapters.map((chapter) => chapter.title), ['Intro', 'Un']);
    expect(restored.progress, .25);
    expect(restored.chapterIndexAt(3999), 0);
    expect(restored.chapterIndexAt(4000), 1);
    expect(restored.copyWith(lastPositionMs: 1).chapters, hasLength(2));
  });
}
