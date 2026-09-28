import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_reader_app/models/music_track.dart';
import 'package:music_reader_app/providers/player_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('inserts a track next and disables shuffle to preserve its position',
      () async {
    final audioPlayer = _FakeAudioPlayer()..shuffleEnabled = true;
    final player = PlayerProvider(
      audioPlayer: audioPlayer,
      fadeDuration: Duration.zero,
    );
    final first = _track('1');
    final second = _track('2');
    final next = _track('3');

    await player.playTrack(first, [first, second]);
    await player.playNext(next);

    expect(player.queue.map((track) => track.id), ['1', '3', '2']);
    expect(audioPlayer.shuffleEnabled, isFalse);
    player.dispose();
  });

  test('supports appending selecting moving and removing queue tracks',
      () async {
    final audioPlayer = _FakeAudioPlayer();
    final player = PlayerProvider(
      audioPlayer: audioPlayer,
      fadeDuration: Duration.zero,
    );
    final first = _track('1');
    final second = _track('2');
    final third = _track('3');

    await player.playTrack(first, [first, second]);
    await player.addToQueue(third);
    await player.playAt(2);
    expect(player.current?.id, '3');

    await player.moveQueueItem(2, 1);
    expect(player.queue.map((track) => track.id), ['1', '3', '2']);
    expect(player.current?.id, '3');

    await player.removeFromQueue(1);
    expect(player.queue.map((track) => track.id), ['1', '2']);
    expect(player.current?.id, '2');
    player.dispose();
  });

  test('removes every queued copy of a deleted track', () async {
    final audioPlayer = _FakeAudioPlayer();
    final player = PlayerProvider(
      audioPlayer: audioPlayer,
      fadeDuration: Duration.zero,
    );
    final first = _track('1');
    final second = _track('2');

    await player.playTrack(first, [first, second, first]);
    await player.removeTracksByIds({first.id});

    expect(player.queue.map((track) => track.id), ['2']);
    expect(player.current?.id, '2');
    expect(audioPlayer.sources, hasLength(1));
    player.dispose();
  });

  test('persists application volume changes', () async {
    final audioPlayer = _FakeAudioPlayer();
    double? persistedVolume;
    final player = PlayerProvider(
      audioPlayer: audioPlayer,
      fadeDuration: Duration.zero,
      volume: .4,
      onVolumeChanged: (volume) async => persistedVolume = volume,
    );

    await player.setVolume(.65);

    expect(player.volume, .65);
    expect(audioPlayer.currentVolume, .65);
    expect(persistedVolume, .65);
    player.dispose();
  });

  test('records history only after continuous listened progress', () async {
    final audioPlayer = _FakeAudioPlayer();
    final listened = <String>[];
    final player = PlayerProvider(
      audioPlayer: audioPlayer,
      fadeDuration: Duration.zero,
      onTrackListened: (id) async => listened.add(id),
    );
    final track = _track('1');
    await player.playTrack(track, [track]);

    audioPlayer.emitPosition(const Duration(seconds: 30));
    await Future<void>.delayed(Duration.zero);
    expect(listened, isEmpty, reason: 'A seek must not count as listening');

    for (var second = 31; second <= 60; second++) {
      audioPlayer.emitPosition(Duration(seconds: second));
    }
    await Future<void>.delayed(Duration.zero);

    expect(listened, ['1']);
    player.dispose();
  });

  test('plays a shuffled queue and inserts several tracks in order', () async {
    final audioPlayer = _FakeAudioPlayer()..shuffleEnabled = true;
    final player = PlayerProvider(
      audioPlayer: audioPlayer,
      fadeDuration: Duration.zero,
    );
    final tracks = [for (var i = 1; i <= 5; i++) _track('$i')];

    await player.playShuffled(tracks, random: Random(1));
    expect(audioPlayer.shuffleEnabled, isFalse);
    expect(player.queue.map((track) => track.id).toSet(),
        {'1', '2', '3', '4', '5'});
    expect(player.current?.id, player.queue.first.id);

    final first = player.queue.first.id;
    await player.playNextAll([_track('a'), _track('b')]);
    expect(player.queue.take(3).map((track) => track.id), [first, 'a', 'b']);

    await player.addAllToQueue([_track('c'), _track('d')]);
    expect(player.queue.skip(7).map((track) => track.id), ['c', 'd']);
    player.dispose();
  });

  test('publishes position ticks without notifying provider listeners',
      () async {
    final audioPlayer = _FakeAudioPlayer();
    final player = PlayerProvider(
      audioPlayer: audioPlayer,
      fadeDuration: Duration.zero,
    );
    final track = _track('1');
    await player.playTrack(track, [track]);
    await Future<void>.delayed(Duration.zero);

    var notifications = 0;
    final positions = <Duration>[];
    player.addListener(() => notifications++);
    player.positionListenable
        .addListener(() => positions.add(player.positionListenable.value));

    audioPlayer.emitPosition(const Duration(seconds: 1));
    audioPlayer.emitPosition(const Duration(seconds: 2));
    await Future<void>.delayed(Duration.zero);

    expect(positions, const [Duration(seconds: 1), Duration(seconds: 2)]);
    expect(notifications, 0);
    player.dispose();
  });

  test('announces the current track once for automatic enrichment', () async {
    final announced = <String>[];
    final player = PlayerProvider(
      audioPlayer: _FakeAudioPlayer(),
      fadeDuration: Duration.zero,
      onCurrentTrackChanged: (track) async => announced.add(track.id),
    );
    final first = _track('1');

    await player.playTrack(first, [first]);
    await Future<void>.delayed(const Duration(milliseconds: 450));

    expect(announced, ['1']);
    player.dispose();
  });
}

