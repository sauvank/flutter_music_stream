import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/music_track.dart';

class PlayerProvider extends ChangeNotifier {
  PlayerProvider({
    this.onPositionChanged,
    this.onFadeDurationChanged,
    Duration fadeDuration = const Duration(milliseconds: 500),
    AudioPlayer? audioPlayer,
  })  : _fadeDuration = fadeDuration,
        _player = audioPlayer ?? AudioPlayer() {
    _subscriptions
        .add(_player.playerStateStream.listen((_) => notifyListeners()));
    _subscriptions.add(_player.positionStream.listen((position) {
      final track = _current;
      final now = DateTime.now();
      if (track != null &&
          now.difference(_lastPersistedAt) >= const Duration(seconds: 5)) {
        _lastPersistedAt = now;
        unawaited(onPositionChanged?.call(track.id, position));
      }
      notifyListeners();
    }));
    _subscriptions.add(_player.durationStream.listen((_) => notifyListeners()));
    _subscriptions.add(_player.loopModeStream.listen((_) => notifyListeners()));
    _subscriptions
        .add(_player.shuffleModeEnabledStream.listen((_) => notifyListeners()));
    _subscriptions.add(_player.currentIndexStream.listen((index) {
      _current = index != null && index < _queue.length ? _queue[index] : null;
      notifyListeners();
    }));
  }

  final AudioPlayer _player;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final Future<void> Function(String id, Duration position)? onPositionChanged;
  final Future<void> Function(Duration duration)? onFadeDurationChanged;
  List<MusicTrack> _queue = [];
  MusicTrack? _current;
  Duration _fadeDuration;
  int _fadeOperation = 0;
  DateTime _lastPersistedAt = DateTime.fromMillisecondsSinceEpoch(0);

  MusicTrack? get current => _current;
  bool get playing => _player.playing;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  bool get hasNext => _player.hasNext;
  bool get hasPrevious => _player.hasPrevious;
  bool get shuffleEnabled => _player.shuffleModeEnabled;
  LoopMode get loopMode => _player.loopMode;
  Duration get fadeDuration => _fadeDuration;
  List<MusicTrack> get queue => List.unmodifiable(_queue);
  int? get currentIndex => _player.currentIndex;

  Future<void> playTrack(MusicTrack track, List<MusicTrack> library) async {
    final startIndex = library.indexWhere((item) => item.id == track.id);
    _queue = List.of(library);
    final sources = library.map(_audioSource).toList();
    await _player.setAudioSources(
      sources,
      initialIndex: startIndex < 0 ? 0 : startIndex,
      initialPosition: Duration(milliseconds: track.lastPositionMs),
      preload: true,
    );
    _current = track;
    await _playWithFade();
  }

  Future<void> playAll(List<MusicTrack> tracks) async {
    if (tracks.isEmpty) return;
    if (_player.loopMode == LoopMode.one) {
      await _player.setLoopMode(LoopMode.off);
    }
    await playTrack(tracks.first, tracks);
  }

  Future<void> playRemote(
    MusicTrack track, {
    Map<String, String> headers = const {},
  }) async {
    _queue = [track];
    _current = track;
    await _player.setAudioSources([
      _audioSource(track, headers: headers),
    ]);
    await _playWithFade();
  }

  Future<void> playAt(int index) async {
    if (index < 0 || index >= _queue.length) return;
    final wasPlaying = _player.playing;
    if (wasPlaying && !await _fadeTo(0)) return;
    await _player.seek(Duration.zero, index: index);
    _current = _queue[index];
    notifyListeners();
    if (wasPlaying) {
      await _fadeTo(1);
    } else {
      await _playWithFade();
    }
  }

  Future<void> playNext(MusicTrack track) async {
    final index = _player.currentIndex;
    if (_queue.isEmpty || index == null) {
      await playTrack(track, [track]);
      return;
    }
    if (_player.shuffleModeEnabled) {
      await _player.setShuffleModeEnabled(false);
    }
    final insertionIndex = (index + 1).clamp(0, _queue.length);
    await _player.insertAudioSource(insertionIndex, _audioSource(track));
    _queue.insert(insertionIndex, track);
    notifyListeners();
  }

