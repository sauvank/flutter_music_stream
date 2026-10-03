import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Compares the installed build number with the one published on Hosting
/// (`hosting/version.json`, bumped only once a build is live on Google Play).
class UpdateCheckService {
  UpdateCheckService({Dio? dio}) : _dio = dio ?? Dio();

  static const versionUrl = 'https://musicstream-ks.web.app/version.json';
  static const storeUrl =
      'https://play.google.com/store/apps/details?id=com.sauvank.musicstream';
  static const _dismissedKey = 'update_dismissed_build_v1';

  final Dio _dio;

  /// Returns the newer build number to announce, or null when the app is up to
  /// date, the user already dismissed that build, or the check failed.
  Future<int?> pendingUpdate() async {
    try {
      final response = await _dio.get<Map<String, Object?>>(
        versionUrl,
        options: Options(
          responseType: ResponseType.json,
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final latest = response.data?['latestBuild'];
      if (latest is! int) return null;
      final installed =
          int.tryParse((await PackageInfo.fromPlatform()).buildNumber);
      if (installed == null || latest <= installed) return null;
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
