import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/features/admin/checks/domain/repositories/checks_repository.dart';
import 'package:doctorbike/features/admin/checks/domain/usecases/all_customers_sellers_usecase.dart';
import 'package:doctorbike/features/admin/sales/data/models/instant_sales_model.dart';
import 'package:doctorbike/features/admin/sales/data/models/profit_sale_model.dart';
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
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => Get.put<DioConsumer>(_DioConsumer()));
  tearDown(Get.reset);

  test('daily sales total excludes cancelled invoices and follows the day', () {
    final sales = _controller();
    sales.selectedInstantSalesDate.value = DateTime(2026, 11, 2);
    sales.salesService.instantSalesTasks['invoices'] = [
      _sale(1, '١٬٢٠٠٫٥٠', 2),
      _sale(2, '24.25', 2),
      _sale(3, '500', 2, status: 'cancelled'),
      _sale(4, '70', 1),
    ];
    expect(sales.instantSalesDayTotal, 1224.75);
    sales.instantSalesPackageFilter.value = 1;
    expect(sales.instantSalesDayTotal, 1224.75);
    sales.selectedInstantSalesDate.value = DateTime(2026, 11, 1);
    expect(sales.instantSalesDayTotal, 70);
    sales.selectedInstantSalesDate.value = DateTime(2026, 10, 31);
    expect(sales.instantSalesDayTotal, 0);
    sales.instantSalesSearchQuery.value = 'زبون';
    expect(sales.instantSalesDayTotal, 1294.75);
  });

  test('profit total excludes both cancellation forms and handles empty days',
      () {
    final sales = _controller();
    sales.selectedProfitSalesDate.value = DateTime(2026, 11, 2);
    ProfitSale profit(int id, String amount, int day,
            {String? status, String? cancelledAt}) =>
        ProfitSale(
          id: id,
          totalCost: amount,
          notes: '',
          createdAt: DateTime(2026, 11, day, 12),
          updatedAt: DateTime(2026, 11, day, 12),
          status: status,
          cancelledAt: cancelledAt,
        );
    sales.salesService.filterProfitSalesTasks['invoices'] = [
      profit(1, '10.50', 2),
      profit(2, '٢٥٫٢٥', 2),
      profit(3, '500', 2, status: 'cancelled'),
      profit(4, '500', 2, cancelledAt: '2026-11-02 13:00:00'),
      profit(5, '30', 1),
    ];
    expect(sales.profitSalesDayTotal, 35.75);
    sales.selectedProfitSalesDate.value = DateTime(2026, 11, 1);
    expect(sales.profitSalesDayTotal, 30);
    sales.profitSalesSearchQuery.value = 'زبون';
    expect(sales.profitSalesDayTotal, 65.75);
    sales.salesService.filterProfitSalesTasks.clear();
    expect(sales.profitSalesDayTotal, 0);
  });
}

InstantSalesModel _sale(int id, String total, int day, {String? status}) =>
    InstantSalesModel(
      id: id,
      product: 'منتج',
      cost: '100',
      totalCost: total,
      quantity: '2',
      date: DateTime(2026, 11, day),
      notes: '',
      paidAmount: '0',
      status: status,
    );

SalesController _controller() {
  final repository = _SalesRepository();
  final service = SalesService();
  service.instantSalesTasks.clear();
  service.filterInstantSalesTasks.clear();
  service.profitSalesTasks.clear();
  service.filterProfitSalesTasks.clear();
  final sales = SalesController(
    salesService: service,
    addProfitSaleUsecase: AddProfitSaleUsecase(salesRepository: repository),
    getProfitSalesUsecase: GetProfitSalesUsecase(salesRepository: repository),
    getInstantSalesUsecase: GetInstantSalesUsecase(salesRepository: repository),
    getAllProductsUsecase: GetAllProductsUsecase(salesRepository: repository),
    updateProductRetailPriceUsecase:
        UpdateProductRetailPriceUsecase(salesRepository: repository),
    addInstantSalesUsecase: AddInstantSalesUsecase(salesRepository: repository),
    invoiceModelUsecase: InvoiceModelUsecase(salesRepository: repository),
    getCustomerProductPriceHistoryUsecase:
        GetCustomerProductPriceHistoryUsecase(salesRepository: repository),
    allCustomersSellersUsecase:
        AllCustomersSellersUsecase(checksRepository: _ChecksRepository()),
  );
  sales.animController = AnimationController(vsync: sales);
  addTearDown(sales.onClose);
  return sales;
}

class _SalesRepository extends Fake implements SalesRepository {}

class _ChecksRepository extends Fake implements ChecksRepository {}

class _DioConsumer extends Fake implements DioConsumer {}
