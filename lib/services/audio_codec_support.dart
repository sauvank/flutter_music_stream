import 'dart:io';

import 'package:flutter/services.dart';

/// Asks Android whether a bundled software or system decoder is available.
/// Keeps playback from appearing active when neither can handle the format.
class AudioCodecSupport {
  const AudioCodecSupport();

  static const _channel = MethodChannel('com.sauvank.musicstream/output');
  static Future<bool>? _flac;

  /// True when unknown (other platforms, no answer): never block playback on
  /// a guess.
  Future<bool> canDecodeFlac() => _flac ??= _canDecode('audio/flac');

  Future<bool> _canDecode(String mime) async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>('canDecode', {'mime': mime}) ??
          true;
    } on PlatformException {
      return true;
    } on MissingPluginException {
      return true;
    }
  }
}
