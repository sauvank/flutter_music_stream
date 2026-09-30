import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/music_track.dart';

class PlayerProvider extends ChangeNotifier {
  PlayerProvider({
    this.onPositionChanged,
    this.onFadeDurationChanged,
    this.onVolumeChanged,
    this.onTrackListened,
    this.onCurrentTrackChanged,
    this.displayMetadata,
    this.onNowPlayingChanged,
    Duration fadeDuration = const Duration(milliseconds: 500),
    double volume = 1,
    AudioPlayer? audioPlayer,
  })  : _fadeDuration = fadeDuration,
        _volume = volume.clamp(0, 1),
        _player = audioPlayer ?? AudioPlayer() {
    unawaited(_player.setVolume(_volume));
    _subscriptions
        .add(_player.playerStateStream.listen((_) => notifyListeners()));
    _subscriptions.add(_player.positionStream.listen((position) {
      final track = _current;
      _trackListening(track, position);
      final now = DateTime.now();
      if (track != null &&
          now.difference(_lastPersistedAt) >= const Duration(seconds: 5)) {
        _lastPersistedAt = now;
        unawaited(onPositionChanged?.call(track.id, position));
      }
      _position.value = position;
    }));
    _subscriptions.add(_player.durationStream.listen((_) => notifyListeners()));
    _subscriptions.add(_player.loopModeStream.listen((_) => notifyListeners()));
    _subscriptions
        .add(_player.shuffleModeEnabledStream.listen((_) => notifyListeners()));
    _subscriptions.add(_player.currentIndexStream.listen((index) {
      _current = index != null && index < _queue.length ? _queue[index] : null;
      _resetListeningSession(_current);
      _announceTrack();
      notifyListeners();
    }));
  }

  final AudioPlayer _player;
  final ValueNotifier<Duration> _position = ValueNotifier(Duration.zero);
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final Future<void> Function(String id, Duration position)? onPositionChanged;
  final Future<void> Function(Duration duration)? onFadeDurationChanged;
  final Future<void> Function(double volume)? onVolumeChanged;
  final Future<void> Function(String id)? onTrackListened;
  final Future<void> Function(MusicTrack track)? onCurrentTrackChanged;

  /// Translates stored tag placeholders for the system media notification.
  final String Function(String value)? displayMetadata;

  /// Called when the current track or the play/pause state changes, for
  /// surfaces outside the app such as the home screen widget.
  final void Function(MusicTrack? track, bool playing)? onNowPlayingChanged;
  String? _nowPlayingKey;

  @override
  void notifyListeners() {
    super.notifyListeners();
    final callback = onNowPlayingChanged;
    if (callback == null) return;
    final key = '${_current?.id}|${_player.playing}';
    if (key == _nowPlayingKey) return;
    _nowPlayingKey = key;
    callback(_current, _player.playing);
  }

  List<MusicTrack> _queue = [];
  MusicTrack? _current;
  Duration _fadeDuration;
  double _volume;
  int _fadeOperation = 0;
  DateTime _lastPersistedAt = DateTime.fromMillisecondsSinceEpoch(0);
  String? _listeningTrackId;
  Duration? _lastObservedPosition;
  Duration _listenedDuration = Duration.zero;
  bool _historyRecorded = false;
  String? _lastAnnouncedTrackId;
  bool _isDisposed = false;

  MusicTrack? get current => _current;
  bool get playing => _player.playing;

  /// Android audio session of the player, which the visualizer attaches to.
  Stream<int?> get audioSessionIdStream =>
      _player.androidAudioSessionIdStream.distinct();
  Duration get position => _player.position;

