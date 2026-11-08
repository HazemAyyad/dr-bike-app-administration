import 'package:dio/dio.dart';
import 'package:doctorbike/core/databases/api/api_consumer.dart';
import 'package:doctorbike/features/admin/stock/data/datasources/stock_datasource.dart';
import 'package:doctorbike/features/admin/stock/presentation/widgets/inventory_cost_revaluation_sheet.dart';
import 'package:doctorbike/features/admin/stock/presentation/widgets/stock_quick_adjust_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Almarai')
          ..addFont(
              rootBundle.load('assets/fonts/Almarai/Almarai-Regular.ttf')))
        .load();
  });
  for (final legacyCurrency in ['mixed', 'USD', 'NIS', 'شيكل']) {
    test('cost requests use shekels despite $legacyCurrency input', () async {
      final api = _Api();
      final datasource = StockDatasource(api: api);
      await datasource.adjustProductStock(
          productId: '974',
          sizeColorId: '967',
          actualQuantity: 152,
          unitCost: 1.25,
          reason: 'جرد فعلي للمخزون',
          currency: legacyCurrency);
      expect(api.payload['currency'], 'شيكل');
      expect(api.payload['actual_quantity'], 152);
      expect(api.payload['unit_cost'], 1.25);
      expect(api.payload['size_color_id'], '967');

      await datasource.updateProductCostPrice(
          productId: '974',
          costPrice: 1.25,
          reason: 'إعادة تقييم',
          currency: legacyCurrency);
      expect(api.payload['currency'], 'شيكل');
      expect(api.payload['new_unit_cost'], 1.25);

      await datasource.initializeProductInventoryCost(
          productId: '974',
          unitCost: 1.25,
          reason: 'تكلفة مرجعية',
          referenceOnly: true,
          currency: legacyCurrency);
      expect(api.payload['currency'], 'شيكل');
      expect(api.payload['unit_cost'], 1.25);
      expect(api.payload['reference_only'], isTrue);

      for (final apply in [false, true]) {
        await datasource.reviewMissingSalesCost(
            productId: '974',
            unitCost: 1.25,
            currency: legacyCurrency,
            saleIds: apply ? [5181] : null,
            reviewToken: apply ? 'reviewed' : null,
            reason: apply ? 'تصحيح تكلفة مفقودة' : null);
        expect(api.payload['currency'], 'شيكل');
        expect(api.payload['unit_cost'], 1.25);
        expect(api.payload['sale_ids'], apply ? [5181] : null);
      }
    });
  }

  testWidgets('stocktaking displays shekels for a legacy mixed summary',
      (tester) async {
    StockQuickAdjustResult? result;
    await _open(tester, (context) async {
      result = await showStockQuickAdjustSheet(
          context: context,
          title: 'ستيكرات انوكيم',
          currentStock: 4,
          currency: 'mixed');
    });
    expect(find.text('mixed'), findsNothing);
    await tester.enterText(find.byType(TextField).at(0), '8');
    await tester.pump();
    expect(find.text('شيكل'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), '1.25');
    await tester.ensureVisible(find.text('تسجيل التسوية'));
    await tester.tap(find.text('تسجيل التسوية'));
    await tester.pumpAndSettle();
    expect(result?.actualQuantity, 8);
    expect(result?.unitCost, 1.25);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cost entry displays shekels for a legacy mixed summary',
      (tester) async {
    await _open(tester, (context) async {
      await showInventoryCostRevaluationSheet(
          context: context,
          title: 'ستيكرات انوكيم',
          currentUnitCost: 1,
          currency: 'mixed');
    });
    expect(find.text('mixed'), findsNothing);
    expect(find.text('شيكل'), findsOneWidget);
    expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '1.00');
    expect(tester.takeException(), isNull);
  });
}

Future<void> _open(
    WidgetTester tester, Future<void> Function(BuildContext) onOpen) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
          theme: ThemeData(fontFamily: 'Almarai'),
          home: Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                      onPressed: () => onOpen(context),
                      child: const Text('open')))))));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

class _Api implements ApiConsumer {
  Map<String, dynamic> payload = {};

  Response<dynamic> _respond(String path, Object? data) {
    payload = Map<String, dynamic>.from(data! as Map);
    return Response(
        requestOptions: RequestOptions(path: path),
        data: {'status': 'success', 'product_stock': 152, 'result': {}});
  }

  @override
  Future<dynamic> post(String path,
          {Object? data,
          Options? options,
          Map<String, dynamic>? queryParameters,
          bool isFormData = false,
          Function(int, int)? onSendProgress}) async =>
      _respond(path, data);

  @override
  Future<dynamic> get(String path,
          {Object? data,
          Options? options,
          Map<String, dynamic>? queryParameters}) async =>
      _respond(path, queryParameters);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
