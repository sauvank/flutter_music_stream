import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/models/music_playlist.dart';
import 'package:music_reader_app/models/music_track.dart';
import 'package:music_reader_app/providers/library_provider.dart';
import 'package:music_reader_app/screens/library_screen.dart';
import 'package:music_reader_app/services/library_service.dart';
import 'package:music_reader_app/services/playlist_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('long press selects tracks instead of deleting them',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final library = LibraryProvider(_MemoryLibraryService(), _NoPlaylists());
    await library.load();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: library,
      child: const MaterialApp(home: Scaffold(body: LibraryScreen())),
    ));
    await tester.pumpAndSettle();

    final allTracks = find.text('Tous les morceaux');
    await tester.scrollUntilVisible(
      allTracks,
      200,
      scrollable: find
          .byWidgetPredicate((widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down)
          .first,
    );
    await tester.pumpAndSettle();
    final tiles = find.descendant(
      of: find.byType(SliverList),
      matching: find.text('Night Drive'),
    );

    await tester.longPress(tiles.last);
    await tester.pumpAndSettle();
    expect(find.text('1 sélectionné'), findsOneWidget);
    expect(find.text('Supprimer ce morceau ?'), findsNothing);

    await tester.tap(find.text('Morning Run').last);
    await tester.pumpAndSettle();
    expect(find.text('2 sélectionnés'), findsOneWidget);

    await tester.tap(find.byTooltip('Annuler la sélection'));
    await tester.pumpAndSettle();
    expect(find.textContaining('sélectionné'), findsNothing);
  });
}

class _MemoryLibraryService extends LibraryService {
  @override
  Future<List<MusicTrack>> load() async => [
        MusicTrack(
          id: 'night',
          title: 'Night Drive',
          uri: 'file:///media/music/night.mp3',
          addedAt: DateTime.utc(2026, 1, 1),
          metadataRead: true,
        ),
        MusicTrack(
          id: 'morning',
          title: 'Morning Run',
          uri: 'file:///media/music/morning.mp3',
          addedAt: DateTime.utc(2026, 1, 2),
          metadataRead: true,
        ),
      ];

  @override
  Future<void> save(List<MusicTrack> tracks) async {}
}

class _NoPlaylists extends PlaylistService {
  @override
  Future<List<MusicPlaylist>> load() async => [];

  @override
  Future<void> save(List<MusicPlaylist> playlists) async {}
}
