// Frame timing benchmark on a real device. Enables "Device media" so the lists
// hold the audio files already on the device (grant READ_MEDIA_AUDIO first).
// Run in profile mode:
//   flutter drive -d <device> --profile \
//     --driver=test_driver/perf_driver.dart --target=integration_test/perf_test.dart
// Results land in build/perf/*.json.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:music_reader_app/main.dart' as app;
import 'package:music_reader_app/providers/library_provider.dart';
import 'package:music_reader_app/screens/home_screen.dart';
import 'package:provider/provider.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final reports = <String, Object>{};

  // Same summary as watchPerformance, without its VM service dependency.
  Future<void> measure(Future<void> Function() action,
      {required String reportKey}) async {
    final timings = <FrameTiming>[];
    void collect(List<FrameTiming> batch) => timings.addAll(batch);
    SchedulerBinding.instance.addTimingsCallback(collect);
    final watch = Stopwatch()..start();
    await action();
    // Timings are delivered in batches; let the last one arrive.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    SchedulerBinding.instance.removeTimingsCallback(collect);
    reports[reportKey] = {
      ...FrameTimingSummarizer(timings).summary,
      'wall_ms': watch.elapsedMilliseconds,
    };
    binding.reportData = reports;
  }

  testWidgets('UI frame timings', (tester) async {
    app.main();
    for (var i = 0;
        i < 100 && find.byType(NavigationBar).evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 20));

    final library =
        tester.element(find.byType(HomeScreen)).read<LibraryProvider>();
    for (var i = 0; i < 300 && library.allTracks.length < 100; i++) {
      if (!library.isImporting) {
        if (!library.deviceMediaEnabled) {
          await library.setDeviceMediaEnabled(true);
        }
        await library.scanDeviceMedia();
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    debugPrint('perf: ${library.allTracks.length} tracks');

    Finder scrollable() => find
        .byWidgetPredicate((widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down)
        .hitTestable()
        .first;

    await measure(() async {
      for (var i = 0; i < 4; i++) {
        await tester.fling(scrollable(), const Offset(0, -2500), 4000);
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < 4; i++) {
        await tester.fling(scrollable(), const Offset(0, 2500), 4000);
        await tester.pumpAndSettle();
      }
    }, reportKey: 'library_scroll');

    await measure(() async {
      await tester.tap(find.byType(SearchBar));
      await tester.pumpAndSettle();
      for (final query in ['M', 'Mo', 'Morceau', 'Morceau 5', 'Artiste 1']) {
        await tester.enterText(find.byType(SearchBar), query);
        await tester.pumpAndSettle();
      }
      await tester.enterText(find.byType(SearchBar), '');
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
    }, reportKey: 'search');

    final destinations = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byType(NavigationDestination));
    await measure(() async {
      for (var round = 0; round < 2; round++) {
        for (final index in [1, 3, 0]) {
          await tester.tap(destinations.at(index));
          await tester.pumpAndSettle();
        }
      }
    }, reportKey: 'tab_switch');

    await measure(() async {
      await tester.tap(find.text('Shuffle').first);
      await tester.pumpAndSettle();
      await tester.tap(destinations.at(2));
      // Playback screen: position ticks, artwork tint and animations.
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(destinations.at(0));
      await tester.pumpAndSettle();
    }, reportKey: 'now_playing');
  });
}
