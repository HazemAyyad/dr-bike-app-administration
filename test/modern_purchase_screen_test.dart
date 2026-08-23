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
    testWidgets('shows selector, search, loading and bottom summary',
        (tester) async {
      final controller = _putController(
        productsLoader: () async => <ProductModel>[],
      );
      controller.purchaseProductsStatus.value = PurchaseLoadStatus.loading;
      controller.update();

      await _pumpScreen(tester);

      expect(find.text('اختر المورد أو الزبون'), findsOneWidget);
      expect(find.text('ابحث عن منتج للشراء'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text('الإجمالي'), findsOneWidget);
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
}) {
  final billsRepository = _FakeBillsRepository();
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
