import 'package:doctorbike/features/admin/boxes/data/models/all_boxes_logs_model.dart';
import 'package:doctorbike/features/admin/boxes/presentation/widgets/movement_balances.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the before and after balance for a movement',
      (tester) async {
    final log = BoxLogModel.fromJson({
      'id': 1,
      'box_balance_before': '1250.50',
      'box_balance_after': 1200,
    });
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MovementBalances(log: log)),
    ));
    expect(find.text('الرصيد قبل: 1,250.5  |  بعد: 1,200'), findsOneWidget);
    expect(log.toJson()['box_balance_before'], 1250.5);
  });

  testWidgets('transfer shows each box and preserves balances in JSON',
      (tester) async {
    final log = BoxLogModel.fromJson({
      'id': 2,
      'type': 'transfer',
      'from_box': {'id': 1, 'name': 'الرئيسي'},
      'to_box': {'id': 2, 'name': 'الفرع'},
      'from_box_balance_before': '100',
      'from_box_balance_after': '70',
      'to_box_balance_before': 20,
      'to_box_balance_after': 50,
    });
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MovementBalances(log: log)),
    ));
    expect(find.text('من الرئيسي: قبل: 100  |  بعد: 70'), findsOneWidget);
    expect(find.text('إلى الفرع: قبل: 20  |  بعد: 50'), findsOneWidget);
    final restored = BoxLogModel.fromJson(log.toJson());
    expect(restored.fromBoxBalanceBefore, 100);
    expect(restored.fromBoxBalanceAfter, 70);
    expect(restored.toBoxBalanceBefore, 20);
    expect(restored.toBoxBalanceAfter, 50);
  });

  testWidgets('unavailable legacy balances do not appear as zero',
      (tester) async {
    final log = BoxLogModel.fromJson({'id': 3});
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MovementBalances(log: log)),
    ));
    expect(find.text('الرصيد قبل: —  |  بعد: —'), findsOneWidget);
    expect(log.boxBalanceBefore, isNull);
    expect(log.boxBalanceAfter, isNull);
  });
}
