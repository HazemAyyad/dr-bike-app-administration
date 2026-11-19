import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/features/admin/checks/data/models/check_model.dart';
import 'package:doctorbike/features/admin/sales/data/models/invoice_model.dart';
import 'package:doctorbike/features/admin/sales/data/models/product_model.dart';
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

  for (final editing in [false, true]) {
    test(
        'price, quantity and bonus changes update ${editing ? 'edited' : 'new'} sales',
        () {
      final sales = _salesController(editing: editing);
      final paid = _line('1', quantity: '2', price: '100');
      final bonus = _line('1', quantity: '3', price: '50')..isBonus = true;
      bonus.recalculateTotal();
      sales.addCartLine(paid);
      sales.addCartLine(bonus);
      sales.syncCartToItems();
      expect(sales.cartLines.length, 2);
      expect(sales.totalCost.value, 200);

      paid.priceController.text = '125.50';
      expect(sales.totalCost.value, 251);
      paid.quantityController.text = '3';
      expect(sales.totalCost.value, 376.5);
      bonus.quantityController.text = '8';
      bonus.priceController.text = '999';
      expect(sales.totalCost.value, 376.5);
      expect(bonus.lineTotal.value, 0);
      expect(sales.buildCartOtherProductsPayload().last['cost'], '0');
      expect(sales.buildCartOtherProductsPayload().last['is_bonus'], true);

      sales.setCartLineBonus(0, true);
      expect(sales.totalCost.value, 0);
      sales.setCartLineBonus(0, false);
      expect(sales.totalCost.value, 376.5);
    });
  }

  test('administrative corrections keep recalculating after invoice hydration',
      () async {
    final sales = _salesController(administrative: true);
    await sales.hydrateFromInvoice(InvoiceModel.fromJson({
      'id': 42,
      'product_id': '1',
      'quantity': '2',
      'cost': '100',
      'discount': '10',
      'total_cost': '190',
      'sub_products': [
        {
          'id': 43,
          'product_id': '1',
          'quantity': '3',
          'cost': '0',
          'is_bonus': true
        },
      ],
    }));
    expect(sales.totalCost.value, 190);
    sales.cartLines.first.priceController.text = '125';
    expect(sales.totalCost.value, 240);
    sales.cartLines.first.quantityController.text = '3';
    expect(sales.totalCost.value, 365);
    sales.cartLines.last.quantityController.text = '8';
    expect(sales.totalCost.value, 365);
    sales.saveInstantSaleNoteLine(text: 'Delivery', amount: '5');
    expect(sales.totalCost.value, 370);
    expect(sales.totalController.text, '370');
  });

  testWidgets('removing the final synced product clears its invoice total',
      (tester) async {
    final sales = _salesController();
    sales.addCartLine(_line('1', quantity: '2', price: '100'));
    sales.syncCartToItems();
    sales.removeCartLine(0);
    sales.syncCartToItems();
    expect(sales.totalCost.value, 0);
    expect(sales.totalController.text, '0');
    await tester.pump();
  });

  test('syncing extra products preserves package quantity and price', () {
    final sales = _salesController();
    sales.isPackageSale.value = true;
    sales.selectedPackageId.value = 7;
    sales.items.first.quantityController.text = '2';
    sales.items.first.priceController.text = '100';
    sales.addCartLine(_line('1', quantity: '1', price: '25'));
    sales.setCartLinePrice(0, '30');
    sales.calculateGrandTotal();
    expect(sales.items.first.quantityController.text, '2');
    expect(sales.items.first.priceController.text, '100');
    expect(sales.totalCost.value, 230);
    sales.setCartLineBonus(0, true);
    expect(sales.totalCost.value, 200);
  });

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

SalesController _salesController(
    {bool editing = true, bool administrative = false}) {
  final repository = _SalesRepository();
  final sales = _TestSalesController(
    administrative: administrative,
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
  sales.activeEditInstantSaleId.value = editing ? 42 : null;
  sales.animController = AnimationController(vsync: sales);
  addTearDown(() {
    sales.clearCartLines(deferDispose: false);
    sales.onClose();
  });
  return sales;
}

class _TestSalesController extends SalesController {
  _TestSalesController({
    required this.administrative,
    required SalesService salesService,
    required AddProfitSaleUsecase addProfitSaleUsecase,
    required GetProfitSalesUsecase getProfitSalesUsecase,
    required GetInstantSalesUsecase getInstantSalesUsecase,
    required GetAllProductsUsecase getAllProductsUsecase,
    required UpdateProductRetailPriceUsecase updateProductRetailPriceUsecase,
    required AddInstantSalesUsecase addInstantSalesUsecase,
    required InvoiceModelUsecase invoiceModelUsecase,
    required GetCustomerProductPriceHistoryUsecase
        getCustomerProductPriceHistoryUsecase,
    required AllCustomersSellersUsecase allCustomersSellersUsecase,
  }) : super(
          salesService: salesService,
          addProfitSaleUsecase: addProfitSaleUsecase,
          getProfitSalesUsecase: getProfitSalesUsecase,
          getInstantSalesUsecase: getInstantSalesUsecase,
          getAllProductsUsecase: getAllProductsUsecase,
          updateProductRetailPriceUsecase: updateProductRetailPriceUsecase,
          addInstantSalesUsecase: addInstantSalesUsecase,
          invoiceModelUsecase: invoiceModelUsecase,
          getCustomerProductPriceHistoryUsecase:
              getCustomerProductPriceHistoryUsecase,
          allCustomersSellersUsecase: allCustomersSellersUsecase,
        );

  final bool administrative;

  @override
  bool get isClosedDayAdministrativeCorrection => administrative;
}

class _SalesRepository extends Fake implements SalesRepository {
  @override
  Future<List<ProductModel>> getAllProducts({
    String endPoint = '',
    String? customerId,
    String? sellerId,
    String? search,
    String? storeSectionId,
  }) async =>
      [];
}

class _ChecksRepository extends Fake implements ChecksRepository {
  @override
  Future<List<SellerModel>> allCustomersSellers(
          {required String endPoint}) async =>
      [];
}

class _DioConsumer extends Fake implements DioConsumer {}
