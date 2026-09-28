import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/models/music_track.dart';
import 'package:music_reader_app/services/library_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('large library saves remain ordered and can be loaded', () async {
    SharedPreferences.setMockInitialValues({});
    final service = LibraryService();
    final tracks = List.generate(
      120,
      (index) => MusicTrack(
        id: '$index',
        title: 'Track $index',
        uri: 'file:///music/$index.mp3',
        addedAt: DateTime.utc(2026),
        metadataRead: true,
      ),
    );

    await Future.wait([
      service.save(tracks),
      service.save([...tracks, tracks.first.copyWith(favorite: true)]),
    ]);

    final loaded = await service.load();
    expect(loaded, hasLength(121));
    expect(loaded.last.favorite, isTrue);
  });

  test('positions persist separately and fold back on load', () async {
    SharedPreferences.setMockInitialValues({});
    final service = LibraryService();
    final track = MusicTrack(
      id: 'a',
      title: 'Track',
      uri: 'file:///music/a.mp3',
      addedAt: DateTime.utc(2026),
      metadataRead: true,
    );
    await service.save([track]);
    await service.savePosition('a', 42000);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('music_positions_v1'), isNotNull);

    final reloaded = LibraryService();
    final loaded = await reloaded.load();
    expect(loaded.single.lastPositionMs, 42000);

    await reloaded.save(loaded);
    expect(preferences.getString('music_positions_v1'), isNull);
    expect((await LibraryService().load()).single.lastPositionMs, 42000);
  });
}
