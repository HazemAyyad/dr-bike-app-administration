import 'dart:async';

import 'package:flutter/widgets.dart';

import '../databases/api/api_request_backoff.dart';

/// Runs one refresh at a time, while its screen and app are visible.
class ForegroundPoller with WidgetsBindingObserver {
  ForegroundPoller({
    required this.interval,
    required this.task,
    required this.isVisible,
  });

  final Duration interval;
  final Future<void> Function() task;
  final bool Function() isVisible;
  Timer? _timer;
  bool _started = false;
  bool _running = false;

  bool get _foreground {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _schedule(interval);
  }

  void _schedule(Duration delay) {
    _timer?.cancel();
    if (_started && _foreground && !_running) {
      _timer = Timer(delay, _tick);
    }
  }

  Future<void> _tick() async {
    if (!_started || _running) return;
    _running = true;
    try {
      if (_foreground &&
          isVisible() &&
          !ApiRequestBackoff.instance.isCoolingDown) {
        await task();
      }
    } catch (_) {
      // Refresh failures leave the current screen data available.
    } finally {
      _running = false;
      _schedule(interval);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _schedule(Duration.zero);
    } else {
      _timer?.cancel();
    }
  }

  void dispose() {
    _started = false;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
