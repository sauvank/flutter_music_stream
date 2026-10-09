import 'music_track.dart';

/// Audiobook files that belong together (same album and author), so a book
/// split into one file per chapter reads, resumes and progresses as one.
class Audiobook {
  Audiobook({
    required this.title,
    required this.author,
    required List<MusicTrack> chapters,
  }) : chapters = List.unmodifiable(chapters);

  final String title;
  final String author;

  /// Files in reading order.
  final List<MusicTrack> chapters;

  /// Groups [tracks] into books, the most recently heard first, then by title.
  static List<Audiobook> group(Iterable<MusicTrack> tracks) {
    final grouped = <String, List<MusicTrack>>{};
    for (final track in tracks) {
      // A file without an album is a book on its own (typically a .m4b).
      final key = track.album == MusicTrack.unknownAlbum
          ? 'file\u0000${track.id}'
          : '${track.album.toLowerCase()}\u0000${track.artist.toLowerCase()}';
      grouped.putIfAbsent(key, () => []).add(track);
    }
    final books = [
      for (final files in grouped.values)
        Audiobook(
          title: files.first.album == MusicTrack.unknownAlbum
              ? files.first.title
              : files.first.album,
          author: files.first.artist,
          chapters: files..sort(_readingOrder),
        ),
    ];
    return books
      ..sort((a, b) {
        final left = a.lastPlayedAt?.millisecondsSinceEpoch ?? 0;
        final right = b.lastPlayedAt?.millisecondsSinceEpoch ?? 0;
        if (left != right) return right.compareTo(left);
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
  }

  static int _readingOrder(MusicTrack a, MusicTrack b) {
    final disc = (a.discNumber ?? 0).compareTo(b.discNumber ?? 0);
    if (disc != 0) return disc;
    final number = (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0);
    return number != 0 ? number : naturalCompare(a.title, b.title);
  }

  /// Orders "Chapitre 2" before "Chapitre 10".
  static int naturalCompare(String a, String b) {
    final pattern = RegExp(r'\d+|\D+');
    final left = pattern.allMatches(a.toLowerCase()).map((m) => m[0]!).toList();
    final right =
        pattern.allMatches(b.toLowerCase()).map((m) => m[0]!).toList();
    for (var i = 0; i < left.length && i < right.length; i++) {
      final x = int.tryParse(left[i]);
      final y = int.tryParse(right[i]);
      final order = x != null && y != null
          ? x.compareTo(y)
          : left[i].compareTo(right[i]);
      if (order != 0) return order;
    }
    return left.length.compareTo(right.length);
  }

  DateTime? get lastPlayedAt {
    DateTime? latest;
    for (final chapter in chapters) {
      final played = chapter.lastPlayedAt;
      if (played != null && (latest == null || played.isAfter(latest))) {
        latest = played;
      }
    }
    return latest;
  }

  bool get started => chapters
      .any((chapter) => chapter.lastPlayedAt != null || chapter.lastPositionMs > 0);

  static bool _finished(MusicTrack chapter) {
    final total = chapter.durationMs;
    return total != null &&
        total > 1000 &&
        chapter.lastPositionMs >= total - 1000;
  }

  int get _resumeIndex {
    var index = -1;
    DateTime? latest;
    for (var i = 0; i < chapters.length; i++) {
      final played = chapters[i].lastPlayedAt;
      if (played != null && (latest == null || played.isAfter(latest))) {
        latest = played;
        index = i;
      }
    }
    if (index == -1) {
      index = chapters.lastIndexWhere((chapter) => chapter.lastPositionMs > 0);
    }
    if (index == -1) return 0;
    // A chapter heard to the end hands over to the next one.
    if (_finished(chapters[index]) && index + 1 < chapters.length) {
      return index + 1;
    }
    return index;
  }

  /// Where listening continues: the last chapter heard, or the next one when
  /// that chapter is finished, or the first chapter of an unheard book.
  MusicTrack get resumeChapter => chapters[_resumeIndex];

  bool get finished =>
      _resumeIndex == chapters.length - 1 && _finished(chapters.last);

  /// Share of the book heard, assuming earlier chapters are done; null when
  /// nothing has been heard yet.
  double? get progress {
    if (!started) return null;
    if (finished) return 1;
    final index = _resumeIndex;
    final resume = chapters[index];
    final durations = chapters.map((chapter) => chapter.durationMs).toList();
    if (durations.every((value) => value != null && value > 0)) {
      final total = durations.fold<int>(0, (sum, value) => sum + value!);
      final before =
          durations.take(index).fold<int>(0, (sum, value) => sum + value!);
      return ((before + resume.lastPositionMs) / total).clamp(0.0, 1.0);
    }
    return ((index + (resume.progress ?? 0)) / chapters.length)
        .clamp(0.0, 1.0);
  }
}
