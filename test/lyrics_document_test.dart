import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/models/lyrics_document.dart';

void main() {
  test('parses, sorts and locates synchronized lines', () {
    final document = LyricsDocument.parse('''
[ti:Example]
[offset:+500]
[00:12.50][00:24.500] Second line
[00:02.3] First line
[00:30.00]
''');

    expect(document.synchronized, isTrue);
    expect(document.lines.map((line) => line.text), [
      'First line',
      'Second line',
      'Second line',
      '',
    ]);
    expect(document.lines.first.time, const Duration(milliseconds: 2800));
    expect(document.activeLineAt(const Duration(seconds: 1)), -1);
    expect(document.activeLineAt(const Duration(seconds: 13)), 1);
    expect(document.activeLineAt(const Duration(milliseconds: 30500)), 3);
  });

  test('uses plain lyrics when timestamps are absent', () {
    final document =
        LyricsDocument.parse('\uFEFF[ar:Demo]\nA line\nAnother line');

    expect(document.synchronized, isFalse);
    expect(document.plainText, 'A line\nAnother line');
  });
}
