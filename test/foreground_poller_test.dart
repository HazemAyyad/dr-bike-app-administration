import 'dart:async';

import 'package:doctorbike/core/services/foreground_poller.dart';
import 'package:doctorbike/core/services/coalesced_refresh.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('poller skips covered/background screens and resumes serially',
      (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    var visible = true;
    var calls = 0;
    var pending = Completer<void>();
    final poller = ForegroundPoller(
      interval: const Duration(seconds: 5),
      isVisible: () => visible,
      task: () {
        calls++;
        return pending.future;
      },
    )..start();
    addTearDown(poller.dispose);
    await tester.pump(const Duration(seconds: 5));
    expect(calls, 1);
    await tester.pump(const Duration(seconds: 30));
    expect(calls, 1);
    pending.complete();
    await tester.pump();
    visible = false;
    await tester.pump(const Duration(seconds: 5));
    expect(calls, 1);
    visible = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 1));
    expect(calls, 1);
    pending = Completer<void>();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 1));
    expect(calls, 2);
    poller.dispose();
    pending.complete();
    await tester.pump(const Duration(minutes: 1));
    expect(calls, 2);
  });

  test('coalesces periodic work while preserving the latest user refresh',
      () async {
    final refresh = CoalescedRefresh();
    final pending = Completer<void>();
    final calls = <String>[];
    final first = refresh.run(() async {
      calls.add('original');
      await pending.future;
    });
    final periodic = refresh.run(() async => calls.add('periodic'));
    refresh.run(() async => calls.add('old filter'), queueIfBusy: true);
    final manual =
        refresh.run(() async => calls.add('latest filter'), queueIfBusy: true);
    pending.complete();
    await Future.wait([first, periodic, manual]);
    expect(calls, ['original', 'latest filter']);
    await refresh.run(() async => calls.add('next'));
    expect(calls.last, 'next');
  });

  test('a failed refresh can be retried', () async {
    final refresh = CoalescedRefresh();
    await expectLater(
        refresh.run(() async => throw StateError('offline')), throwsStateError);
    var ran = false;
    await refresh.run(() async {
      ran = true;
    });
    expect(ran, isTrue);
  });
}
