import 'package:dio/dio.dart';
import 'package:doctorbike/core/databases/api/api_consumer.dart';
import 'package:doctorbike/features/admin/sales/data/datasources/sales_datasources.dart';
import 'package:doctorbike/features/admin/sales/data/models/invoice_model.dart';
import 'package:doctorbike/features/admin/sales/presentation/models/instant_sale_cart_line.dart';
import 'package:doctorbike/features/admin/sales/presentation/controllers/sales_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

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
      data: {'success': true},
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('sale creation sends canonical prices, discounts and payments',
      () async {
    final api = _RecordingApi();
    final datasource = SalesDatasource(api: api);
    await datasource.addInstantSales(
      productId: '1',
      quantity: '2',
      cost: '١٢٫٥',
      discount: '٠،٧٥',
      totalCost: '٢٤٫٢٥',
      note: '',
      type: 'normal',
      projectId: '',
      otherProducts: <ItemModel>[].obs,
      buyerType: 'unknown',
      paymentBoxValue: '١٠،٥',
      additionalNotes: [
        {'text': 'عمل', 'amount': '١،٥'}
      ],
      cartOtherProducts: [
        {'product_id': '1', 'quantity': '2', 'cost': '١٢٫٥'},
        {'product_id': '2', 'quantity': '1', 'cost': '٣،٢٥'},
      ],
    );
    expect(api.sent['cost'], '12.5');
    expect(api.sent['discount'], '0.75');
    expect(api.sent['total_cost'], '24.25');
    expect(api.sent['payment_box_value'], '10.5');
    expect(api.sent['other_products[0][cost]'], '3.25');
    expect(api.sent['additional_notes[0][amount]'], '1.5');
    expect(api.sent['quantity'], '2');
  });

  test('a paid line and bonus line keep distinct prices and flags', () async {
    final api = _RecordingApi();
    final datasource = SalesDatasource(api: api);
    final line = InstantSaleCartLine(
      productId: '1',
      productName: 'Helmet',
      imageUrl: '',
      stock: 10,
      initialPrice: '50',
      isBonus: true,
    );
    addTearDown(line.dispose);
    expect(line.lineTotal.value, 0);
    expect(line.priceText, '0');

    await datasource.addInstantSales(
      productId: '1',
      quantity: '2',
      cost: '50',
      discount: '0',
      totalCost: '100',
      note: '',
      type: 'normal',
      projectId: '',
      otherProducts: <ItemModel>[].obs,
      buyerType: 'unknown',
      cartOtherProducts: [
        {'product_id': '1', 'quantity': '2', 'cost': '50'},
        {
          'product_id': line.productId,
          'quantity': line.quantityText,
          'cost': line.priceText,
          'is_bonus': line.isBonus,
        },
      ],
    );

    expect(api.sent['is_bonus'], '0');
    expect(api.sent['cost'], '50.0');
    expect(api.sent['other_products[0][is_bonus]'], '1');
    expect(api.sent['other_products[0][cost]'], '0.0');

    final invoice = InvoiceModel.fromJson({
      'cost': '0',
      'is_bonus': true,
      'subtotal': '0',
      'sub_products': [
        {'cost': '50', 'quantity': '2'},
        {'cost': '0', 'is_bonus': true},
        {'cost': '0'},
      ],
    });
    expect(invoice.isBonus, isTrue);
    expect(invoice.subProducts.map((item) => item.isBonus), [false, true, false]);
    expect(invoice.productsSubtotal, 100);
  });

  test('sale edits and profit sales keep decimal commas in API values',
      () async {
    final api = _RecordingApi();
    final datasource = SalesDatasource(api: api);
    await datasource.editInstantSale(
      instantSaleId: '1',
      cost: '12,5',
      quantity: '2',
      totalCost: '25,0',
      paymentBoxValue: '10,5',
    );
    expect(api.sent['cost'], '12.5');
    expect(api.sent['total_cost'], '25.0');
    expect(api.sent['payment_box_value'], '10.5');
    await datasource.addProfitSales(
      notes: '',
      totalCost: '١٢٫٥',
      paymentBoxValue: '١٠،٥',
    );
    expect(api.sent['total_cost'], '12.5');
    expect(api.sent['payment_box_value'], '10.5');
  });
}