  /// Position updates are published separately so that frequent ticks only
  /// rebuild progress widgets instead of every [PlayerProvider] listener.
  ValueListenable<Duration> get positionListenable => _position;
  Duration get duration => _player.duration ?? Duration.zero;
  bool get hasNext => _player.hasNext;
  bool get hasPrevious => _player.hasPrevious;
  bool get shuffleEnabled => _player.shuffleModeEnabled;
  LoopMode get loopMode => _player.loopMode;
  Duration get fadeDuration => _fadeDuration;
  double get volume => _volume;
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
    _resetListeningSession(track, force: true);
    _announceTrack();
    await _playWithFade();
  }

  Future<void> playAll(List<MusicTrack> tracks) async {
    if (tracks.isEmpty) return;
    if (_player.loopMode == LoopMode.one) {
      await _player.setLoopMode(LoopMode.off);
    }
    await playTrack(tracks.first, tracks);
  }

  /// Plays a shuffled copy so the visible queue matches the listening order.
  Future<void> playShuffled(List<MusicTrack> tracks, {Random? random}) async {
    if (tracks.isEmpty) return;
    if (_player.shuffleModeEnabled) {
      await _player.setShuffleModeEnabled(false);
    }
    await playAll(List.of(tracks)..shuffle(random));
  }

  /// Inserts [tracks] after the current one, preserving their order.
  Future<void> playNextAll(List<MusicTrack> tracks) async {
    if (tracks.isEmpty) return;
    if (_queue.isEmpty || _player.currentIndex == null) {
      await playAll(tracks);
      return;
    }
    for (final track in tracks.reversed) {
      await playNext(track);
    }
  }

  Future<void> addAllToQueue(List<MusicTrack> tracks) async {
    if (tracks.isEmpty) return;
    if (_queue.isEmpty) {
      await playAll(tracks);
      return;
    }
    for (final track in tracks) {
      await addToQueue(track);
    }
  }

  Future<void> playRemote(
    MusicTrack track, {
    Map<String, String> headers = const {},
  }) =>
      playRemoteQueue([track], headers: headers);

  /// Streams a server folder as one queue. Tracks already imported may be
  /// passed as local `file:` tracks; authorization headers are only sent to
  /// remote sources.
  Future<void> playRemoteQueue(
    List<MusicTrack> tracks, {
    int startIndex = 0,
    Map<String, String> headers = const {},
  }) async {
    if (tracks.isEmpty) return;
    final index = startIndex.clamp(0, tracks.length - 1);
    _queue = List.of(tracks);
    _current = _queue[index];
    _resetListeningSession(_current, force: true);
    _announceTrack();
    await _player.setAudioSources(
      [
        for (final track in _queue)
          _audioSource(
            track,
            headers: Uri.parse(track.uri).isScheme('file') ? const {} : headers,
          ),
      ],
      initialIndex: index,
    );
    await _playWithFade();
  }

  Future<void> playAt(int index) async {
    if (index < 0 || index >= _queue.length) return;
    final wasPlaying = _player.playing;
    if (wasPlaying && !await _fadeTo(0)) return;
    await _player.seek(Duration.zero, index: index);
    _current = _queue[index];
    _announceTrack();
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

  Future<void> removeTracksByIds(Set<String> ids) async {
    if (ids.isEmpty || !_queue.any((track) => ids.contains(track.id))) return;
    _fadeOperation++;
    if (_current != null && ids.contains(_current!.id)) {
      await _player.pause();
    }
    for (var index = _queue.length - 1; index >= 0; index--) {
      if (ids.contains(_queue[index].id)) await removeFromQueue(index);
    }
    if (_queue.isEmpty) await _player.stop();
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
        await _player.setVolume(_volume);
      }
      return;
    }
    await _playWithFade();
  }

  Future<void> setFadeDuration(Duration duration) async {
    if (_fadeDuration == duration) return;
    _fadeDuration = duration;
    _fadeOperation++;
    await _player.setVolume(_volume);
    notifyListeners();
    await onFadeDurationChanged?.call(duration);
  }

  Future<void> setVolume(double volume) async {
    final normalized = volume.clamp(0, 1).toDouble();
    if (_volume == normalized) return;
    _volume = normalized;
    _fadeOperation++;
    await _player.setVolume(normalized);
    notifyListeners();
    await onVolumeChanged?.call(normalized);
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
      await _player.setVolume(_volume);
      unawaited(_player.play());
      return;
    }
    await _player.setVolume(0);
    unawaited(_player.play());
    await _fadeTo(_volume);
  }

  Future<void> _changeTrack(Future<void> Function() change) async {
    final wasPlaying = _player.playing;
    if (wasPlaying && !await _fadeTo(0)) return;
    await change();
    if (wasPlaying) await _fadeTo(_volume);
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
          artist: displayMetadata?.call(track.artist) ?? track.artist,
          album: displayMetadata?.call(track.album) ?? track.album,
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
    _announceTrack();
  }

  void _announceTrack() {
    final track = _current;
    if (track == null) {
      _lastAnnouncedTrackId = null;
      return;
    }
    if (_lastAnnouncedTrackId == track.id) return;
    _lastAnnouncedTrackId = track.id;
    unawaited(Future<void>.delayed(const Duration(milliseconds: 400), () async {
      if (!_isDisposed && _current?.id == track.id) {
        await onCurrentTrackChanged?.call(track);
      }
    }));
  }

  void _resetListeningSession(MusicTrack? track, {bool force = false}) {
    if (!force && track?.id == _listeningTrackId) return;
    _listeningTrackId = track?.id;
    _lastObservedPosition = null;
    _listenedDuration = Duration.zero;
    _historyRecorded = false;
  }

  void _trackListening(MusicTrack? track, Duration position) {
    if (track == null) return;
    if (track.id != _listeningTrackId) _resetListeningSession(track);
    final previous = _lastObservedPosition;
    _lastObservedPosition = position;
    if (!_player.playing || _historyRecorded || previous == null) return;

    final progress = position - previous;
    if (progress <= Duration.zero || progress > const Duration(seconds: 2)) {
      return;
    }
    _listenedDuration += progress;
    final knownDuration = _player.duration ??
        (track.durationMs == null
            ? null
            : Duration(milliseconds: track.durationMs!));
    final halfDuration = knownDuration != null && knownDuration > Duration.zero
        ? Duration(
            microseconds: (knownDuration.inMicroseconds / 2).round(),
          )
        : const Duration(seconds: 30);
    final required = halfDuration < const Duration(seconds: 30)
        ? halfDuration
        : const Duration(seconds: 30);
    if (_listenedDuration < required) return;
    _historyRecorded = true;
    unawaited(onTrackListened?.call(track.id));
  }

  @override
  void dispose() {
    _isDisposed = true;
    _fadeOperation++;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_player.dispose());
    _position.dispose();
    super.dispose();
  }
}
