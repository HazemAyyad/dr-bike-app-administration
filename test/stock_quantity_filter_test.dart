import 'package:doctorbike/core/services/initial_bindings.dart' as session;
import 'package:doctorbike/core/services/translations_service.dart';
import 'package:doctorbike/features/admin/sales/data/models/product_model.dart';
import 'package:doctorbike/features/admin/stock/data/models/store_section_model.dart';
import 'package:doctorbike/features/admin/stock/domain/stock_product_filters.dart';
import 'package:doctorbike/features/admin/stock/presentation/controllers/stock_controller.dart';
import 'package:doctorbike/features/admin/stock/presentation/widgets/stock_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Controller extends GetxController implements StockController {
  @override
  final productListFilters =
      const StockProductFilters(search: 'فرامل', categoryId: '1').obs;
  @override
  List<ProductModel> mainCategories = [
    ProductModel.fromJson({'id': '1', 'nameAr': 'قطع'})
  ];
  @override
  List<ProductModel> allSubCategories = [];
  @override
  final storeSections = <StoreSectionModel>[].obs;
  @override
  Future<void> getCategories() async {}
  @override
  Future<void> ensureStoreSectionsLoaded() async {}
  @override
  Future<void> applyProductFilters(StockProductFilters filters) async {
    productListFilters.value = filters;
  }

  @override
  Future<void> clearProductFilters() async {
    productListFilters.value = StockProductFilters.empty;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
    session.userType = 'employee';
  });
  tearDown(() {
    session.userType = '';
    Get.reset();
  });

  for (final status in ['zero', 'negative']) {
    testWidgets(
        'stock filter applies $status and preserves search and category',
        (tester) async {
      final controller = _Controller();
      await _open(tester, controller);
      final dropdown = find.byWidgetPredicate((w) =>
          w is DropdownButton<String?> &&
          (w.items?.any((item) => item.value == 'zero') ?? false));
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      final label = status == 'zero' ? 'المخزون صفر' : 'المخزون سالب';
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('apply'.tr));
      await tester.tap(find.text('apply'.tr));
      await tester.pumpAndSettle();
      final filters = controller.productListFilters.value;
      expect(filters.stockStatus, status);
      expect(filters.search, 'فرامل');
      expect(filters.categoryId, '1');
      expect(filters.activeFilterCount, 2);
      expect(filters.toQueryParams(page: 2)['stock_status'], status);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.widget<DropdownButton<String?>>(dropdown).value, status);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('clear resets stock filter together with the other filters',
      (tester) async {
    final controller = _Controller();
    controller.productListFilters.value =
        const StockProductFilters(stockStatus: 'negative');
    await _open(tester, controller);
    await tester.ensureVisible(find.text('clear'.tr));
    await tester.tap(find.text('clear'.tr));
    await tester.pumpAndSettle();
    expect(controller.productListFilters.value.hasActiveFilters, isFalse);
    expect(controller.productListFilters.value.toQueryParams(page: 1),
        isNot(contains('stock_status')));
  });

  test(
      'search and location copies preserve stock filter until explicitly cleared',
      () {
    const original = StockProductFilters(stockStatus: 'zero');
    expect(original.hasActiveFilters, isTrue);
    expect(original.activeFilterCount, 1);
    final changed = original.copyWith(search: 'اكس', storeSectionId: '3');
    expect(changed.stockStatus, 'zero');
    expect(changed.copyWith(clearStoreSectionId: true).stockStatus, 'zero');
    expect(changed.copyWith(clearStockStatus: true).toQueryParams(page: 1),
        isNot(contains('stock_status')));
  });
}

Future<void> _open(WidgetTester tester, _Controller controller) async {
  Get.put<StockController>(controller);
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
                      onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => const StockFilterSheet()),
                      child: const Text('open')))))));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
