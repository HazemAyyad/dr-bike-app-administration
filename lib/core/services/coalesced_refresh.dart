import 'dart:async';

/// Periodic callers join a running refresh. User actions can queue one final
/// refresh so a changed filter or a newly sent message is still fetched.
class CoalescedRefresh {
  Future<void>? _running;
  Future<void> Function()? _pending;

  Future<void> run(Future<void> Function() task, {bool queueIfBusy = false}) {
    if (_running != null) {
      if (queueIfBusy) _pending = task;
      return _running!;
    }
    final completion = Completer<void>();
    _running = completion.future;
    _drain(task, completion);
    return completion.future;
  }

  Future<void> _drain(
    Future<void> Function() task,
    Completer<void> completion,
  ) async {
    try {
      Future<void> Function()? next = task;
      while (next != null) {
        _pending = null;
        await next();
        next = _pending;
      }
      completion.complete();
    } catch (error, stack) {
      completion.completeError(error, stack);
    } finally {
      _pending = null;
      _running = null;
    }
  }
}
