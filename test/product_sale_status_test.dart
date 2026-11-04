import 'dart:async';

import 'package:doctorbike/features/admin/stock/data/datasources/stock_datasource.dart';
import 'package:doctorbike/features/admin/stock/data/models/all_stock_products_model.dart';
import 'package:doctorbike/features/admin/stock/data/models/product_details_model.dart'
    show ProductDetailsModel;
import 'package:doctorbike/features/admin/stock/data/models/stock_products_page_result.dart';
import 'package:doctorbike/features/admin/stock/domain/stock_product_filters.dart';
import 'package:doctorbike/features/admin/stock/presentation/controllers/stock_controller.dart';
import 'package:doctorbike/features/admin/stock/presentation/widgets/product_sale_status_card.dart';
import 'package:doctorbike/features/admin/stock/presentation/widgets/sale_blocked_products_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class _Datasource implements StockDatasource {
  final requests = <StockProductFilters?>[];

  @override
  Future<StockProductsPageResult> getAllStock({
    required int page,
    required bool ifCombinations,
    required bool ifCloseouts,
    StockProductFilters? filters,
    int perPage = 15,
  }) async {
    requests.add(filters);
    return StockProductsPageResult(
        products: [], currentPage: 1, lastPage: 1, total: 0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Controller extends GetxController implements StockController {
  @override
  final _Datasource stockDatasource = _Datasource();
  Completer<bool>? pendingChange;
  final changes = <bool>[];

  @override
  Future<bool> setProductSaleBlocked(
      ProductDetailsModel product, bool blocked) async {
    changes.add(blocked);
    final ok = pendingChange == null ? true : await pendingChange!.future;
    if (ok) product.isSaleBlocked = blocked;
    return ok;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());

  test('sale filter survives search and location changes and clears explicitly',
      () {
    const filters = StockProductFilters(saleStatus: 'blocked');
    expect(filters.hasActiveFilters, isTrue);
    expect(filters.activeFilterCount, 1);
    final changed = filters.copyWith(search: 'خوذة', storeSectionId: '2');
    expect(changed.toQueryParams(page: 2)['sale_status'], 'blocked');
    expect(changed.copyWith(clearSaleStatus: true).toQueryParams(page: 1),
        isNot(contains('sale_status')));
  });

  test('blocked status survives model parsing, copying and serialization', () {
    final row = AllStockProductsModel.fromJson(
        {'product_id': 191, 'is_sale_blocked': true});
    expect(row.isSaleBlocked, isTrue);
    expect(row.copyWith(normailPrice: 60).isSaleBlocked, isTrue);
    expect(row.toJson()['is_sale_blocked'], isTrue);
    final details =
        ProductDetailsModel.fromJson({'id': 191, 'is_sale_blocked': 1});
    expect(details.isSaleBlocked, isTrue);
    expect(details.toJson()['is_sale_blocked'], isTrue);
    expect(ProductDetailsModel.fromJson({'id': 192}).isSaleBlocked, isFalse);
  });

  testWidgets(
      'status switch prevents duplicate saves and can allow sales again',
      (tester) async {
    final controller = _Controller();
    Get.put<StockController>(controller);
    final product = ProductDetailsModel.fromJson({'id': 191, 'stock': 31});
    controller.pendingChange = Completer<bool>();
    await tester.pumpWidget(GetMaterialApp(
        home: Scaffold(body: ProductSaleStatusCard(product: product))));
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(controller.changes, [true]);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    controller.pendingChange!.complete(true);
    await tester.pumpAndSettle();
    expect(product.isSaleBlocked, isTrue);
    expect(product.stock, '31');
    controller.pendingChange = null;
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(controller.changes, [true, false]);
    expect(product.isSaleBlocked, isFalse);
  });

  testWidgets('failed status change preserves the displayed state',
      (tester) async {
    final controller = _Controller()..pendingChange = Completer<bool>();
    Get.put<StockController>(controller);
    final product = ProductDetailsModel.fromJson({'id': 191});
    await tester.pumpWidget(GetMaterialApp(
        home: Scaffold(body: ProductSaleStatusCard(product: product))));
    await tester.tap(find.byType(Switch));
    controller.pendingChange!.complete(false);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });

  testWidgets('blocked tab searches with the blocked filter on every request',
      (tester) async {
    final controller = _Controller();
    Get.put<StockController>(controller);
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => const GetMaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(child: SaleBlockedProductsTab())),
      ),
    ));
    await tester.pumpAndSettle();
    expect(controller.stockDatasource.requests.single?.saleStatus, 'blocked');
    expect(find.text('لا توجد منتجات ممنوعة من البيع'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'خوذة');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(controller.stockDatasource.requests.last?.search, 'خوذة');
    expect(controller.stockDatasource.requests.last?.saleStatus, 'blocked');
    expect(tester.takeException(), isNull);
  });
}
