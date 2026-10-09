import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/music_track.dart';
import '../services/audio_codec_support.dart';

class PlayerProvider extends ChangeNotifier {
  PlayerProvider({
    this.onPositionChanged,
    this.onFadeDurationChanged,
    this.onVolumeChanged,
    this.onTrackListened,
    this.onCurrentTrackChanged,
    this.displayMetadata,
    this.onNowPlayingChanged,
    this.onQueueChanged,
    this.onAudiobookSpeedChanged,
    double audiobookSpeed = 1,
    Duration fadeDuration = const Duration(milliseconds: 500),
    double volume = 1,
    AudioPlayer? audioPlayer,
    AudioCodecSupport codecSupport = const AudioCodecSupport(),
  })  : _codecSupport = codecSupport,
        _fadeDuration = fadeDuration,
        _audiobookSpeed = audiobookSpeed,
        _volume = volume.clamp(0, 1),
        _player = audioPlayer ?? AudioPlayer() {
    unawaited(_player.setVolume(_volume));
    _subscriptions.add(_player.playerStateStream.listen((state) {
      notifyListeners();
      // Audiobooks are resumed days later, so pausing or finishing must not
      // wait for the next 5-second tick to remember the position.
      // Only a real pause counts: a queue restored at launch is idle at
      // 0:00 until it loads, and saving that would lose the bookmark.
      final paused = _wasPlaying && !state.playing;
      _wasPlaying = state.playing;
      final track = _current;
      if (paused && track != null && track.isAudiobook) {
        _lastPersistedAt = DateTime.now();
        unawaited(onPositionChanged?.call(track.id, _player.position));
      }
    }));
    _subscriptions.add(_player.positionStream.listen((position) {
      final track = _current;
      _trackListening(track, position);
      // Sticky until the track changes: a first tick of the next track may
      // arrive before its index does.
      final duration = _player.duration;
      if (duration != null &&
          position >= duration - const Duration(seconds: 3)) {
        _reachedTrackEnd = true;
      }
      final now = DateTime.now();
      if (track != null &&
          _player.playing &&
          now.difference(_lastPersistedAt) >= const Duration(seconds: 5)) {
        _lastPersistedAt = now;
        unawaited(onPositionChanged?.call(track.id, position));
      }
      final sleepChapter = _sleepChapter;
      if (sleepChapter != null &&
          track != null &&
          track.chapterIndexAt(position.inMilliseconds) > sleepChapter) {
        unawaited(_sleep(fade: false));
      }
      _position.value = position;
    }));
    _subscriptions.add(_player.durationStream.listen((_) => notifyListeners()));
    _subscriptions.add(_player.loopModeStream.listen((_) => notifyListeners()));
    _subscriptions
        .add(_player.shuffleModeEnabledStream.listen((_) => notifyListeners()));
    _subscriptions.add(_player.currentIndexStream.listen((index) {
      // Loading a restored queue first reports index 0; ignore it so the
      // saved current track is not overwritten.
      if (_restoreIndex != null && index != _restoreIndex) return;
      if (_sleepAtTrackEnd && _reachedTrackEnd) {
        _cancelSleepTimer();
        unawaited(_player.pause().then((_) => _player.seek(Duration.zero)));
      }
      _reachedTrackEnd = false;
      _current = index != null && index < _queue.length ? _queue[index] : null;
      _applySpeed();
      _resetListeningSession(_current);
      _announceTrack();
      notifyListeners();
      final track = _current;
      if (track != null && _player.playing) unawaited(_guardFormat(track));
    }));
  }

  static bool _isFlac(MusicTrack track) =>
      Uri.parse(track.uri).path.toLowerCase().endsWith('.flac');

  /// Pauses and reports [track] when this device has no decoder for it.
  /// Returns whether playback may go on.
  Future<bool> _guardFormat(MusicTrack track) async {
    if (!_isFlac(track) || await _codecSupport.canDecodeFlac()) return true;
    if (_isDisposed) return false;
    _fadeOperation++;
    await _player.pause();
    await _player.setVolume(_volume);
    unsupportedFormat.value = track;
    return false;
  }

  final AudioPlayer _player;
  final AudioCodecSupport _codecSupport;

  /// Set when the current track is in a format this device cannot decode, so
  /// the UI can explain the silence. Playback is paused instead of pretending.
  final ValueNotifier<MusicTrack?> unsupportedFormat = ValueNotifier(null);
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

  /// Called when the queue or its current track changes, so the session
  /// can be restored on the next launch.
  final void Function(List<String> trackIds, String? currentId)? onQueueChanged;
  int _queueRevision = 0;
  int? _restoreIndex;
  String? _queueKey;

