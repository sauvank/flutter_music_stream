import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Access to audio files in shared storage, needed to read them by path:
/// READ_MEDIA_AUDIO on Android 13+, READ_EXTERNAL_STORAGE up to Android 12.
/// Other platforms and picked files (copied by the picker) need neither.
class AudioAccess {
  const AudioAccess._();

  static const _permissions = [Permission.audio, Permission.storage];

  static Future<bool> request() async {
    if (!Platform.isAndroid) return true;
    final statuses = await _permissions.request();
    return statuses.values.any(_usable);
  }

  /// Checks without prompting, for background rescans.
  static Future<bool> granted() async {
    if (!Platform.isAndroid) return true;
    for (final permission in _permissions) {
      if (_usable(await permission.status)) return true;
    }
    return false;
  }

  static bool _usable(PermissionStatus status) =>
      status.isGranted || status.isLimited;

  static Future<bool> openSettings() => openAppSettings();
}
