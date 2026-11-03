import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:dartz/dartz.dart';
import 'package:doctorbike/core/errors/failure.dart';
import 'package:doctorbike/core/services/translations_service.dart';
import 'package:doctorbike/routes/app_routes.dart';
import 'package:doctorbike/features/admin/checks/domain/repositories/checks_repository.dart';
import 'package:doctorbike/features/admin/checks/domain/usecases/all_customers_sellers_usecase.dart';
import 'package:doctorbike/features/admin/sales/domain/repositories/sales_repositores.dart';
import 'package:doctorbike/features/admin/sales/domain/usecases/add_instant_sales_usecase.dart';
import 'package:doctorbike/features/admin/sales/domain/usecases/add_profit_sale.dart';
import 'package:doctorbike/features/admin/sales/domain/usecases/get_all_products_usecase.dart';
import 'package:doctorbike/features/admin/sales/domain/usecases/get_customer_product_price_history_usecase.dart';
import 'package:doctorbike/features/admin/sales/domain/usecases/get_instant_sales_usecase.dart';
import 'package:doctorbike/features/admin/sales/domain/usecases/get_profit_sales_usecase.dart';
import 'package:doctorbike/features/admin/sales/domain/usecases/invoice_model_usecase.dart';
import 'package:doctorbike/features/admin/sales/domain/usecases/update_product_retail_price_usecase.dart';
import 'package:doctorbike/features/admin/sales/presentation/controllers/sales_controller.dart';
import 'package:doctorbike/features/admin/sales/presentation/controllers/sales_service.dart';
import 'package:doctorbike/features/admin/sales/presentation/widgets/new_instant_sale/discount_widget.dart';
import 'package:doctorbike/features/admin/sales/presentation/views/instant_sale_product_picker_screen.dart';
import 'package:doctorbike/features/admin/sales_orders/data/models/sales_order_model.dart';
import 'package:doctorbike/features/admin/sales_orders/data/repositories/sales_orders_implement.dart';
import 'package:doctorbike/features/admin/sales_orders/presentation/controllers/sales_orders_controller.dart';
import 'package:doctorbike/features/admin/payment_method/presentation/controllers/payment_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.testMode = true;
    Get.put<DioConsumer>(_DioConsumer());
  });
  tearDown(Get.reset);

  testWidgets(
      'the order picker opens service checkout without selecting a product',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sales = _controller();
    Get.put<SalesOrdersController>(_OrdersController(_OrdersRepository()));
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => GetMaterialApp(
        translations: Translation(),
        locale: const Locale('ar'),
        initialRoute: AppRoutes.NEWSALESORDERSCREEN,
        getPages: [
          GetPage(
              name: AppRoutes.NEWSALESORDERSCREEN,
              page: () => const InstantSaleProductPickerScreen())
        ],
      ),
    ));
    await tester.pumpAndSettle();
    expect(sales.cartLines, isEmpty);
    await tester.tap(find.text('طلبية خدمة'));
    expect(sales.checkoutOpens, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  test('service-only checkout saves notes and payment without any stock prompt',
      () async {
    final sales = _controller();
    final repository = _OrdersRepository();
    final orders =
        Get.put<SalesOrdersController>(_OrdersController(repository));
    Get.put<PaymentController>(_PaymentController(),
        tag: kSalesOrderPaymentTag);
    orders.manualDeliveryFee.value = 5;
    sales.discountController.text = '10';
    sales.saveInstantSaleNoteLine(text: 'خدمة تركيب', amount: '100');

    expect(await orders.submitCreateOrderFromCheckout(sales), isTrue);
    final body = repository.created!;
    expect(body['items'], isEmpty);
    expect(body['additional_notes'], [
      {'text': 'خدمة تركيب', 'amount': 100.0}
    ]);
    expect(body['discount'], 10);
    expect(body['total'], 95);
    expect(body['payment_type'], 'mixed');
    expect(body['payment_amount'], 25);
    expect(body['reserve_stock'], isFalse);
    expect(sales.instantSaleNotes, isEmpty);
    expect(orders.detail.value?.additionalNotes.single.text, 'خدمة تركيب');
  });

  test('checkout rejects an empty order or a free note without products',
      () async {
    final sales = _controller();
    final repository = _OrdersRepository();
    final orders =
        Get.put<SalesOrdersController>(_OrdersController(repository));
    expect(await orders.submitCreateOrderFromCheckout(sales), isFalse);
    sales.saveInstantSaleNoteLine(text: 'ملاحظة فقط', amount: '0');
    expect(await orders.submitCreateOrderFromCheckout(sales), isFalse);
    expect(repository.created, isNull);
  });

  test('editing a service-only order restores its total without product rows',
      () async {
    final sales = _controller();
    final order = SalesOrderDetailModel.fromJson({
      'id': 42,
      'discount': 10,
      'customer_delivery_fee': 5,
      'total': 95,
      'additional_notes': [
        {'text': 'خدمة تركيب', 'amount': 100}
      ],
      'items': [],
    });
    await sales.hydrateFromSalesOrder(order);
    expect(sales.cartLines, isEmpty);
    expect(sales.totalCost.value, 90);
    expect(sales.totalCost.value + order.customerDeliveryFee, order.total);
  });

  test('order editing restores paid and free notes into the shared sales cart',
      () async {
    final sales = _controller();
    final order = SalesOrderDetailModel.fromJson({
      'id': 42,
      'subtotal': 100,
      'discount': 10,
      'customer_delivery_fee': 20,
      'total': 125.5,
      'additional_notes': [
        {'text': 'تركيب', 'amount': 15.5},
        {'text': 'ملاحظة مجانية', 'amount': 0},
      ],
      'items': [
        {'id': 1, 'product_id': 1, 'quantity': 2, 'unit_price': 50}
      ],
    });
    await sales.hydrateFromSalesOrder(order);
    sales.activeEditInstantSaleId.value = 42;
    expect(sales.instantSaleNotes.length, 2);
    expect(sales.instantSaleNotesTotal, 15.5);
    expect(sales.totalCost.value, 105.5);
    expect(sales.totalCost.value + order.customerDeliveryFee, order.total);
    expect(order.netPrice, 105.5);
    expect(sales.instantSaleNotesPayload(), [
      {'text': 'تركيب', 'amount': 15.5},
      {'text': 'ملاحظة مجانية', 'amount': 0.0},
    ]);
    sales.saveInstantSaleNoteLine(
        index: 0, text: 'تركيب وتعديل', amount: '٢٥٫٢٥');
    expect(sales.totalCost.value, 115.25);
    sales.removeInstantSaleNoteLine(0);
    expect(sales.totalCost.value, 90);
    sales.resetInstantSaleForm();
    expect(sales.instantSaleNotes, isEmpty);
    expect(SalesOrderDetailModel.fromJson({'id': 43}).additionalNotes, isEmpty);
  });

  testWidgets(
      'shared note sheet adds, edits, cancels and deletes an order charge',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sales = _controller();
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => GetMaterialApp(
        translations: Translation(),
        locale: const Locale('ar'),
        home: const Scaffold(
          body: SingleChildScrollView(child: InstantSaleNotesRepeater()),
        ),
      ),
    ));
    await tester.tap(find.text('addNote'.tr).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'تركيب');
    await tester.enterText(find.byType(TextFormField).at(1), '١٥٫٥');
    await tester.tap(find.text('save'.tr));
    await tester.pumpAndSettle();
    expect(sales.instantSaleNotesTotal, 15.5);
    expect(find.text('تركيب'), findsOneWidget);

    await tester.tap(find.byTooltip('edit'.tr));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '٢٥');
    await tester.tap(find.text('save'.tr));
    await tester.pumpAndSettle();
    expect(sales.instantSaleNotesTotal, 25);

    await tester.tap(find.byTooltip('edit'.tr));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '٩٩');
    await tester.tap(find.text('cancel'.tr));
    await tester.pumpAndSettle();
    expect(sales.instantSaleNotesTotal, 25);
    await tester.tap(find.byTooltip('delete'.tr));
    await tester.pumpAndSettle();
    expect(sales.instantSaleNotes, isEmpty);
    expect(sales.instantSaleNotesTotal, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

_SalesController _controller() {
  final sales = _SalesController(_SalesRepository());
  sales.activeEditInstantSaleId.value = 42;
  sales.animController = AnimationController(vsync: sales);
  Get.put<SalesController>(sales);
  addTearDown(() => sales.clearCartLines(deferDispose: false));
  return sales;
}

class _SalesController extends SalesController {
  int checkoutOpens = 0;
  _SalesController(SalesRepository repository)
      : super(
          salesService: SalesService(),
          addProfitSaleUsecase:
              AddProfitSaleUsecase(salesRepository: repository),
          getProfitSalesUsecase:
              GetProfitSalesUsecase(salesRepository: repository),
          getInstantSalesUsecase:
              GetInstantSalesUsecase(salesRepository: repository),
          getAllProductsUsecase:
              GetAllProductsUsecase(salesRepository: repository),
          updateProductRetailPriceUsecase:
              UpdateProductRetailPriceUsecase(salesRepository: repository),
          addInstantSalesUsecase:
              AddInstantSalesUsecase(salesRepository: repository),
          invoiceModelUsecase: InvoiceModelUsecase(salesRepository: repository),
          getCustomerProductPriceHistoryUsecase:
              GetCustomerProductPriceHistoryUsecase(
                  salesRepository: repository),
          allCustomersSellersUsecase:
              AllCustomersSellersUsecase(checksRepository: _ChecksRepository()),
        );

  @override
  // Initial list and lookup requests are outside this checkout test.
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<void> ensurePickerPartnersLoaded() async {}

  @override
  Future<void> getAllProducts({bool showLoading = true}) async {}

  @override
  Future<void> ensurePickerStoreSectionsLoaded({bool force = false}) async {}

  @override
  Future<void> loadDailySession() async {}

  @override
  void openSalesOrderCheckout() {
    checkoutOpens++;
  }
}

class _SalesRepository extends Fake implements SalesRepository {}

class _ChecksRepository extends Fake implements ChecksRepository {}

class _DioConsumer extends Fake implements DioConsumer {}

class _OrdersRepository extends Fake implements SalesOrdersRepository {
  Map<String, dynamic>? created;

  @override
  Future<Either<Failure, SalesOrderDetailModel>> createOrder(
      Map<String, dynamic> body) async {
    created = Map<String, dynamic>.from(body);
    return Right(SalesOrderDetailModel.fromJson({'id': 42, ...body}));
  }
}

class _OrdersController extends SalesOrdersController {
  _OrdersController(SalesOrdersRepository repository)
      : super(repository: repository);

  @override
  // List requests are outside checkout submission tests.
  // ignore: must_call_super
  void onInit() {}

  @override
  void openOrderDetailAfterSave(SalesOrderDetailModel order) {
    detail.value = order;
  }
}

class _PaymentController extends GetxController implements PaymentController {
  @override
  final cashValueController = TextEditingController(text: '25');

  @override
  Map<String, dynamic> buildInstantSaleBuyerPayload() => {};

  @override
  void onClose() {
    cashValueController.dispose();
    super.onClose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
