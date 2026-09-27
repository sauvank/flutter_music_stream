import 'dart:async';

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
  Duration get position => Duration.zero;

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
