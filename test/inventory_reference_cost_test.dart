import 'package:doctorbike/core/services/initial_bindings.dart' as session;
import 'package:doctorbike/features/admin/stock/data/datasources/stock_datasource.dart';
import 'package:doctorbike/features/admin/stock/data/models/product_details_model.dart'
    hide Size;
import 'package:doctorbike/features/admin/stock/presentation/widgets/inventory_summary_section.dart';
import 'package:doctorbike/features/admin/stock/presentation/widgets/product_inventory_cost_sheet.dart';
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
  setUp(() {
    Get.testMode = true;
    session.userType = 'admin';
  });
  tearDown(() {
    session.userType = '';
    session.employeePermissionNames.clear();
    Get.reset();
  });

  testWidgets('zero stock can save reference from inventory without sales',
      (tester) async {
    final ds = _ReferenceDatasource();
    Get.put<StockDatasource>(ds);
    await _app(tester, Builder(builder: (context) {
      return TextButton(
          onPressed: () => showProductInventoryCostSheet(
              context: context,
              productId: '962',
              productName: 'منتج بدون رصيد'),
          child: const Text('open'));
    }));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('تسجيل تكلفة مرجعية'));
    await tester.tap(find.text('تسجيل تكلفة مرجعية'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('لا يغيّر قيمة المخزون أو تكلفة المبيعات السابقة'),
        findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), '٢٨٠');
    await tester.enterText(
        find.byType(TextField).at(1), 'تكلفة مرجعية من المورد');
    await tester.ensureVisible(find.text('حفظ التكلفة المرجعية'));
    await tester.tap(find.text('حفظ التكلفة المرجعية'));
    await tester.pumpAndSettle();
    expect(ds.referenceOnly, isTrue);
    expect(ds.savedCost, 280);
    expect(ds.savedProduct, '962');
    expect(find.text('تكلفة الوحدة المرجعية'), findsOneWidget);
    expect(find.text('280.00 شيكل'), findsOneWidget);
    expect(ds.product.inventory!.quantityOnHand, 0);
    expect(ds.product.inventory!.inventoryValue, 0);
    expect(ds.product.inventory!.costLayers, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets(
      'summary offers reference at zero and respects adjustment permission',
      (tester) async {
    final product = _ReferenceDatasource().product;
    var opened = false;
    await _app(
        tester,
        SingleChildScrollView(
            child: InventorySummarySection(
                product: product,
                onAdjust: () {},
                onRevalue: () => opened = true)));
    await tester.ensureVisible(find.text('تسجيل تكلفة مرجعية'));
    await tester.tap(find.text('تسجيل تكلفة مرجعية'));
    expect(opened, isTrue);
    session.userType = 'employee';
    session.employeePermissionNames
        .add(session.viewInventoryCostPermissionName);
    await _app(
        tester,
        SingleChildScrollView(
            child: InventorySummarySection(
                product: product, onAdjust: () {}, onRevalue: () {})));
    expect(find.text('تسجيل تكلفة مرجعية'), findsNothing);
  });
}

Future<void> _app(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => GetMaterialApp(
          theme: ThemeData(fontFamily: 'Almarai'),
          home: Scaffold(body: child))));
  await tester.pumpAndSettle();
}

class _ReferenceDatasource implements StockDatasource {
  bool? referenceOnly;
  double? savedCost;
  String? savedProduct;
  ProductDetailsModel get product => ProductDetailsModel.fromJson({
        'id': '962',
        'nameAr': 'منتج بدون رصيد',
        'nameEng': 'Product',
        'stock': '0',
        'can_view_inventory_cost': true,
        'inventory': {
          'quantity_on_hand': 0,
          'costed_quantity': 0,
          'missing_cost_quantity': 0,
          'inventory_value': 0,
          'average_inventory_unit_cost': 0,
          'costing_method': 'fifo',
          'currency': 'شيكل',
          'cost_coverage_complete': true,
          'has_variants': false,
          'reference_unit_cost': savedCost,
          'reference_cost_currency': 'شيكل',
        },
      });

  @override
  Future<ProductDetailsModel> getProductDetails(
          {required String productId}) async =>
      product;

  @override
  Future<Map<String, dynamic>> initializeProductInventoryCost({
    required String productId,
    String? sizeColorId,
    required double unitCost,
    required String reason,
    String? notes,
    String currency = 'شيكل',
    bool referenceOnly = false,
  }) async {
    this.referenceOnly = referenceOnly;
    savedCost = unitCost;
    savedProduct = productId;
    return {'status': 'success'};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
