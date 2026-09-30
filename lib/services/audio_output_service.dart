import 'dart:io';

import 'package:flutter/services.dart';

/// Opens Android's audio output picker: Bluetooth devices (an Echo paired
/// with the phone included), wired outputs and cast-capable speakers.
class AudioOutputService {
  const AudioOutputService();

  static const _channel = MethodChannel('com.sauvank.musicstream/output');

  bool get supported => Platform.isAndroid;

  /// False when no picker or settings screen could be opened.
  Future<bool> showOutputSwitcher() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('showOutputSwitcher') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
