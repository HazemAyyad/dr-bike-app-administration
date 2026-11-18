import 'package:dio/dio.dart';
import 'package:doctorbike/core/databases/api/api_consumer.dart';
import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/features/admin/checks/domain/repositories/checks_repository.dart';
import 'package:doctorbike/features/admin/checks/domain/usecases/all_customers_sellers_usecase.dart';
import 'package:doctorbike/features/admin/sales/data/datasources/sales_datasources.dart';
import 'package:doctorbike/features/admin/sales/data/models/suspended_instant_sale_model.dart';
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
import 'package:doctorbike/features/admin/sales/presentation/utils/suspended_invoice_guard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

class _UnusedSalesRepository implements SalesRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedChecksRepository implements ChecksRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedDioConsumer implements DioConsumer {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingApi extends ApiConsumer {
  Map<String, dynamic> sent = {};

  @override
  Future<dynamic> post(
    String path, {
    Object? data,
    Options? options,
    Map<String, dynamic>? queryParameters,
    bool isFormData = false,
    Function(int, int)? onSendProgress,
  }) async {
    sent = Map<String, dynamic>.from(data as Map);
    return Response(
        requestOptions: RequestOptions(path: path),
        data: {'status': 'success'});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'resetting the sale clears its suspended identity before a new cart is built',
      () {
    Get.testMode = true;
    Get.put<DioConsumer>(_UnusedDioConsumer());
    addTearDown(() => Get.reset());
    final repo = _UnusedSalesRepository();
    final controller = SalesController(
      salesService: SalesService(),
      addProfitSaleUsecase: AddProfitSaleUsecase(salesRepository: repo),
      getProfitSalesUsecase: GetProfitSalesUsecase(salesRepository: repo),
      getInstantSalesUsecase: GetInstantSalesUsecase(salesRepository: repo),
      getAllProductsUsecase: GetAllProductsUsecase(salesRepository: repo),
      updateProductRetailPriceUsecase:
          UpdateProductRetailPriceUsecase(salesRepository: repo),
      addInstantSalesUsecase: AddInstantSalesUsecase(salesRepository: repo),
      invoiceModelUsecase: InvoiceModelUsecase(salesRepository: repo),
      getCustomerProductPriceHistoryUsecase:
          GetCustomerProductPriceHistoryUsecase(salesRepository: repo),
      allCustomersSellersUsecase: AllCustomersSellersUsecase(
          checksRepository: _UnusedChecksRepository()),
    );
    controller.activeSuspendedSaleId.value = 690;
    controller.items.first.selectedItem.value = '120';
    controller.items.first.quantityController.text = '111';
    controller.resetInstantSaleForm();
    controller.items.first.selectedItem.value = '978';
    controller.items.first.quantityController.text = '2';
    expect(controller.activeSuspendedSaleId.value, isNull);
    expect(controller.activeSuspendedReferenceCode, isNull);
  });

  test(
      'changing a known buyer needs confirmation, including changing to unknown',
      () {
    final original = {
      'buyer_type': 'customer',
      'buyer_id': '7',
      'buyer_name': 'خليل'
    };
    expect(
        SuspendedInvoiceGuard.needsBuyerConfirmation(original, {
          'buyer_type': 'seller',
          'seller_id': '44',
          'buyer_name': 'السيلاوي',
        }),
        isTrue);
    expect(
        SuspendedInvoiceGuard.needsBuyerConfirmation(
            original, {'buyer_type': 'unknown'}),
        isTrue);
    expect(
        SuspendedInvoiceGuard.needsBuyerConfirmation(original, {
          'buyer_type': 'customer',
          'buyer_id': 7,
          'buyer_name': 'خليل شحتوت',
        }),
        isFalse);
  });

  test(
      'selecting the first buyer at checkout does not count as replacing a buyer',
      () {
    expect(
        SuspendedInvoiceGuard.needsBuyerConfirmation({}, {
          'buyer_type': 'customer',
          'buyer_id': '7',
        }),
        isFalse);
  });

  test('suspended model keeps the server hash and tolerates older responses',
      () {
    expect(
        SuspendedInstantSaleModel.fromJson(
            {'id': 690, 'payload_hash': 'saved-version'}).payloadHash,
        'saved-version');
    expect(SuspendedInstantSaleModel.fromJson({'id': 690}).payloadHash, isNull);
  });

  test(
      'saving an edited suspended invoice sends its opened version and explicit confirmation',
      () async {
    final api = _RecordingApi();
    await SalesDatasource(api: api).suspendInstantSale(
      currentStep: 'checkout',
      payload: {'buyer_name': 'السيلاوي'},
      suspendedInstantSaleId: 690,
      expectedPayloadHash: 'opened-version',
      confirmBuyerChange: true,
    );
    expect(api.sent['suspended_instant_sale_id'], 690);
    expect(api.sent['expected_payload_hash'], 'opened-version');
    expect(api.sent['confirm_buyer_change'], isTrue);
  });

  test(
      'completion sends the opened version without inventing buyer confirmation',
      () async {
    final api = _RecordingApi();
    await SalesDatasource(api: api).completeSuspendedInstantSale(
      suspendedInstantSaleId: 690,
      expectedPayloadHash: 'opened-version',
      payload: {'buyer_name': 'خليل'},
    );
    expect(api.sent['expected_payload_hash'], 'opened-version');
    expect(api.sent.containsKey('confirm_buyer_change'), isFalse);
  });
}
