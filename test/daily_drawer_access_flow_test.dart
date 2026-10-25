import 'package:doctorbike/features/admin/sales/data/models/daily_session_model.dart';
import 'package:doctorbike/features/admin/sales/presentation/utils/daily_drawer_access_flow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final type in ['instant_sales', 'sales_orders']) {
    group(type, () {
      const closed = DailySessionPayload(canRequestOpen: true);
      final pending = DailySessionPayload(
        session: DailySessionInfo(
          id: 7,
          sessionType: type,
          businessDate: '2026-10-24',
          status: 'closing_requested',
        ),
        canFinalizeClosing: true,
        pendingClosingRequestId: 42,
      );
      final open = DailySessionPayload(
        session: DailySessionInfo(
          id: 8,
          sessionType: type,
          businessDate: '2026-10-25',
          status: 'open',
          allowsSales: true,
        ),
      );

      test('closed drawer opens then reloads before continuing', () async {
        final flow = _Flow([closed, open]);
        expect(await flow.run(), same(open));
        expect(flow.calls, ['load', 'open', 'load']);
      });

      test('pending closing is reviewed before opening and continuing',
          () async {
        final flow = _Flow([pending, closed, open]);
        expect(await flow.run(), same(open));
        expect(flow.calls, ['load', 'review:42', 'load', 'open', 'load']);
      });

      test('cancelling or failing review stops the waiting sale', () async {
        final flow = _Flow([pending])..approved = false;
        expect(await flow.run(), isNull);
        expect(flow.calls, ['load', 'review:42']);
      });

      test('cancelling opening after approval stops the waiting sale',
          () async {
        final flow = _Flow([pending, closed])..opened = false;
        expect(await flow.run(), isNull);
        expect(flow.calls, ['load', 'review:42', 'load', 'open']);
      });

      test('review cannot bypass a closing still pending on the server',
          () async {
        final flow = _Flow([pending, pending]);
        expect((await flow.run())?.allowsSales, isFalse);
        expect(flow.calls, ['load', 'review:42', 'load']);
      });

      test('opening cannot bypass a drawer still closed on the server',
          () async {
        final flow = _Flow([closed, closed]);
        expect((await flow.run())?.allowsSales, isFalse);
        expect(flow.calls, ['load', 'open', 'load']);
      });

      test('open drawer continues without review or opening', () async {
        final flow = _Flow([open]);
        expect(await flow.run(), same(open));
        expect(flow.calls, ['load']);
      });

      test('employee without review permission remains blocked', () async {
        final blocked = DailySessionPayload(
          session: pending.session,
          pendingClosingRequestId: 42,
        );
        final flow = _Flow([blocked]);
        expect((await flow.run())?.allowsSales, isFalse);
        expect(flow.calls, ['load']);
      });

      test('missing payload stops before showing actions', () async {
        final flow = _Flow([null]);
        expect(await flow.run(), isNull);
        expect(flow.calls, ['load']);
      });
    });
  }
}

class _Flow {
  _Flow(this.payloads);

  final List<DailySessionPayload?> payloads;
  final calls = <String>[];
  var approved = true;
  var opened = true;
  var index = 0;

  Future<DailySessionPayload?> run() => prepareDailyDrawer(
        loadPayload: () async {
          calls.add('load');
          return payloads[index++];
        },
        reviewClosing: (id) async {
          calls.add('review:$id');
          return approved;
        },
        openDrawer: () async {
          calls.add('open');
          return opened;
        },
      );
}
