import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/services/download_queue_refresh.dart';

void main() {
  testWidgets('1500 native events cause one delayed refresh, not 1500 scans',
      (tester) async {
    var reads = 0;
    final refresh = DownloadQueueRefresh(() async {
      reads++;
    }, onError: (_) {});
    for (var i = 0; i < 1500; i++) {
      refresh.request();
    }
    await tester.pump(const Duration(milliseconds: 499));
    expect(reads, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(reads, 1);
    refresh.request(); // The final completion is not lost.
    await tester.pump(const Duration(milliseconds: 500));
    expect(reads, 2);
    refresh.dispose();
  });

  testWidgets('events during a slow read cause one later read without overlap',
      (tester) async {
    var reads = 0;
    final pending = Completer<void>();
    final refresh = DownloadQueueRefresh(() async {
      reads++;
      if (reads == 1) await pending.future;
    }, onError: (_) {});
    refresh.request();
    await tester.pump(const Duration(milliseconds: 500));
    for (var i = 0; i < 1500; i++) {
      refresh.request();
    }
    await tester.pump(const Duration(seconds: 2));
    expect(reads, 1);
    pending.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(reads, 2);
    refresh.dispose();
  });

  testWidgets(
      'errors do not poison future reads; disposal cancels pending work',
      (tester) async {
    var reads = 0;
    var errors = 0;
    final refresh = DownloadQueueRefresh(() async {
      reads++;
      if (reads == 1) throw StateError('storage unavailable');
    }, onError: (_) {
      errors++;
    });
    refresh.request();
    await tester.pump(const Duration(milliseconds: 500));
    expect(errors, 1);
    refresh.request();
    await tester.pump(const Duration(milliseconds: 500));
    expect(reads, 2);
    refresh.request();
    refresh.dispose();
    refresh.request();
    await tester.pump(const Duration(seconds: 1));
    expect(reads, 2);
  });
}
