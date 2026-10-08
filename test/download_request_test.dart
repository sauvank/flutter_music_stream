import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_reader_app/l10n/l10n.dart';
import 'package:music_reader_app/models/remote_audio_entry.dart';
import 'package:music_reader_app/models/server_profile.dart';
import 'package:music_reader_app/providers/download_queue_provider.dart';
import 'package:music_reader_app/providers/download_request.dart';
import 'package:music_reader_app/providers/library_provider.dart';
import 'package:music_reader_app/providers/server_provider.dart';
import 'package:music_reader_app/screens/servers_screen.dart';
import 'package:music_reader_app/services/library_service.dart';
import 'package:music_reader_app/services/playlist_service.dart';
import 'package:music_reader_app/services/remote_server_service.dart';
import 'package:music_reader_app/services/server_profile_service.dart';

const profile = ServerProfile(
    id: 'demo',
    name: 'Demo',
    baseUrl: 'https://example.com/music',
    type: ServerType.http);
final entry = RemoteAudioEntry(
    name: 'Demo',
    uri: Uri.parse('https://example.com/music/'),
    isDirectory: true);

class _Remote extends RemoteServerService {
  Completer<List<RemoteAudioEntry>> scan = Completer();
  Uri? scannedRoot;
  String? receivedPassword;
  @override
  Future<List<RemoteAudioEntry>> listRecursively(
      ServerProfile profile, Uri root, String password,
      {int maximumEntries = 10000}) {
    scannedRoot = root;
    receivedPassword = password;
    return scan.future;
  }
}

class _Queue extends DownloadQueueProvider {
  _Queue(super.library);
  final accepted = <RemoteAudioEntry>[];
  @override
  Future<int> enqueueAll(List<RemoteAudioEntry> files,
      {Map<String, String> headers = const {}}) async {
    accepted.addAll(files);
    return files.length;
  }
}

class _Servers extends ServerProvider {
  _Servers(super.profilesService, super.remoteService);
  @override
  Future<String> passwordFor(ServerProfile profile) async => 'example-password';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LibraryProvider library;
  late _Remote remote;
  late _Queue queue;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    library = LibraryProvider(LibraryService(), PlaylistService());
    remote = _Remote();
    queue = _Queue(library);
  });
  tearDown(() {
    queue.dispose();
    library.dispose();
  });

  test('preparation returns immediately and ignores duplicate active requests',
      () async {
    bool start() => queue.startRequest(
        entry: entry,
        profile: profile,
        password: () async => 'example-password',
        remote: remote);
    expect(start(), isTrue);
    expect(start(), isFalse);
    expect(queue.requests.single.stage, DownloadRequestStage.scanning);
    expect(queue.accepted, isEmpty);
    await Future<void>.delayed(Duration.zero);
    final file = RemoteAudioEntry(
        name: 'Track.mp3',
        uri: entry.uri.resolve('Track.mp3'),
        isDirectory: false);
    remote.scan.complete([file]);
    await Future<void>.delayed(Duration.zero);
    expect(queue.accepted, [file]);
    expect(queue.requests, isEmpty);
    expect(remote.receivedPassword, 'example-password');
  });

  test('empty and failed scans remain visible and can be dismissed or retried',
      () async {
    queue.startRequest(
        entry: entry,
        profile: profile,
        password: () async => '',
        remote: remote);
    remote.scan.completeError(StateError('too many entries'));
    await Future<void>.delayed(Duration.zero);
    final request = queue.requests.single;
    expect(request.stage, DownloadRequestStage.failed);
    remote.scan = Completer()..complete([]);
    await queue.retryRequest(request);
    expect(request.stage, DownloadRequestStage.complete);
    expect(request.total, 0);
    queue.dismissRequest(request.id);
    expect(queue.requests, isEmpty);
  });

  testWidgets('download entire server uses its root without opening a dialog',
      (tester) async {
    final servers = _Servers(ServerProfileService(), remote)
      ..profiles.add(profile);
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<LibraryProvider>.value(value: library),
          ChangeNotifierProvider<DownloadQueueProvider>.value(value: queue),
          ChangeNotifierProvider<ServerProvider>.value(value: servers),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ServersScreen()),
        )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Télécharger tout le serveur'));
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);
    expect(Navigator.of(tester.element(find.byType(ServersScreen))).canPop(),
        isFalse);
    expect(remote.scannedRoot, Uri.parse('https://example.com/music/'));
    expect(queue.requests.single.active, isTrue);
    // Simulate leaving the screen before inventory completes.
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      remote.scan.complete([]);
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    expect(queue.requests.single.stage, DownloadRequestStage.complete);
    servers.dispose();
  });
}
