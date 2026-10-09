// Bulk download benchmark: "Download all" on a WebDAV server holding many
// audio files, measuring listing, queueing, transfer + indexing throughput and
// UI frame timings while the queue runs. Serve a folder and expose it to the
// device first, for example:
//   rclone serve webdav <folder> --addr 127.0.0.1:8090 --read-only
//   adb reverse tcp:8090 tcp:8090
// Then, in profile mode:
//   flutter drive -d <device> --profile --driver=test_driver/perf_driver.dart \
//     --target=integration_test/download_test.dart \
//     --dart-define=BENCH_URL=http://127.0.0.1:8090/ --dart-define=BENCH_FILES=3000
// Results land in build/perf/download.json.
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:music_reader_app/main.dart' as app;
import 'package:music_reader_app/models/music_track.dart';
import 'package:music_reader_app/models/server_profile.dart';
import 'package:music_reader_app/providers/download_queue_provider.dart';
import 'package:music_reader_app/providers/download_request.dart';
import 'package:music_reader_app/providers/library_provider.dart';
import 'package:music_reader_app/providers/server_provider.dart';
import 'package:music_reader_app/screens/home_screen.dart';
import 'package:music_reader_app/models/remote_audio_entry.dart';
import 'package:provider/provider.dart';

const _url =
    String.fromEnvironment('BENCH_URL', defaultValue: 'http://127.0.0.1:8090/');
const _expected = int.fromEnvironment('BENCH_FILES', defaultValue: 3000);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bulk download', (tester) async {
    app.main();
    for (var i = 0;
        i < 100 && find.byType(NavigationBar).evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(HomeScreen));
    final library = context.read<LibraryProvider>();
    final servers = context.read<ServerProvider>();
    final downloads = context.read<DownloadQueueProvider>();
    int downloaded() => library.allTracks
        .where((track) => track.source == MusicSource.serverDownload)
        .length;
    final before = downloaded();

    const profile = ServerProfile(
        id: 'bench', name: 'Bench', baseUrl: _url, type: ServerType.webdav);
    if (!servers.profiles.any((p) => p.id == profile.id)) {
      await servers.addProfile(profile, '');
    }

    final timings = <FrameTiming>[];
    void collect(List<FrameTiming> batch) => timings.addAll(batch);
    SchedulerBinding.instance.addTimingsCallback(collect);
    final watch = Stopwatch()..start();
    final root = Uri.parse(_url);
    downloads.startRequest(
      entry: RemoteAudioEntry(name: 'Bench', uri: root, isDirectory: true),
      profile: profile,
      password: () async => '',
      remote: servers.remoteService,
    );

    int? listedMs, queuedMs, transferredMs;
    final samples = <Map<String, int>>[];
    Finder scrollable() => find
        .byWidgetPredicate((widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down)
        .hitTestable()
        .first;
    var tick = 0;
    while (watch.elapsed < const Duration(minutes: 30)) {
      // Keep the UI busy as a user would: scroll the library during the run.
      if (tick.isEven) {
        await tester.fling(scrollable(), const Offset(0, -1500), 3000);
      } else {
        await tester.fling(scrollable(), const Offset(0, 1500), 3000);
      }
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      tick++;
      final request = downloads.requests.isEmpty
          ? null
          : downloads.requests.firstWhere((r) => r.profile.id == profile.id,
              orElse: () => downloads.requests.first);
      if (listedMs == null &&
          (request == null || request.stage != DownloadRequestStage.scanning)) {
        listedMs = watch.elapsedMilliseconds;
      }
      if (queuedMs == null && (request == null || !request.active)) {
        queuedMs = watch.elapsedMilliseconds;
      }
      final records = downloads.records;
      final complete =
          records.where((r) => r.status == TaskStatus.complete).length;
      final failed = records
          .where((r) =>
              r.status == TaskStatus.failed || r.status == TaskStatus.notFound)
          .length;
      if (transferredMs == null && complete + failed >= _expected) {
        transferredMs = watch.elapsedMilliseconds;
      }
      final indexed = downloaded() - before;
      samples.add({
        't': watch.elapsedMilliseconds,
        'complete': complete,
        'failed': failed,
        'indexed': indexed,
      });
      if (tick % 10 == 0) {
        debugPrint('bench t=${watch.elapsed.inSeconds}s complete=$complete '
            'failed=$failed indexed=$indexed');
      }
      if (indexed + failed >= _expected) break;
    }
    final totalMs = watch.elapsedMilliseconds;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    SchedulerBinding.instance.removeTimingsCallback(collect);

    final last = samples.last;
    binding.reportData = {
      'download': {
        'expected_files': _expected,
        'indexed_files': last['indexed'],
        'failed_files': last['failed'],
        'listing_ms': listedMs,
        'queueing_ms': queuedMs,
        'transfer_ms': transferredMs,
        'total_ms': totalMs,
        'files_per_second':
            (last['indexed']! / (totalMs / 1000)).toStringAsFixed(1),
        'frames': FrameTimingSummarizer(timings).summary,
        'samples': samples,
      },
    };
  });
}
