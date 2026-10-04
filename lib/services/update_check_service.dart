import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks Google Play for an update available to this installation/account.
/// No release manifest needs to be maintained or deployed separately.
class UpdateCheckService {
  const UpdateCheckService();

  static const _channel = MethodChannel('com.sauvank.musicstream/updates');
  static const storeUrl =
      'https://play.google.com/store/apps/details?id=com.sauvank.musicstream';
  static const _dismissedKey = 'update_dismissed_build_v1';

  /// Returns the newer build number to announce, or null when the app is up to
  /// date, the user already dismissed that build, or the check failed.
  Future<int?> pendingUpdate() async {
    try {
      final latest = await _channel
          .invokeMethod<int>('check')
          .timeout(const Duration(seconds: 5));
      if (latest == null || latest <= 0) return null;
      final preferences = await SharedPreferences.getInstance();
      return preferences.getInt(_dismissedKey) == latest ? null : latest;
    } catch (_) {
      return null;
    }
  }

  Future<void> dismiss(int build) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_dismissedKey, build);
  }
}
