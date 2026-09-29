import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/models/music_playlist.dart';
import 'package:music_reader_app/services/sync/sync_crypto.dart';
import 'package:music_reader_app/services/sync/sync_payload.dart';

void main() {
  // Few iterations keep tests fast; production uses the default.
  final kdf = SyncKdf(salt: List.filled(16, 7), iterations: 1000);

  test('seals metadata so only the right passphrase opens it', () async {
    final crypto = SyncCrypto();
    final key = await crypto.deriveKey('correct horse', kdf);
    final envelope = await crypto.seal(
      {'secret': 'Evening playlist'},
      key: key,
      kdf: kdf,
    );

    expect(jsonEncode(envelope), isNot(contains('Evening')));
    expect(SyncCrypto.kdfOf(envelope).salt, kdf.salt);
    expect(
        await crypto.open(envelope, key: key), {'secret': 'Evening playlist'});

    final wrong = await crypto.deriveKey('wrong horse', kdf);
    await expectLater(crypto.open(envelope, key: wrong),
        throwsA(isA<SyncPassphraseException>()));
  });

  test('the same passphrase and salt give the same key on every device',
      () async {
    final first = await SyncCrypto().deriveKey('correct horse', kdf);
    final second = await SyncCrypto().deriveKey('correct horse', kdf);
    expect(first, second);
    expect(first, hasLength(32));
  });

  test('latest favorite choice wins and listening counters keep the max', () {
    final merged = SyncPayload.merge(
      SyncPayload(tracks: {
        'a': SyncTrackState(
          favorite: true,
          favoriteAt: DateTime.utc(2026, 1, 1),
          playCount: 5,
          lastPlayedAt: DateTime.utc(2026, 1, 3),
        ),
        'b': const SyncTrackState(favorite: true),
      }),
      SyncPayload(tracks: {
        'a': SyncTrackState(
          favorite: false,
          favoriteAt: DateTime.utc(2026, 1, 2),
          playCount: 3,
          lastPlayedAt: DateTime.utc(2026, 1, 4),
        ),
        'c': const SyncTrackState(playCount: 1),
      }),
    );

    expect(merged.tracks['a']!.favorite, isFalse);
    expect(merged.tracks['a']!.playCount, 5);
    expect(merged.tracks['a']!.lastPlayedAt, DateTime.utc(2026, 1, 4));
    expect(merged.tracks['b']!.favorite, isTrue);
    expect(merged.tracks['c']!.playCount, 1);
  });

  test('playlists keep the latest edit and honour deletions', () {
    MusicPlaylist playlist(String id, String name, int day) => MusicPlaylist(
          id: id,
          name: name,
          trackIds: const [],
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026, 1, day),
        );

    final merged = SyncPayload.merge(
      SyncPayload(
        playlists: [playlist('p1', 'Old name', 1), playlist('p2', 'Gone', 1)],
      ),
      SyncPayload(
        playlists: [
          playlist('p1', 'New name', 2),
          playlist('p3', 'Edited after deletion', 5),
        ],
        deletedPlaylists: {
          'p2': DateTime.utc(2026, 1, 2),
          'p3': DateTime.utc(2026, 1, 4),
        },
      ),
    );

    expect(merged.playlists.map((p) => p.name),
        ['New name', 'Edited after deletion']);
    expect(merged.deletedPlaylists.keys, containsAll(['p2', 'p3']));

    final roundTrip = SyncPayload.fromJson(
        jsonDecode(jsonEncode(merged.toJson())) as Map<String, Object?>);
    expect(roundTrip.playlists.map((p) => p.id), ['p1', 'p3']);
    expect(roundTrip.deletedPlaylists['p2'], DateTime.utc(2026, 1, 2));
  });
}
