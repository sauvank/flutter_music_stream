import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/music_track.dart';

class PlayerProvider extends ChangeNotifier {
  PlayerProvider({this.onPositionChanged}) {
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
    _subscriptions.add(_player.currentIndexStream.listen((index) {
      if (index != null && index < _queue.length) _current = _queue[index];
      notifyListeners();
    }));
  }

  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final Future<void> Function(String id, Duration position)? onPositionChanged;
  List<MusicTrack> _queue = [];
  MusicTrack? _current;
  DateTime _lastPersistedAt = DateTime.fromMillisecondsSinceEpoch(0);

  MusicTrack? get current => _current;
  bool get playing => _player.playing;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  bool get hasNext => _player.hasNext;
  bool get hasPrevious => _player.hasPrevious;

  Future<void> playTrack(MusicTrack track, List<MusicTrack> library) async {
    final startIndex = library.indexWhere((item) => item.id == track.id);
    _queue = List.of(library);
    final sources = library
        .map((item) => AudioSource.uri(
              Uri.parse(item.uri),
              tag: MediaItem(
                  id: item.id,
                  title: item.title,
                  artist: item.artist,
                  album: item.album),
            ))
        .toList();
    await _player.setAudioSources(
      sources,
      initialIndex: startIndex < 0 ? 0 : startIndex,
      initialPosition: Duration(milliseconds: track.lastPositionMs),
      preload: true,
    );
    _current = track;
    await _player.play();
  }

  Future<void> toggle() => _player.playing ? _player.pause() : _player.play();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> next() => _player.seekToNext();
  Future<void> previous() => _player.seekToPrevious();

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_player.dispose());
    super.dispose();
  }
}
