import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_reader_app/services/audio_visualizer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a screen leaving during a transition keeps the new capture',
      () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.sauvank.musicstream/visualizer'),
      (call) async {
        calls.add(call.method);
        return call.method == 'start' ? true : null;
      },
    );
    const service = AudioVisualizerService();
    final leaving = Object();
    final arriving = Object();

    await service.start(leaving, 7);
    await service.start(arriving, 7);
    await service.stop(leaving);
    expect(calls, ['start', 'start']);

    await service.stop(arriving);
    expect(calls, ['start', 'start', 'stop']);
  });
}
