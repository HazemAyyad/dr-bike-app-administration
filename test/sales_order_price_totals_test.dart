import 'package:doctorbike/core/databases/api/dio_consumer.dart';
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
import 'package:doctorbike/features/admin/sales/presentation/models/instant_sale_cart_line.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => Get.put<DioConsumer>(_DioConsumer()));
  tearDown(Get.reset);

  test('edited order prices immediately update the discounted cart total', () {
    final sales = _salesController();
    final first = _line('1', quantity: '2', price: '100');
    final second = _line('2', quantity: '1', price: '50');
    sales.discountController.text = '10';
    sales.addCartLine(first);
    sales.addCartLine(second);
    expect(sales.totalCost.value, 240);

    first.priceController.text = '125.50';
    expect(first.lineTotal.value, 251);
    expect(sales.totalCost.value, 291);
    expect(sales.totalController.text, '291');

    second.priceController.text = '20';
    expect(sales.totalCost.value, 261);
    first.quantityController.text = '3';
    expect(sales.totalCost.value, 386.5);
  });

  testWidgets('replaced and removed lines stop affecting the total',
      (tester) async {
    final sales = _salesController();
    final original = _line('1', quantity: '2', price: '100');
    final replacement = _line('1', quantity: '2', price: '75');
    sales.addCartLine(original);
    sales.updateCartLine(0, replacement);
    original.priceController.text = '999';
    expect(sales.totalCost.value, 150);
    replacement.priceController.text = '80';
    expect(sales.totalCost.value, 160);

    sales.removeCartLine(0);
    replacement.priceController.text = '999';
    expect(sales.totalCost.value, 0);
    await tester.pump();
  });

  for (final stock in [-5, 0, 3]) {
    test('confirmed order quantity can exceed stock $stock', () {
      final sales = _salesController();
      sales.salesOrderStockMode.value = true;
      final line = _line('1', quantity: '1', price: '10', stock: stock);
      sales.addCartLine(line);

      sales.setCartLineQuantity(0, 25);

      expect(line.quantityText, '25');
      expect(line.lineTotal.value, 250);
      expect(sales.totalCost.value, 250);
    });
  }
}

InstantSaleCartLine _line(String id,
        {required String quantity, required String price, int stock = 100}) =>
    InstantSaleCartLine(
      productId: id,
      productName: 'منتج',
      imageUrl: '',
      stock: stock,
      initialQuantity: quantity,
      initialPrice: price,
    );

SalesController _salesController() {
  final repository = _SalesRepository();
  final sales = SalesController(
    salesService: SalesService(),
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
  sales.activeEditInstantSaleId.value = 42;
  sales.animController = AnimationController(vsync: sales);
  addTearDown(() {
    sales.clearCartLines(deferDispose: false);
    sales.onClose();
  });
  return sales;
}

class _SalesRepository extends Fake implements SalesRepository {}

class _ChecksRepository extends Fake implements ChecksRepository {}

class _DioConsumer extends Fake implements DioConsumer {}