  Future<void> addToQueue(MusicTrack track) async {
    if (_queue.isEmpty) {
      await playTrack(track, [track]);
      return;
    }
    await _player.addAudioSource(_audioSource(track));
    _queue.add(track);
    notifyListeners();
  }

  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= _queue.length) return;
    final removed = _queue.removeAt(index);
    if (_queue.isEmpty) _current = null;
    notifyListeners();
    try {
      await _player.removeAudioSourceAt(index);
    } catch (_) {
      _queue.insert(index, removed);
      _syncCurrentTrack();
      notifyListeners();
      rethrow;
    }
    _syncCurrentTrack();
    notifyListeners();
  }

  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _queue.length) return;
    if (newIndex < 0 || newIndex >= _queue.length || oldIndex == newIndex) {
      return;
    }
    final track = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, track);
    notifyListeners();
    try {
      await _player.moveAudioSource(oldIndex, newIndex);
    } catch (_) {
      _queue.removeAt(newIndex);
      _queue.insert(oldIndex, track);
      _syncCurrentTrack();
      notifyListeners();
      rethrow;
    }
    _syncCurrentTrack();
    notifyListeners();
  }

  Future<void> toggle() async {
    if (_player.playing) {
      if (await _fadeTo(0)) {
        await _player.pause();
        await _player.setVolume(1);
      }
      return;
    }
    await _playWithFade();
  }

  Future<void> setFadeDuration(Duration duration) async {
    if (_fadeDuration == duration) return;
    _fadeDuration = duration;
    _fadeOperation++;
    await _player.setVolume(1);
    notifyListeners();
    await onFadeDurationChanged?.call(duration);
  }

  Future<void> toggleShuffle() async {
    final enabled = !_player.shuffleModeEnabled;
    if (enabled) await _player.shuffle();
    await _player.setShuffleModeEnabled(enabled);
  }

  Future<void> cycleLoopMode() =>
      _player.setLoopMode(switch (_player.loopMode) {
        LoopMode.off => LoopMode.all,
        LoopMode.all => LoopMode.one,
        LoopMode.one => LoopMode.off,
      });

  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> next() => _changeTrack(_player.seekToNext);
  Future<void> previous() => _changeTrack(_player.seekToPrevious);

  Future<void> _playWithFade() async {
    _fadeOperation++;
    if (_fadeDuration == Duration.zero) {
      await _player.setVolume(1);
      unawaited(_player.play());
      return;
    }
    await _player.setVolume(0);
    unawaited(_player.play());
    await _fadeTo(1);
  }

  Future<void> _changeTrack(Future<void> Function() change) async {
    final wasPlaying = _player.playing;
    if (wasPlaying && !await _fadeTo(0)) return;
    await change();
    if (wasPlaying) await _fadeTo(1);
  }

  Future<bool> _fadeTo(double target) async {
    final operation = ++_fadeOperation;
    if (_fadeDuration == Duration.zero) {
      await _player.setVolume(target);
      return operation == _fadeOperation;
    }

    final start = _player.volume;
    final steps = (_fadeDuration.inMilliseconds / 50).ceil().clamp(1, 20);
    final delay = Duration(
      microseconds: (_fadeDuration.inMicroseconds / steps).round(),
    );
    for (var step = 1; step <= steps; step++) {
      await Future<void>.delayed(delay);
      if (operation != _fadeOperation) return false;
      final progress = step / steps;
      await _player.setVolume(start + (target - start) * progress);
    }
    return operation == _fadeOperation;
  }

  AudioSource _audioSource(
    MusicTrack track, {
    Map<String, String> headers = const {},
  }) =>
      AudioSource.uri(
        Uri.parse(track.uri),
        headers: headers,
        tag: MediaItem(
          id: track.id,
          title: track.title,
          artist: track.artist,
          album: track.album,
          duration: track.durationMs == null
              ? null
              : Duration(milliseconds: track.durationMs!),
          artUri:
              track.artworkUri == null ? null : Uri.parse(track.artworkUri!),
        ),
      );

  void _syncCurrentTrack() {
    final index = _player.currentIndex;
    _current = index != null && index < _queue.length ? _queue[index] : null;
  }

  @override
  void dispose() {
    _fadeOperation++;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_player.dispose());
    super.dispose();
  }
}
