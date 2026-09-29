import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Pushes the now-playing state to the Android home screen widget.
class HomeWidgetService {
  const HomeWidgetService();

  static const _channel = MethodChannel('com.sauvank.musicstream/widget');

  /// Asks the launcher to add the widget. False when unsupported.
  Future<bool> requestPin() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('pin') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> update({
    required String? title,
    required String? artist,
    required String? artworkUri,
    required bool playing,
    required String idleTitle,
  }) async {
    if (!Platform.isAndroid) return;
    final artwork = Uri.tryParse(artworkUri ?? '');
    try {
      await _channel.invokeMethod<void>('update', {
        'title': title ?? idleTitle,
        'artist': artist ?? '',
        'artworkPath': artwork?.scheme == 'file' ? artwork!.toFilePath() : null,
        'playing': playing,
      });
    } on PlatformException catch (error) {
      debugPrint('Home widget update failed: ${error.code}');
    } on MissingPluginException {
      // Widget channel unavailable (tests, other embeddings).
    }
  }
}
