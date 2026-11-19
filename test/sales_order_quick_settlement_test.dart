import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:doctorbike/core/errors/failure.dart';
import 'package:doctorbike/features/admin/sales_orders/data/models/sales_order_model.dart';
import 'package:doctorbike/features/admin/sales_orders/data/repositories/sales_orders_implement.dart';
import 'package:doctorbike/features/admin/sales_orders/presentation/controllers/sales_orders_controller.dart';
import 'package:doctorbike/features/admin/sales_orders/presentation/widgets/sales_order_settlement_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  test('Shiply handover omits its hidden zero so the saved quote can be used',
      () async {
    final repository = _Repository();
    final controller = _Controller(repository);
    controller.deliveryCompanies.add(
        DeliveryCompanyModel(id: 1, name: 'Shiply', deliveryType: 'shiply'));
    controller.selectedDeliveryCompanyId.value = 1;
    controller.carrierDeliveryCostController.text = '0';
    await controller.handover(63);
    expect(
        repository.handoverBody!.containsKey('carrier_delivery_cost'), isFalse);
    controller.carrierDeliveryCostController.text = '30';
    await controller.handover(63);
    expect(repository.handoverBody!['carrier_delivery_cost'], 30);
    controller.onClose();
  });

  test('legacy Shiply fee is an explicit estimate; stored carrier cost wins',
      () {
    expect(_order().suggestedCarrierFee, 70);
    expect(_order().usesCustomerFeeEstimate, isTrue);
    expect(_order(cost: 20).suggestedCarrierFee, 20);
    expect(_order(cost: 20).usesCustomerFeeEstimate, isFalse);
    expect(_order(quote: 30).suggestedCarrierFee, 30);
    expect(_order(quote: 30).usesCustomerFeeEstimate, isFalse);
  });

  test(
      'free authoritative quote and non-Shiply delivery never use customer fee',
      () {
    expect(_order(quote: 0).suggestedCarrierFee, 0);
    expect(_order(quote: 0).usesCustomerFeeEstimate, isFalse);
    expect(_order(shiply: false).suggestedCarrierFee, 0);
  });

  test(
      'already deducted fees are not charged twice and debt-only settlement has no fee',
      () {
    expect(_order(cost: 70, deducted: 20).suggestedCarrierFee, 50);
    expect(_order(cost: 70, deducted: 80).suggestedCarrierFee, 0);
    expect(_order(cost: 70, carrier: 10).suggestedCarrierFee, 10);
    expect(_order(cost: 70, carrier: 0, debt: 20).suggestedCarrierFee, 0);
    expect(_order(carrier: 0, debt: 20).canArchive, isFalse);
    expect(_order(carrier: 0).canArchive, isTrue);
  });

  for (final size in [const Size(360, 640), const Size(640, 360)]) {
    testWidgets(
        'settlement fits $size, disables partial archive and blocks repeated submit',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final repository = _Repository();
      final controller = _Controller(repository);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Builder(
        builder: (context) => TextButton(
            onPressed: () =>
                SalesOrderSettlementSheet.show(context, controller, 63),
            child: const Text('فتح التسوية')),
      ))));
      await tester.tap(find.text('فتح التسوية'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('صافي الداخل للصندوق: 60.00'), findsOneWidget);
      expect(
          tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
          isTrue);
      await tester.enterText(find.byType(TextField).first, '100');
      await tester.pump();
      expect(
          tester
              .widget<CheckboxListTile>(find.byType(CheckboxListTile))
              .onChanged,
          isNull);
      expect(
          tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
          isFalse);
      await tester.enterText(find.byType(TextField).first, '130');
      await tester.pump();
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      final confirm = find.text('تأكيد التسوية والأرشفة');
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pump();
      expect(repository.calls, 1);
      expect(repository.body!['delivery_settled_amount'], 130);
      expect(repository.body!['carrier_fee'], 70);
      expect(repository.body!['archive_after_settlement'], isTrue);
      expect(repository.body!.containsKey('payment_box_id'), isFalse);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull);
      expect(controller.statusFilter.value, 'delivered');
      repository.pending.complete(Right(_order()));
      await tester.pumpAndSettle();
      expect(find.byType(SalesOrderSettlementSheet), findsNothing);
      expect(tester.takeException(), isNull);
      controller.onClose();
    });
  }
}

SalesOrderDetailModel _order(
        {double? cost = 0,
        double? quote,
        double deducted = 0,
        bool shiply = true,
        double carrier = 130,
        double debt = 0}) =>
    SalesOrderDetailModel(
      id: 63,
      serialNumber: '0000100',
      status: 'delivered',
      customerName: 'أم موسى',
      total: 130,
      subtotal: 60,
      discount: 0,
      calculatedTotal: 130,
      customerDeliveryFee: 70,
      carrierDeliveryCost: cost,
      shiplyQuotedDeliveryFee: quote,
      settlementCarrierFeeTotal: deducted,
      isShiplyDelivery: shiply,
      carrierReceivableBalance: carrier,
      customerDebtBalance: debt,
      paymentType: 'credit',
      items: [],
      media: [],
    );

class _Controller extends SalesOrdersController {
  _Controller(SalesOrdersRepository repository)
      : super(repository: repository) {
    statusFilter.value = 'delivered';
  }
  @override
  Future<void> loadOrders() async {}
  @override
  Future<void> loadLookups() async {}
  @override
  Future<void> withBlockingProgress(Future<void> Function() action,
          {required String message}) =>
      action();
}

class _Repository implements SalesOrdersRepository {
  int calls = 0;
  Map<String, dynamic>? body;
  Map<String, dynamic>? handoverBody;
  final pending = Completer<Either<Failure, SalesOrderDetailModel>>();
  @override
  Future<Either<Failure, SalesOrderDetailModel>> getOrder(int orderId) async =>
      Right(_order());
  @override
  Future<Either<Failure, SalesOrderDetailModel>> handover(
      int orderId, Map<String, dynamic> body) async {
    handoverBody = body;
    return Right(_order());
  }

  @override
  Future<Either<Failure, SalesOrderDetailModel>> settle(
      int orderId, Map<String, dynamic> body) {
    calls++;
    this.body = body;
    return pending.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