MusicTrack _track(String id) => MusicTrack(
      id: id,
      title: 'Titre $id',
      uri: 'file:///music/$id.mp3',
      addedAt: DateTime.utc(2026),
    );

class _FakeAudioPlayer extends AudioPlayer {
  final _playerState = StreamController<PlayerState>.broadcast();
  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration?>.broadcast();
  final _loopMode = StreamController<LoopMode>.broadcast();
  final _shuffle = StreamController<bool>.broadcast();
  final _currentIndex = StreamController<int?>.broadcast();
  final List<AudioSource> sources = [];

  bool isPlaying = false;
  bool shuffleEnabled = false;
  int? index;
  double currentVolume = 1;
  Duration currentPosition = Duration.zero;

  @override
  Stream<PlayerState> get playerStateStream => _playerState.stream;

  @override
  Stream<Duration> get positionStream => _position.stream;

  @override
  Stream<Duration?> get durationStream => _duration.stream;

  @override
  Stream<LoopMode> get loopModeStream => _loopMode.stream;

  @override
  Stream<bool> get shuffleModeEnabledStream => _shuffle.stream;

  @override
  Stream<int?> get currentIndexStream => _currentIndex.stream;

  @override
  bool get playing => isPlaying;

  @override
  Duration get position => currentPosition;

  @override
  Duration? get duration => null;

  @override
  double get volume => currentVolume;

  @override
  bool get shuffleModeEnabled => shuffleEnabled;

  @override
  LoopMode get loopMode => LoopMode.off;

  @override
  int? get currentIndex => index;

  @override
  Future<Duration?> setAudioSources(
    List<AudioSource> audioSources, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
    ShuffleOrder? shuffleOrder,
  }) async {
    sources
      ..clear()
      ..addAll(audioSources);
    index = initialIndex ?? (sources.isEmpty ? null : 0);
    _currentIndex.add(index);
    return null;
  }

  @override
  Future<void> insertAudioSource(int insertionIndex, AudioSource source) async {
    sources.insert(insertionIndex, source);
  }

  @override
  Future<void> addAudioSource(AudioSource source) async {
    sources.add(source);
  }

  @override
  Future<void> removeAudioSourceAt(int removedIndex) async {
    sources.removeAt(removedIndex);
    if (sources.isEmpty) {
      index = null;
    } else if (index != null) {
      if (removedIndex < index!) {
        index = index! - 1;
      } else if (removedIndex == index!) {
        index = removedIndex.clamp(0, sources.length - 1);
      }
    }
    _currentIndex.add(index);
  }

  @override
  Future<void> moveAudioSource(int oldIndex, int newIndex) async {
    final source = sources.removeAt(oldIndex);
    sources.insert(newIndex, source);
    if (index == oldIndex) {
      index = newIndex;
    } else if (index != null && oldIndex < index! && newIndex >= index!) {
      index = index! - 1;
    } else if (index != null && oldIndex > index! && newIndex <= index!) {
      index = index! + 1;
    }
    _currentIndex.add(index);
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    if (index != null) this.index = index;
    _currentIndex.add(this.index);
  }

  @override
  Future<void> setShuffleModeEnabled(bool enabled) async {
    shuffleEnabled = enabled;
    _shuffle.add(enabled);
  }

  @override
  Future<void> setVolume(double volume) async {
    currentVolume = volume;
  }

  void emitPosition(Duration position) {
    currentPosition = position;
    _position.add(position);
  }

  @override
  Future<void> play() async {
    isPlaying = true;
    _playerState.add(PlayerState(true, ProcessingState.ready));
  }

  @override
  Future<void> pause() async {
    isPlaying = false;
    _playerState.add(PlayerState(false, ProcessingState.ready));
  }

  @override
  Future<void> stop() async {
    isPlaying = false;
    _playerState.add(PlayerState(false, ProcessingState.idle));
  }

  @override
  Future<void> dispose() async {
    await Future.wait([
      _playerState.close(),
      _position.close(),
      _duration.close(),
      _loopMode.close(),
      _shuffle.close(),
      _currentIndex.close(),
    ]);
  }
}
