import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keeps Android's foreground state for a whole download batch.
///
/// WorkManager drops its own foreground service between files; once the app
/// is in the background Android refuses to restart it and cuts network
/// access, so the rest of the queue fails. A native dataSync service started
/// while the app is visible spans those gaps.
class DownloadKeepAlive {
  DownloadKeepAlive();

  static const _channel = MethodChannel('com.sauvank.musicstream/downloads');
  bool _held = false;
  bool _busy = false;
  bool? _wanted;
  String _title = '';

  set title(String value) => _title = value;

  /// Holds or releases the service. A refused start (app in background) is
  /// retried on the next call.
  void update(bool active) {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    _wanted = active;
    if (_busy || active == _held) return;
    _busy = true;
    _apply(active).whenComplete(() {
      _busy = false;
      if (_wanted != null && _wanted != _held) update(_wanted!);
    });
  }

  Future<void> _apply(bool active) async {
    try {
      if (active) {
        _held =
            await _channel.invokeMethod<bool>('hold', {'title': _title}) ??
                false;
      } else {
        await _channel.invokeMethod<void>('release');
        _held = false;
      }
    } catch (error) {
      debugPrint('Download keep-alive unavailable: ${error.runtimeType}');
      // Stop retrying where the channel does not exist (tests, other hosts).
      _wanted = _held;
    }
  }
}
