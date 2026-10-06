import 'package:doctorbike/features/admin/sales_orders/data/models/sales_order_model.dart';
import 'package:doctorbike/features/admin/sales_orders/presentation/widgets/sales_order_origin_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses explicit admin and store origins with safe admin fallback', () {
    SalesOrderListItemModel parse(String? origin) =>
        SalesOrderListItemModel.fromJson({
          'id': 1,
          'status': 'confirmed',
          'total': 10,
          'payment_type': 'cash',
          if (origin != null) 'origin': origin,
        });
    expect(parse('store').origin, 'store');
    expect(parse('admin').origin, 'admin');
    expect(parse(null).origin, 'admin');
  });

  testWidgets('renders localized explicit origin labels', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
          body: Column(children: [
        SalesOrderOriginBadge(origin: 'store'),
        SalesOrderOriginBadge(origin: 'admin'),
      ])),
    ));
    expect(find.text('المتجر'), findsOneWidget);
    expect(find.text('الإدارة'), findsOneWidget);
  });
}
