import 'dart:async';

import 'package:doctorbike/core/services/translations_service.dart';
import 'package:doctorbike/features/admin/stock/data/datasources/stock_datasource.dart';
import 'package:doctorbike/features/admin/stock/presentation/widgets/missing_sales_cost_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Almarai')
          ..addFont(
              rootBundle.load('assets/fonts/Almarai/Almarai-Regular.ttf')))
        .load();
  });
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('review never applies until user selects a sale and confirms',
      (tester) async {
    final ds = _Datasource();
    await _open(tester, ds);
    await tester.enterText(find.byType(TextField).at(0), '10');
    await tester.enterText(find.byType(TextField).at(1), 'تكلفة مخزون قديم');
    await tester.tap(find.text('مراجعة المبيعات'));
    await tester.pumpAndSettle();
    expect(ds.previews, 1);
    expect(ds.applications, 0);
    expect(find.textContaining('الكمية المباعة: 2'), findsOneWidget);
    expect(
        find.textContaining('سعر بيع القطعة المسجل: 50 شيكل'), findsOneWidget);
    expect(find.textContaining('إجمالي بيع الصنف قبل خصم الفاتورة: 100 شيكل'),
        findsOneWidget);
    expect(find.textContaining('إجمالي الفاتورة: 150 شيكل — خصم الفاتورة: 25'),
        findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    final boxes = find.byType(CheckboxListTile);
    expect(boxes, findsNWidgets(2));
    expect(tester.widget<CheckboxListTile>(boxes.at(1)).onChanged, isNull);
    await tester.ensureVisible(boxes.first);
    await tester.tap(boxes.first);
    await tester.pumpAndSettle();
    expect(find.textContaining('المحدد: 1'), findsOneWidget);
    await tester.tap(find.text('تأكيد تكلفة المبيعات المحددة'));
    await tester.pumpAndSettle();
    expect(ds.applications, 1);
    expect(ds.ids, [42]);
    expect(ds.token, 'review-token');
    expect(find.text('جارٍ التحميل...'), findsOneWidget);
    ds.applied.complete({'corrected_count': 1});
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing cost clears previous review and selection',
      (tester) async {
    final ds = _Datasource();
    await _open(tester, ds);
    await tester.enterText(find.byType(TextField).at(0), '10');
    await tester.enterText(find.byType(TextField).at(1), 'تصحيح');
    await tester.tap(find.text('مراجعة المبيعات'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(CheckboxListTile).first);
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('تعديل التكلفة وإعادة المراجعة'));
    await tester.tap(find.text('تعديل التكلفة وإعادة المراجعة'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.text('مراجعة المبيعات'), findsOneWidget);
    expect(ds.applications, 0);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
  });

  testWidgets('zero stock without sales cannot save a fabricated cost',
      (tester) async {
    final ds = _Datasource(empty: true);
    await _open(tester, ds);
    await tester.enterText(find.byType(TextField).at(0), '280');
    await tester.enterText(find.byType(TextField).at(1), 'تصحيح');
    await tester.tap(find.text('مراجعة المبيعات'));
    await tester.pumpAndSettle();
    expect(find.textContaining('لا توجد مبيعات ناقصة التكلفة'), findsOneWidget);
    expect(ds.applications, 0);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
  });
}

Future<void> _open(WidgetTester tester, _Datasource ds) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => GetMaterialApp(
      translations: Translation(),
      locale: const Locale('ar'),
      theme: ThemeData(fontFamily: 'Almarai'),
      home: Scaffold(
          body: Builder(
        builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => MissingSalesCostSheet(
                      productId: '962',
                      productName: 'اكس مطور كبير تفصيل',
                      datasource: ds),
                ),
            child: const Text('open')),
      )),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

class _Datasource implements StockDatasource {
  _Datasource({this.empty = false});
  final bool empty;
  final applied = Completer<Map<String, dynamic>>();
  int previews = 0;
  int applications = 0;
  List<int>? ids;
  String? token;

  @override
  Future<Map<String, dynamic>> reviewMissingSalesCost({
    required String productId,
    String? sizeColorId,
    required double unitCost,
    required String currency,
    List<int>? saleIds,
    String? reviewToken,
    String? reason,
  }) async {
    if (saleIds != null) {
      applications++;
      ids = saleIds;
      token = reviewToken;
      return applied.future;
    }
    previews++;
    return {
      'review_token': 'review-token',
      'sales': empty
          ? []
          : [
              {
                'id': 42,
                'invoice_number': 'SAL-42',
                'sold_at': '2026-10-20',
                'quantity': 2,
                'missing_quantity': 2,
                'sale_unit_price': 50,
                'sale_line_total': 100,
                'invoice_total': 150,
                'invoice_discount': 25,
                'known_cost': 0,
                'new_total_cost': 20,
                'added_cost': 20,
                'currency': 'شيكل',
                'eligible': true
              },
              {
                'id': 43,
                'invoice_number': 'SAL-43',
                'sold_at': '2026-10-21',
                'quantity': 1,
                'missing_quantity': 1,
                'known_cost': 0,
                'new_total_cost': 10,
                'added_cost': 10,
                'currency': 'شيكل',
                'eligible': false,
                'blocked_reason': 'البيع مرتبط بمرتجع'
              },
            ]
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
