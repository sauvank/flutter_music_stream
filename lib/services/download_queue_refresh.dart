import 'dart:async';

/// Coalesces native event bursts without overlapping expensive database reads.
class DownloadQueueRefresh {
  DownloadQueueRefresh(this.refresh, {required this.onError});

  final Future<void> Function() refresh;
  final void Function(Object) onError;
  Timer? _timer;
  bool _running = false;
  bool _pending = false;
  bool _disposed = false;

  void request() {
    if (_disposed) return;
    _pending = true;
    if (_running || _timer != null) return;
    _timer = Timer(const Duration(milliseconds: 500), _run);
  }

  Future<void> _run() async {
    _timer = null;
    _pending = false;
    _running = true;
    try {
      await refresh();
    } catch (error) {
      if (!_disposed) onError(error);
    } finally {
      _running = false;
      if (_pending) request();
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
  }
}
