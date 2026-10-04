import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/services/update_check_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.sauvank.musicstream/updates');
  const service = UpdateCheckService();

  void reply(Future<Object?> Function(MethodCall)? handler) {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, handler);
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => reply(null));

  test('offers the build Google Play makes available to this user', () async {
    reply((call) async {
      expect(call.method, 'check');
      return 100;
    });
    expect(await service.pendingUpdate(), 100);
  });

  test('does not offer a build when Play reports no eligible update', () async {
    reply((_) async => null);
    expect(await service.pendingUpdate(), isNull);
  });

  test('remembers a dismissal but offers the next available build', () async {
    var available = 100;
    reply((_) async => available);
    await service.dismiss(100);
    expect(await const UpdateCheckService().pendingUpdate(), isNull);
    available = 101;
    expect(await service.pendingUpdate(), 101);
  });

  test('ignores malformed build numbers', () async {
    for (final value in [0, -1, '100']) {
      reply((_) async => value);
      expect(await service.pendingUpdate(), isNull);
    }
  });

  test('a failed or absent Play bridge does not interrupt startup', () async {
    reply((_) async => throw PlatformException(code: 'PLAY_UNAVAILABLE'));
    expect(await service.pendingUpdate(), isNull);
    reply(null);
    expect(await service.pendingUpdate(), isNull);
  });

  testWidgets('bounds a stalled Play request without showing a false update',
      (tester) async {
    final stalled = Completer<Object?>();
    reply((_) => stalled.future);
    final pending = service.pendingUpdate();
    await tester.pump(const Duration(seconds: 6));
    expect(await pending, isNull);
    stalled.complete(100);
    await tester.pump();
  });
}
