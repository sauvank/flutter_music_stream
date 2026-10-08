import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:music_reader_app/l10n/l10n.dart';
import 'package:music_reader_app/providers/download_queue_provider.dart';
import 'package:music_reader_app/providers/library_provider.dart';
import 'package:music_reader_app/screens/downloads_sheet.dart';
import 'package:music_reader_app/services/library_service.dart';
import 'package:music_reader_app/services/playlist_service.dart';

class _Queue extends DownloadQueueProvider {
  _Queue(super.library, this.items);
  List<TaskRecord> items;
  final calls = <String>[];
  bool failAction = false;
  final importing = <String>{};
  @override
  bool isImporting(String taskId) => importing.contains(taskId);

  @override
  List<TaskRecord> get records => items;
  @override
  int get activeCount => items.where((r) => r.status.isNotFinalState).length;
  @override
  bool get hasFailed => items.any((r) => r.status == TaskStatus.failed);
  @override
  bool get hasClearable => items.any((r) => r.status == TaskStatus.complete);
  @override
  Future<void> pause(String taskId) async {
    if (failAction) throw StateError('unavailable');
    calls.add('pause:$taskId');
  }

  @override
  Future<void> resume(String taskId) async => calls.add('resume:$taskId');
  @override
  Future<void> retry(String taskId) async => calls.add('retry:$taskId');
  @override
  Future<void> cancel(String taskId) async => calls.add('cancel:$taskId');
  @override
  Future<void> cancelAll() async => calls.add('cancelAll');
}

TaskRecord _record(String name, TaskStatus status, [double progress = .42]) =>
    TaskRecord(
      DownloadTask(
          taskId: name,
          url: 'https://example.com/Album/$name.mp3',
          displayName: '$name.mp3',
          allowPause: true),
      status,
      progress,
      10 * 1024 * 1024,
    );

void main() {
  late LibraryProvider library;
  late _Queue queue;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    library = LibraryProvider(LibraryService(), PlaylistService());
    queue = _Queue(library, []);
  });
  tearDown(() {
    queue.dispose();
    library.dispose();
  });

  Future<void> open(WidgetTester tester,
      {Size size = const Size(430, 932),
      double textScale = 1,
      bool settle = true}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<LibraryProvider>.value(value: library),
        ChangeNotifierProvider<DownloadQueueProvider>.value(value: queue),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme:
            ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!),
        home: const Scaffold(body: DownloadQueueShortcut()),
      ),
    ));
    await tester.tap(find.text('Téléchargements'));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  testWidgets(
      'empty queue remains discoverable and guides users back to servers',
      (tester) async {
    await open(tester);
    expect(find.text('Aucun téléchargement.'), findsOneWidget);
    await tester.tap(find.text('Parcourir les serveurs'));
    await tester.pumpAndSettle();
    expect(find.byType(DownloadsSheet), findsNothing);
  });

  testWidgets('filters separate failures, active transfers and history',
      (tester) async {
    queue.items = [
      _record('Finished', TaskStatus.complete, 1),
      _record('Failed', TaskStatus.failed),
      _record('Live', TaskStatus.running)
    ];
    await open(tester);
    expect(find.text('1 téléchargement en cours'), findsWidgets);
    expect(find.text('42 %'), findsOneWidget);
    expect(find.text('4.2 MiB / 10.0 MiB'), findsOneWidget);
    await tester.tap(find.text('Échecs · 1'));
    await tester.pumpAndSettle();
    expect(find.text('Failed.mp3'), findsOneWidget);
    expect(find.text('Live.mp3'), findsNothing);
    await tester.ensureVisible(find.text('Réessayer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(queue.calls, ['retry:Failed']);
    await tester.ensureVisible(find.text('Terminés · 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminés · 1'));
    await tester.pumpAndSettle();
    expect(find.text('Finished.mp3'), findsOneWidget);
    expect(find.text('Failed.mp3'), findsNothing);
    // A finished transfer is not advertised as playable before library import.
    expect(find.text('Disponible hors ligne'), findsNothing);
  });

  testWidgets('pause errors are visible and leave the control usable',
      (tester) async {
    queue.items = [_record('Live', TaskStatus.running)];
    queue.failAction = true;
    await open(tester);
    await tester.tap(find.text('Mettre en pause'));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Action impossible pour le moment. Réessayez dans quelques instants.'),
        findsOneWidget);
    queue.failAction = false;
    await tester.tap(find.text('Mettre en pause'));
    await tester.pumpAndSettle();
    expect(queue.calls, ['pause:Live']);
  });

  testWidgets('running transfer comes before newer queued and paused files',
      (tester) async {
    queue.items = [
      _record('Newest queued', TaskStatus.enqueued),
      _record('Paused', TaskStatus.paused),
      _record('Actually downloading', TaskStatus.running)
    ];
    await open(tester);
    expect(tester.getTopLeft(find.text('Actually downloading.mp3')).dy,
        lessThan(tester.getTopLeft(find.text('Newest queued.mp3')).dy));
  });

  testWidgets('paused downloads can be resumed or canceled', (tester) async {
    queue.items = [_record('Paused', TaskStatus.paused)];
    await open(tester);
    await tester.tap(find.text('Reprendre'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Options du téléchargement'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(queue.calls, ['resume:Paused', 'cancel:Paused']);
  });

  testWidgets('HTTP errors show a useful code without leaking server details',
      (tester) async {
    final failed = _record('Failed', TaskStatus.failed);
    queue.items = [
      TaskRecord(failed.task, failed.status, -1, 0,
          TaskHttpException('https://example.com/private?token=secret', 500))
    ];
    await open(tester);
    expect(
        find.text(
            'Le serveur a répondu avec une erreur HTTP 500. Vous pouvez réessayer.'),
        findsOneWidget);
    expect(find.textContaining('token=secret'), findsNothing);
  });

  testWidgets(
      'finished counter includes completed transfers still being indexed',
      (tester) async {
    queue.items = [
      _record('Indexing', TaskStatus.complete, 1),
      _record('Live', TaskStatus.running)
    ];
    queue.importing.add('Indexing');
    await open(tester, settle: false);
    expect(find.text('Terminés · 1'), findsOneWidget);
    expect(find.text('En cours · 1'), findsOneWidget);
    await tester.tap(find.text('Terminés · 1'));
    await tester.pump();
    expect(find.text('Ajout à la bibliothèque…'), findsOneWidget);
    expect(find.text('Disponible hors ligne'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cancel all requires an explicit confirmation', (tester) async {
    queue.items = [_record('Queued', TaskStatus.enqueued)];
    await open(tester);
    await tester.tap(find.byTooltip('Gérer la file'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tout annuler'));
    await tester.pumpAndSettle();
    expect(queue.calls, isEmpty);
    await tester.tap(find.widgetWithText(FilledButton, 'Tout annuler'));
    await tester.pumpAndSettle();
    expect(queue.calls, ['cancelAll']);
  });

  testWidgets('small screens and large text scroll without overflowing',
      (tester) async {
    queue.items = [
      _record('A very long music filename that needs several lines',
          TaskStatus.paused),
      _record('Failed', TaskStatus.failed),
      _record('Finished', TaskStatus.complete)
    ];
    await open(tester, size: const Size(320, 568), textScale: 2);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1100));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