  @override
  void notifyListeners() {
    super.notifyListeners();
    final queueCallback = onQueueChanged;
    final queueKey = '$_queueRevision|${_current?.id}';
    if (queueCallback != null && queueKey != _queueKey) {
      _queueKey = queueKey;
      queueCallback([for (final track in _queue) track.id], _current?.id);
    }
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
  bool _reachedTrackEnd = false;
  bool _wasPlaying = false;
  Timer? _sleepTimer;
  DateTime? _sleepAt;
  bool _sleepAtTrackEnd = false;

  /// Chapter after which an audiobook pauses, for "end of chapter".
  int? _sleepChapter;
  double _audiobookSpeed;
  final Future<void> Function(double speed)? onAudiobookSpeedChanged;

  MusicTrack? get current => _current;

  /// Speed applies to audiobooks only; music always plays at normal speed.
  double get speed => _current?.isAudiobook == true ? _audiobookSpeed : 1;

  void _applySpeed() {
    final target = speed;
    if (_player.speed != target) unawaited(_player.setSpeed(target));
  }

  /// Chapter of the current audiobook at [position], or -1 without chapters.
  int chapterIndexAt(Duration position) =>
      _current?.chapterIndexAt(position.inMilliseconds) ?? -1;

  Future<void> setSpeed(double speed) async {
    _audiobookSpeed = speed;
    _applySpeed();
    notifyListeners();
    await onAudiobookSpeedChanged?.call(speed);
  }

  /// Jumps by [offset] inside the current track, clamped to its bounds.
  Future<void> skipBy(Duration offset) {
    final total = _player.duration;
    var target = _player.position + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (total != null && target > total) target = total;
    return seek(target);
  }

  /// Starts the chapter at [index] of the current track.
  Future<void> seekToChapter(int index) {
    final chapters = _current?.chapters ?? const <TrackChapter>[];
    if (index < 0 || index >= chapters.length) return Future.value();
    return seek(Duration(milliseconds: chapters[index].startMs));
  }

  /// Like a previous button: restarts the chapter after a few seconds,
  /// otherwise goes to the one before.
  Future<void> previousChapter() {
    final index = chapterIndexAt(_player.position);
    if (index < 0) return skipBy(const Duration(seconds: -30));
    final start = Duration(milliseconds: _current!.chapters[index].startMs);
    if (_player.position - start > const Duration(seconds: 3) || index == 0) {
      return seek(start);
    }
    return seekToChapter(index - 1);
  }

  Future<void> nextChapter() {
    final index = chapterIndexAt(_player.position);
    if (index < 0) return skipBy(const Duration(seconds: 30));
    if (index + 1 >= _current!.chapters.length) return next();
    return seekToChapter(index + 1);
  }

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

  /// When the sleep timer pauses playback, or null without a timed sleep.
  DateTime? get sleepAt => _sleepAt;
  bool get sleepAtTrackEnd => _sleepAtTrackEnd;
  bool get sleepAtChapterEnd => _sleepChapter != null;
  bool get sleepTimerActive =>
      _sleepAt != null || _sleepAtTrackEnd || _sleepChapter != null;

  /// Pauses when the current audiobook chapter ends.
  void setSleepAtChapterEnd() {
    final index = chapterIndexAt(_player.position);
    _cancelSleepTimer();
    if (index >= 0) _sleepChapter = index;
    notifyListeners();
  }

  /// Pauses with a long fade after [delay]; null cancels the sleep timer.
  void setSleepTimer(Duration? delay) {
    _cancelSleepTimer();
    if (delay != null) {
      _sleepAt = DateTime.now().add(delay);
      _sleepTimer = Timer(delay, () => unawaited(_sleep()));
    }
    notifyListeners();
  }

  /// Pauses when the current track ends on its own, not on a manual skip.
  void setSleepAtTrackEnd() {
    _cancelSleepTimer();
    _sleepAtTrackEnd = true;
    notifyListeners();
  }

  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepAt = null;
    _sleepAtTrackEnd = false;
    _sleepChapter = null;
  }

  Future<void> _sleep({bool fade = true}) async {
    _cancelSleepTimer();
    notifyListeners();
    if (!_player.playing) return;
    if (!fade) {
      await _player.pause();
      return;
    }
    if (await _fadeTo(0, duration: const Duration(seconds: 8))) {
      await _player.pause();
      await _player.setVolume(_volume);
    }
  }

  /// Loads a saved queue paused, ready to resume where it stopped.
  Future<void> restoreQueue(List<MusicTrack> tracks, String? currentId) async {
    if (tracks.isEmpty || _queue.isNotEmpty) return;
    final index =
        tracks.indexWhere((track) => track.id == currentId).clamp(0, 1 << 30);
    final track = tracks[index];
    _queue = List.of(tracks);
    _queueRevision++;
    _current = track;
    _resetListeningSession(track, force: true);
    _restoreIndex = index;
    try {
      final position = Duration(milliseconds: track.lastPositionMs);
      await _player.setAudioSources(
        tracks.map(_audioSource).toList(),
        initialIndex: index,
        initialPosition: position,
        preload: false,
      );
      if (_player.currentIndex != index) {
        await _player.seek(position, index: index);
      }
    } finally {
      _restoreIndex = null;
    }
    _applySpeed();
    notifyListeners();
  }

