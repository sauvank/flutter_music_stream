import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/player_provider.dart';
import '../services/audio_visualizer_service.dart';

/// Bars following the live spectrum of what the player outputs, drawn over
/// the bottom of the artwork. Asks for
/// the microphone permission only when the user taps to enable it, and only
/// captures while visible, playing and in the foreground.
class AudioVisualizer extends StatefulWidget {
  const AudioVisualizer({super.key, this.height = 64});
  final double height;

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _service = AudioVisualizerService();

  late final Ticker _ticker = createTicker(_tick);
  StreamSubscription<int?>? _sessionSubscription;
  StreamSubscription<List<double>>? _levelsSubscription;
  bool? _granted;
  int? _sessionId;
  int? _capturingSession;
  bool _foreground = true;
  bool _visible = true;
  bool _playing = false;
  List<double> _targets = const [];
  List<double> _values = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service.granted().then((granted) {
      if (mounted) setState(() => _granted = granted);
    });
    _sessionSubscription =
        context.read<PlayerProvider>().audioSessionIdStream.listen((id) {
      _sessionId = id;
      _sync();
    });
    _levelsSubscription = _service.levels.listen((levels) {
      _targets = levels;
      if (!_ticker.isActive) _ticker.start();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = TickerMode.of(context);
    _sync();
  }

  bool get _shouldCapture =>
      _granted == true &&
      _foreground &&
      _visible &&
      _playing &&
      (_sessionId ?? 0) > 0;

  /// Starts or stops the platform capture to match the current state.
  void _sync() {
    if (!mounted) return;
    final wanted = _shouldCapture ? _sessionId : null;
    if (wanted == _capturingSession) return;
    _capturingSession = wanted;
    if (wanted == null) {
      unawaited(_service.stop());
      _targets = const [];
      if (!_ticker.isActive && _values.isNotEmpty) _ticker.start();
    } else {
      unawaited(_service.start(wanted));
    }
  }

  void _tick(Duration _) {
    final count = _targets.isEmpty ? _values.length : _targets.length;
    var moving = false;
    final next = List<double>.generate(count, (index) {
      final current = index < _values.length ? _values[index] : 0.0;
      final target = index < _targets.length ? _targets[index] : 0.0;
      // Rises quickly and falls slowly, like a VU meter.
      final value =
          current + (target - current) * (target > current ? .45 : .12);
      if ((value - target).abs() > .005) moving = true;
      return value;
    });
    setState(() => _values = next);
    if (!moving && _targets.isEmpty) {
      _ticker.stop();
      _values = const [];
    }
  }

  Future<void> _enable() async {
    final granted = await _service.request();
    if (!mounted) return;
    setState(() => _granted = granted);
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionSubscription?.cancel();
    _levelsSubscription?.cancel();
    if (_capturingSession != null) unawaited(_service.stop());
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_service.supported) return const SizedBox.shrink();
    final playing =
        context.select<PlayerProvider, bool>((player) => player.playing);
    if (playing != _playing) {
      _playing = playing;
      WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    }
    if (_granted == null) return const SizedBox.shrink();
    if (_granted == false) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: ActionChip(
            onPressed: _enable,
            avatar: const Icon(Icons.graphic_eq_rounded,
                size: 18, color: Colors.white),
            label: Text(context.l10n.showVisualizer),
            labelStyle: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700),
            backgroundColor: Colors.black.withValues(alpha: .45),
            side: BorderSide.none,
            shape: const StadiumBorder(),
          ),
        ),
      );
    }
    final active = _values.any((value) => value > .02);
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedOpacity(
            opacity: active ? 1 : 0,
            duration: const Duration(milliseconds: 400),
            child: DecoratedBox(
              // Keeps white bars readable on light artwork.
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0),
                    Colors.black.withValues(alpha: .55),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 18),
                child: SizedBox(
                  height: widget.height,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _BarsPainter(
                      values: _values,
                      bands: _targets.isNotEmpty ? _targets.length : 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.values,
    required this.bands,
    required this.color,
  });
  final List<double> values;
  final int bands;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 4.0;
    final width = (size.width - gap * (bands - 1)) / bands;
    final radius = Radius.circular(width / 2);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color.withValues(alpha: .6)],
      ).createShader(Offset.zero & size);
    for (var index = 0; index < bands; index++) {
      final value = index < values.length ? values[index] : 0.0;
      // Grows from the bottom edge; a minimum keeps a visible dot.
      final height =
          (size.height * value.clamp(0.0, 1.0)).clamp(width, size.height);
      final left = index * (width + gap);
      canvas.drawRRect(
        RRect.fromLTRBR(
            left, size.height - height, left + width, size.height, radius),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.values != values || old.color != color;
}
