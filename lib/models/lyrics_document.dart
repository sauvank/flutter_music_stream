class LyricsLine {
  const LyricsLine(this.time, this.text);

  final Duration time;
  final String text;
}

class LyricsDocument {
  const LyricsDocument({required this.lines, required this.plainText});

  final List<LyricsLine> lines;
  final String plainText;

  bool get synchronized => lines.isNotEmpty;
  bool get isEmpty => lines.isEmpty && plainText.trim().isEmpty;

  int activeLineAt(Duration position) {
    var low = 0;
    var high = lines.length;
    while (low < high) {
      final middle = (low + high) ~/ 2;
      if (lines[middle].time <= position) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low - 1;
  }

  factory LyricsDocument.parse(String source) {
    final lines = <LyricsLine>[];
    final plain = <String>[];
    final timestamp = RegExp(r'\[(\d{1,3}):([0-5]\d)(?:[.:](\d{1,3}))?\]');
    final metadata = RegExp(r'^\[[a-zA-Z]+:.*\]$');
    final offset =
        RegExp(r'\[offset:([+-]?\d+)\]').firstMatch(source.toLowerCase());
    final offsetMilliseconds = int.tryParse(offset?.group(1) ?? '') ?? 0;
    for (final raw
        in source.replaceFirst('\uFEFF', '').split(RegExp(r'\r?\n'))) {
      final matches = timestamp.allMatches(raw).toList();
      if (matches.isEmpty) {
        if (!metadata.hasMatch(raw.trim()) && raw.trim().isNotEmpty) {
          plain.add(raw.trim());
        }
        continue;
      }
      final text = raw.replaceAll(timestamp, '').trim();
      for (final match in matches) {
        final minute = int.parse(match.group(1)!);
        final second = int.parse(match.group(2)!);
        final fraction = match.group(3) ?? '';
        final milliseconds = fraction.isEmpty
            ? 0
            : int.parse(fraction.padRight(3, '0').substring(0, 3));
        final timeMilliseconds =
            minute * 60000 + second * 1000 + milliseconds + offsetMilliseconds;
        lines.add(LyricsLine(
          Duration(milliseconds: timeMilliseconds < 0 ? 0 : timeMilliseconds),
          text,
        ));
      }
    }
    lines.sort((a, b) => a.time.compareTo(b.time));
    return LyricsDocument(
      lines: List.unmodifiable(lines),
      plainText: plain.join('\n'),
    );
  }
}
