import 'dart:async';

import 'package:doctorbike/features/admin/boxes/data/models/get_shown_boxes_model.dart';
import 'package:doctorbike/features/admin/boxes/domain/repositories/boxes_repository.dart';
import 'package:doctorbike/features/admin/boxes/domain/usecases/get_shown_box_usecase.dart';
import 'package:doctorbike/features/admin/buying/domain/repositories/bills_repository.dart';
import 'package:doctorbike/features/admin/buying/domain/usecases/bills_usecases/add_bill_usecase.dart';
import 'package:doctorbike/features/admin/buying/domain/usecases/get_bills_usecase.dart';
import 'package:doctorbike/features/admin/buying/domain/usecases/get_billt_details_usecase.dart';
import 'package:doctorbike/features/admin/buying/domain/usecases/purchase_workflow_usecase.dart';
import 'package:doctorbike/features/admin/buying/presentation/controllers/bills_controller.dart';
import 'package:doctorbike/features/admin/buying/presentation/views/bills_screens/add_new_bill_screen.dart';
import 'package:doctorbike/features/admin/checks/data/models/check_model.dart';
import 'package:doctorbike/features/admin/checks/domain/repositories/checks_repository.dart';
import 'package:doctorbike/features/admin/checks/domain/usecases/all_customers_sellers_usecase.dart';
import 'package:doctorbike/features/admin/sales/data/models/product_model.dart';
import 'package:doctorbike/features/admin/sales/data/models/product_variant_model.dart';
import 'package:doctorbike/features/admin/sales/domain/repositories/sales_repositores.dart';
import 'package:doctorbike/features/admin/sales/domain/usecases/get_all_products_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  tearDown(Get.reset);

  group('Modern purchase creation screen', () {
    testWidgets(
        'failed creation and duplicate choice preserve existing purchase quantities',
        (tester) async {
      const variant = ProductColorVariant(
          id: '20', sizeId: '10', colorAr: 'أحمر', stock: 5, normailPrice: 30);
      const size =
          ProductSizeVariant(id: '10', size: 'M', colorSizes: [variant]);
      final product = _product('1', 'قميص')
          .copyWith(hasVariants: true, sizes: const [size]);
      var fail = true;
      var calls = 0;
      final controller = _putController(
        productsLoader: () async => [product],
        createVariant: (payload) async {
          calls++;
          if (fail) throw Exception('انقطع الاتصال');
          return const PurchaseVariantOption(size: size, variant: variant);
        },
      );
      controller.syncPurchaseProductVariants(product, const [
        PurchaseVariantSelection(
            size: size, variant: variant, quantity: 7, unitPriceText: '12'),
      ]);
      await _pumpScreen(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('قميص'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إضافة لون أو حجم'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ واختيار'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.text('أدخل الحجم'), findsOneWidget);
      expect(find.text('أدخل اللون'), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('purchase_variant_size')), 'M');
      await tester.enterText(
          find.byKey(const Key('purchase_variant_color')), 'أحمر');
      await tester.tap(find.text('حفظ واختيار'));
      await tester.pumpAndSettle();
      expect(find.textContaining('انقطع الاتصال'), findsOneWidget);
      expect(controller.purchaseCart.single.quantity, 7);
      fail = false;
      await tester.tap(find.text('حفظ واختيار'));
      await tester.pumpAndSettle();
      expect(find.text('M / أحمر'), findsOneWidget);
      expect(find.text('تأكيد الاختيار (1)'), findsOneWidget);
      await tester.tap(find.text('تأكيد الاختيار (1)'));
      await tester.pumpAndSettle();
      expect(controller.purchaseCart.length, 1);
      expect(controller.purchaseCart.single.quantity, 7);
      expect(controller.products.single.sizes.single.colorSizes.length, 1);
      expect(tester.takeException(), isNull);
    });
    testWidgets(
        'adds new purchase colors and sizes and preserves them on reopening',
        (tester) async {
      final product = _product('1', 'قميص').copyWith(
        hasVariants: true,
        sizes: const [
          ProductSizeVariant(id: '10', size: 'M', colorSizes: [
            ProductColorVariant(
                id: '20',
                sizeId: '10',
                colorAr: 'أحمر',
                stock: 5,
                normailPrice: 30),
          ])
        ],
      );
      final payloads = <Map<String, dynamic>>[];
      final controller = _putController(
        productsLoader: () async => [product],
        createVariant: (payload) async {
          payloads.add(payload);
          final sizeId = payload['size'] == 'M' ? '10' : '11';
          return PurchaseVariantOption(
            size: ProductSizeVariant(
                id: sizeId,
                size: payload['size'] as String,
                colorSizes: const []),
            variant: ProductColorVariant(
                id: '${20 + payloads.length}',
                sizeId: sizeId,
                colorAr: payload['color'] as String,
                stock: 0,
                normailPrice: payload['retail_price'] as double),
          );
        },
      );
      await _pumpScreen(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('قميص'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox).first);
      final quantity = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'الكمية');
      await tester.enterText(quantity.first, '7');

      Future<void> addVariant(String size, String color) async {
        await tester.tap(find.text('إضافة لون أو حجم'));
        await tester.pumpAndSettle();
        await tester.enterText(
            find.byKey(const Key('purchase_variant_size')), size);
        await tester.enterText(
            find.byKey(const Key('purchase_variant_color')), color);
        await tester.enterText(
            find.byKey(const Key('purchase_variant_retail_price')), '35');
        await tester.tap(find.text('حفظ واختيار'));
        await tester.pumpAndSettle();
      }

      await addVariant('M', 'أزرق');
      expect(find.text('M / أزرق'), findsOneWidget);
      await addVariant('XL', 'أخضر');
      expect(payloads.last['size'], 'XL');
      expect(payloads.last['color'], 'أخضر');
      await tester.scrollUntilVisible(find.text('XL / أخضر'), 200,
          scrollable: find
              .descendant(
                  of: find.byType(ListView).last,
                  matching: find.byType(Scrollable))
              .first);
      expect(find.text('XL / أخضر'), findsOneWidget);
      expect(find.text('تأكيد الاختيار (3)'), findsOneWidget);
      await tester.tap(find.text('تأكيد الاختيار (3)'));
      await tester.pumpAndSettle();
      expect(payloads.first, {
        'product_id': '1',
        'size': 'M',
        'color': 'أزرق',
        'retail_price': 35.0
      });
      expect(controller.purchaseCart.length, 3);
      expect(controller.purchaseCart.first.quantity, 7);
      expect(controller.purchaseCart.last.sizeId, '11');
      expect(controller.purchaseCart.last.sizeColorId, '22');
      expect(controller.products.single.sizes.length, 2);
      expect(controller.products.single.sizes.first.colorSizes.length, 2);

      await tester.tap(find.text('قميص'));
      await tester.pumpAndSettle();
      expect(find.text('تأكيد الاختيار (3)'), findsOneWidget);
      expect(find.text('M / أزرق'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('XL / أخضر'), 200,
          scrollable: find
              .descendant(
                  of: find.byType(ListView).last,
                  matching: find.byType(Scrollable))
              .first);
      expect(find.text('XL / أخضر'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    testWidgets('shows source action, search, loading and cart action',
        (tester) async {
      final products = Completer<List<ProductModel>>();
      final controller = _putController(
        productsLoader: () => products.future,
      );
      controller.purchaseProductsStatus.value = PurchaseLoadStatus.loading;
      controller.update();

      await _pumpScreen(tester);

      expect(find.byIcon(Icons.person_search_outlined), findsWidgets);
      expect(find.text('ابحث عن منتج للشراء'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsWidgets);
    });

    testWidgets('renders loaded product cards', (tester) async {
      _putController(
        productsLoader: () async => [
          _product('1', 'بطارية دراجة'),
          _product('2', 'فرامل أمامية'),
        ],
      );

      await _pumpScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('بطارية دراجة'), findsOneWidget);
      expect(find.text('فرامل أمامية'), findsOneWidget);
    });

    testWidgets('quantity controls update the cart and remove at zero',
        (tester) async {
      final controller = _putController(
        productsLoader: () async => [_product('1', 'بطارية دراجة')],
      );
      await _pumpScreen(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('زيادة الكمية'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('زيادة الكمية'));
      await tester.pumpAndSettle();
      expect(controller.purchaseCartQtyForProduct('1'), 2);
      expect(controller.totalCost.value, 24);

      await tester.tap(find.byTooltip('تقليل الكمية'));
      await tester.pumpAndSettle();
      expect(controller.purchaseCartQtyForProduct('1'), 1);
      await tester.tap(find.byTooltip('تقليل الكمية'));
      await tester.pumpAndSettle();
      expect(controller.purchaseCart, isEmpty);
      expect(controller.totalCost.value, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'quantity number accepts direct entry and validates empty input',
        (tester) async {
      final controller = _putController(
        productsLoader: () async => [_product('1', 'بطارية دراجة')],
      );
      await _pumpScreen(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('purchase_quantity_1')));
      await tester.pumpAndSettle();
      final input = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(input, '');
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();
      expect(find.text('أدخل كمية صحيحة'), findsOneWidget);
      expect(controller.purchaseCart, isEmpty);

      await tester.enterText(input, '25');
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();
      expect(controller.purchaseCartQtyForProduct('1'), 25);
      expect(controller.totalCost.value, 300);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders empty state when no products exist', (tester) async {
      _putController(productsLoader: () async => <ProductModel>[]);

      await _pumpScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('لا توجد منتجات'), findsOneWidget);
    });

    testWidgets('renders product loading error and retry', (tester) async {
      _putController(
        productsLoader: () async => throw StateError('products failed'),
      );

      await _pumpScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('تعذر تحميل المنتجات'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });

    testWidgets('empty search shows all and typed search filters products',
        (tester) async {
      _putController(
        productsLoader: () async => [
          _product('1', 'بطارية دراجة'),
          _product('2', 'فرامل أمامية'),
        ],
      );

      await _pumpScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('بطارية دراجة'), findsOneWidget);
      expect(find.text('فرامل أمامية'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'بطارية');
      await tester.pump();

      expect(find.text('بطارية دراجة'), findsOneWidget);
      expect(find.text('فرامل أمامية'), findsNothing);
    });

    testWidgets('missing product image does not throw', (tester) async {
      _putController(
        productsLoader: () async => [
          _product('1', 'منتج بدون صورة', imageUrl: ''),
        ],
      );

      await _pumpScreen(tester);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('منتج بدون صورة'), findsOneWidget);
    });
  });
}

Future<void> _pumpScreen(WidgetTester tester) {
  return tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => const GetMaterialApp(
        locale: Locale('ar'),
        home: AddNewBillScreen(),
      ),
    ),
  );
}

BillsController _putController({
  required Future<List<ProductModel>> Function() productsLoader,
  Future<List<SellerModel>> Function(String endPoint)? peopleLoader,
  Future<PurchaseVariantOption> Function(Map<String, dynamic>)? createVariant,
}) {
  final billsRepository = _FakeBillsRepository()..createVariant = createVariant;
  final controller = BillsController(
    getBillsUsecase: GetBillsUsecase(billsRepository: billsRepository),
    getAllProductsUsecase: GetAllProductsUsecase(
      salesRepository: _FakeSalesRepository(productsLoader),
    ),
    allCustomersSellersUsecase: AllCustomersSellersUsecase(
      checksRepository: _FakeChecksRepository(
        peopleLoader ?? (_) async => <SellerModel>[],
      ),
    ),
    addBillUsecase: AddBillUsecase(billsRepository: billsRepository),
    getBilltDetailsUsecase:
        GetBilltDetailsUsecase(billsRepository: billsRepository),
    purchaseWorkflowUsecase:
        PurchaseWorkflowUsecase(billsRepository: billsRepository),
    getShownBoxUsecase: GetShownBoxUsecase(
      boxesRepository: _FakeBoxesRepository(),
    ),
  );
  return Get.put(controller);
}

ProductModel _product(String id, String name, {String imageUrl = ''}) {
  return ProductModel(
    id: id,
    nameAr: name,
    stock: '5',
    projects: const [],
    purchaseCost: 12,
    imageUrl: imageUrl,
  );
}

class _FakeSalesRepository implements SalesRepository {
  _FakeSalesRepository(this.productsLoader);

  final Future<List<ProductModel>> Function() productsLoader;

  @override
  Future<List<ProductModel>> getAllProducts({
    required String endPoint,
    String? customerId,
    String? sellerId,
    String? search,
    String? storeSectionId,
  }) {
    return productsLoader();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeChecksRepository implements ChecksRepository {
  _FakeChecksRepository(this.peopleLoader);

  final Future<List<SellerModel>> Function(String endPoint) peopleLoader;

  @override
  Future<List<SellerModel>> allCustomersSellers({required String endPoint}) {
    return peopleLoader(endPoint);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBillsRepository implements BillsRepository {
  Future<PurchaseVariantOption> Function(Map<String, dynamic>)? createVariant;

  @override
  Future<PurchaseVariantOption> createPurchaseVariant(
          Map<String, dynamic> payload) =>
      createVariant!(payload);
  @override
  Future<dynamic> getBills({required String page}) async => {'bills': []};

  @override
  Future<dynamic> purchaseAmanatIndex({String? status, String? search}) async {
    return {'amanat': []};
  }

  @override
  Future<dynamic> purchaseDiscrepancies({String? type, String? search}) async {
    return {'discrepancies': []};
  }

  @override
  Future<dynamic> purchasePriceIntelligence({
    required String productId,
    String? sellerId,
    String? customerId,
  }) async {
    return {'price_intelligence': {}};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBoxesRepository implements BoxesRepository {
  @override
  Future<List<ShownBoxesModel>> getShownBoxes({required int screen}) async {
    return <ShownBoxesModel>[];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
