import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/models/audiobook.dart';
import 'package:music_reader_app/models/music_track.dart';

void main() {
  test('groups chapter files into books in natural reading order', () {
    final books = Audiobook.group([
      _chapter('c10', 'Chapitre 10'),
      _chapter('c2', 'Chapitre 2'),
      _chapter('c1', 'Chapitre 1'),
      _chapter('other', 'Partie 1', album: 'Autre livre'),
      _chapter('single', 'Un seul fichier', album: MusicTrack.unknownAlbum),
    ]);

    expect(books.map((book) => book.title),
        ['Autre livre', 'Les Misérables', 'Un seul fichier']);
    final hugo = books[1];
    expect(hugo.chapters.map((track) => track.id), ['c1', 'c2', 'c10']);
    expect(hugo.started, isFalse);
    expect(hugo.progress, isNull);
    expect(hugo.resumeChapter.id, 'c1');
  });

  test('resumes the last chapter heard, or the next one once it is finished',
      () {
    final heard = Audiobook.group([
      _chapter('c1', 'Chapitre 1', position: 60000, playedAt: 1),
      _chapter('c2', 'Chapitre 2', position: 30000, playedAt: 2),
      _chapter('c3', 'Chapitre 3'),
    ]).single;
    expect(heard.resumeChapter.id, 'c2');
    // One full chapter plus half of the second, out of three.
    expect(heard.progress, closeTo(1.5 / 3, 1e-9));

    final finished = Audiobook.group([
      _chapter('c1', 'Chapitre 1', position: 60000, playedAt: 1),
      _chapter('c2', 'Chapitre 2', position: 60000, playedAt: 2),
      _chapter('c3', 'Chapitre 3'),
    ]).single;
    expect(finished.resumeChapter.id, 'c3');
    expect(finished.finished, isFalse);

    final done = Audiobook.group([
      _chapter('c1', 'Chapitre 1', position: 60000, playedAt: 1),
    ]).single;
    expect(done.finished, isTrue);
    expect(done.progress, 1);
  });

  test('books being listened to come first', () {
    final books = Audiobook.group([
      _chapter('a', 'A', album: 'Alpha'),
      _chapter('z', 'Z', album: 'Zeta', position: 1000, playedAt: 5),
    ]);
    expect(books.map((book) => book.title), ['Zeta', 'Alpha']);
  });
}

MusicTrack _chapter(
  String id,
  String title, {
  String album = 'Les Misérables',
  int position = 0,
  int? playedAt,
}) =>
    MusicTrack(
      id: id,
      title: title,
      artist: 'Victor Hugo',
      album: album,
      genre: 'Audiobook',
      uri: 'file:///books/$id.mp3',
      durationMs: 60000,
      lastPositionMs: position,
      lastPlayedAt: playedAt == null
          ? null
          : DateTime.utc(2026).add(Duration(minutes: playedAt)),
      addedAt: DateTime.utc(2026),
    );
