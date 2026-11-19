import 'dart:async';

import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/features/admin/checks/domain/repositories/checks_repository.dart';
import 'package:doctorbike/features/admin/checks/domain/usecases/all_customers_sellers_usecase.dart';
import 'package:doctorbike/features/admin/sales/data/models/invoice_model.dart';
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
import 'package:doctorbike/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<DioConsumer>(_UnusedDio());
  });
  tearDown(() => Get.reset());

  testWidgets('opens invoice before the network completes and can go back',
      (tester) async {
    final repository = _SalesRepository();
    final controller = _controller(repository);
    controller.invoiceModel = _invoice(99);
    await tester.pumpWidget(GetMaterialApp(
      home: const Scaffold(body: Text('دفتر الديون')),
      getPages: [
        GetPage(
          name: AppRoutes.INSTANTSALEBILLDETAILSSCREEN,
          page: () => Scaffold(
            appBar: AppBar(title: const Text('الفاتورة')),
            body: Obx(() => controller.isLoading.value
                ? const CircularProgressIndicator()
                : Text('فاتورة ${controller.invoiceModel?.id}')),
          ),
        ),
      ],
    ));
    var returned = false;
    final opening = controller.openInstantSaleBillDetails('1').then((_) {
      returned = true;
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('الفاتورة'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(controller.invoiceModel, isNull);
    expect(repository.requests['1']!.isCompleted, isFalse);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(returned, isTrue);
    expect(find.text('دفتر الديون'), findsOneWidget);
    repository.requests['1']!.complete(_invoice(1));
    await opening;
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('an older response cannot replace a newer invoice or stop its loader',
      () async {
    final repository = _SalesRepository();
    final controller = _controller(repository);
    final first = controller.getInvoice(invoiceId: '1');
    final second = controller.getInvoice(invoiceId: '2');
    repository.requests['1']!.complete(_invoice(1));
    await first;
    expect(controller.invoiceModel, isNull);
    expect(controller.isLoading.value, isTrue);
    repository.requests['2']!.complete(_invoice(2));
    await second;
    expect(controller.invoiceModel!.id, 2);
    expect(controller.isLoading.value, isFalse);
  });
}

InvoiceModel _invoice(int id) => InvoiceModel.fromJson({'id': id});

SalesController _controller(SalesRepository repository) => SalesController(
      salesService: SalesService(),
      addProfitSaleUsecase: AddProfitSaleUsecase(salesRepository: repository),
      getProfitSalesUsecase: GetProfitSalesUsecase(salesRepository: repository),
      getInstantSalesUsecase:
          GetInstantSalesUsecase(salesRepository: repository),
      getAllProductsUsecase: GetAllProductsUsecase(salesRepository: repository),
      updateProductRetailPriceUsecase:
          UpdateProductRetailPriceUsecase(salesRepository: repository),
      addInstantSalesUsecase:
          AddInstantSalesUsecase(salesRepository: repository),
      invoiceModelUsecase: InvoiceModelUsecase(salesRepository: repository),
      getCustomerProductPriceHistoryUsecase:
          GetCustomerProductPriceHistoryUsecase(salesRepository: repository),
      allCustomersSellersUsecase: AllCustomersSellersUsecase(
          checksRepository: _UnusedChecksRepository()),
    );

class _SalesRepository implements SalesRepository {
  final requests = <String, Completer<InvoiceModel>>{};

  @override
  Future<InvoiceModel> getInvoice({required String invoiceId}) =>
      (requests[invoiceId] = Completer<InvoiceModel>()).future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedChecksRepository implements ChecksRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedDio implements DioConsumer {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