  Future<void> playTrack(MusicTrack track, List<MusicTrack> library) async {
    // An audiobook never runs on into music, only into the next chapters of
    // the same book (same album and author) when they are queued with it.
    if (track.isAudiobook) {
      final total = track.durationMs;
      // Only a genuinely completed book starts over. Treating the last
      // 30 seconds as finished made a tap in the audiobook list discard a
      // valid bookmark, unlike resuming from the mini player.
      if (total != null &&
          total > 1000 &&
          track.lastPositionMs >= total - 1000) {
        track = track.copyWith(lastPositionMs: 0);
      }
      final start = track;
      library = track.album == MusicTrack.unknownAlbum
          ? [track]
          : [
              for (final item in library)
                if (item.id == start.id)
                  start
                else if (item.isAudiobook &&
                    item.album == start.album &&
                    item.artist == start.artist)
                  item,
            ];
      if (!library.any((item) => item.id == track.id)) library = [track];
      // Chapters are read in order.
      if (library.length > 1 && _player.shuffleModeEnabled) {
        await _player.setShuffleModeEnabled(false);
      }
    }
    final startIndex = library.indexWhere((item) => item.id == track.id);
    _queue = List.of(library);
    _queueRevision++;
    final sources = library.map(_audioSource).toList();
    await _player.setAudioSources(
      sources,
      initialIndex: startIndex < 0 ? 0 : startIndex,
      initialPosition: Duration(milliseconds: track.lastPositionMs),
      preload: true,
    );
    _current = track;
    _applySpeed();
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
    _queueRevision++;
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
    _queueRevision++;
    notifyListeners();
  }

  Future<void> addToQueue(MusicTrack track) async {
    if (_queue.isEmpty) {
      await playTrack(track, [track]);
      return;
    }
    await _player.addAudioSource(_audioSource(track));
    _queue.add(track);
    _queueRevision++;
    notifyListeners();
  }

  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= _queue.length) return;
    final removed = _queue.removeAt(index);
    _queueRevision++;
    if (_queue.isEmpty) _current = null;
    notifyListeners();
    try {
      await _player.removeAudioSourceAt(index);
    } catch (_) {
      _queue.insert(index, removed);
      _queueRevision++;
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
    _queueRevision++;
    notifyListeners();
    try {
      await _player.moveAudioSource(oldIndex, newIndex);
    } catch (_) {
      _queue.removeAt(newIndex);
      _queue.insert(oldIndex, track);
      _queueRevision++;
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
    // Picking a book back up repeats the last words before the pause.
    // Only once loaded: before that the player may report 0:00.
    if (_current?.isAudiobook == true &&
        _player.processingState == ProcessingState.ready &&
        _player.position > const Duration(seconds: 3)) {
      await _player.seek(_player.position - const Duration(seconds: 3));
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

  Future<void> seek(Duration position) {
    _reachedTrackEnd = false;
    // Jumping elsewhere moves "end of chapter" to the chapter landed in.
    if (_sleepChapter != null) {
      final index = chapterIndexAt(position);
      if (index >= 0) _sleepChapter = index;
    }
    // An explicit jump is a new bookmark, even while paused.
    final track = _current;
    if (track != null && track.isAudiobook) {
      _lastPersistedAt = DateTime.now();
      unawaited(onPositionChanged?.call(track.id, position));
    }
    return _player.seek(position);
  }

  Future<void> next() => _changeTrack(_player.seekToNext);
  Future<void> previous() => _changeTrack(_player.seekToPrevious);

  Future<void> _playWithFade() async {
    final track = _current;
    if (track != null && !await _guardFormat(track)) return;
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

  Future<bool> _fadeTo(double target, {Duration? duration}) async {
    final fadeDuration = duration ?? _fadeDuration;
    final operation = ++_fadeOperation;
    if (fadeDuration == Duration.zero) {
      await _player.setVolume(target);
      return operation == _fadeOperation;
    }

    final start = _player.volume;
    final steps = (fadeDuration.inMilliseconds / 50).ceil().clamp(1, 200);
    final delay = Duration(
      microseconds: (fadeDuration.inMicroseconds / steps).round(),
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
    _applySpeed();
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
    _sleepTimer?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_player.dispose());
    _position.dispose();
    unsupportedFormat.dispose();
    super.dispose();
  }
}
