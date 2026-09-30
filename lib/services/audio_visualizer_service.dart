import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Live spectrum of the player's own audio session (Android only). The
/// platform visualizer requires the microphone permission, although it only
/// reads what the app itself plays and records nothing.
class AudioVisualizerService {
  const AudioVisualizerService();

  static const _methods = MethodChannel('com.sauvank.musicstream/visualizer');
  static const _events =
      EventChannel('com.sauvank.musicstream/visualizer/levels');

  static final Stream<List<double>> _levels = _events
      .receiveBroadcastStream()
      .map((levels) => List<double>.from(levels as List));

  /// The platform visualizer is a singleton: only its latest owner may stop
  /// it, so a screen leaving during a transition keeps the new one running.
  static Object? _owner;

  bool get supported => Platform.isAndroid;

  /// Band levels between 0 and 1, low frequencies first.
  Stream<List<double>> get levels => _levels;

  Future<bool> granted() async =>
      supported && await Permission.microphone.isGranted;

  /// Prompts once; opens the app settings when Android no longer asks.
  Future<bool> request() async {
    if (!supported) return false;
    final status = await Permission.microphone.request();
    if (status.isPermanentlyDenied) await openAppSettings();
    return status.isGranted;
  }

  Future<bool> start(Object owner, int sessionId) async {
    _owner = owner;
    try {
      return await _methods.invokeMethod<bool>('start', {
            'sessionId': sessionId,
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> stop(Object owner) async {
    if (!identical(_owner, owner)) return;
    _owner = null;
    try {
      await _methods.invokeMethod<void>('stop');
    } on PlatformException {
      // Nothing to release.
    } on MissingPluginException {
      // Not available on this platform.
    }
  }
}
