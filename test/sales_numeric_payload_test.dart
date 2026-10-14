import 'package:dio/dio.dart';
import 'package:doctorbike/core/databases/api/api_consumer.dart';
import 'package:doctorbike/features/admin/sales/data/datasources/sales_datasources.dart';
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
