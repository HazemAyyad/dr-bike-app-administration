import 'package:doctorbike/core/databases/api/api_consumer.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/errors/error_model.dart';
import 'package:doctorbike/core/errors/expentions.dart';
import 'package:dio/dio.dart';

import '../models/sales_order_model.dart';

class SalesOrdersDatasource {
  SalesOrdersDatasource({required this.api});

  final ApiConsumer api;

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Response) {
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return <String, dynamic>{};
    }
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return <String, dynamic>{};
  }

  Future<List<SalesOrderListItemModel>> fetchOrders({String? status}) async {
    final raw = await api.get(
      EndPoints.salesOrders,
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    final response = _asMap(raw);
    _ensureSuccess(response);
    final list = response['sales_orders'] as List<dynamic>? ?? [];
    return list
        .map((e) => SalesOrderListItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SalesOrderDetailModel> fetchOrder(int orderId) async {
    final raw = await api.get(
      EndPoints.salesOrder,
      queryParameters: {'sales_order_id': orderId},
    );
    final response = _asMap(raw);
    _ensureSuccess(response);
    return SalesOrderDetailModel.fromJson(
      response['sales_order'] as Map<String, dynamic>,
    );
  }

  Future<SalesOrderDetailModel> createOrder(Map<String, dynamic> body) async {
    final raw = await api.post(EndPoints.salesOrder, data: body);
    final response = _asMap(raw);
    _ensureSuccess(response);
    return SalesOrderDetailModel.fromJson(
      response['sales_order'] as Map<String, dynamic>,
    );
  }

  Future<SalesOrderDetailModel> postAction(
    String endpoint,
    int orderId, {
    Map<String, dynamic>? extra,
  }) async {
    final raw = await api.post(
      endpoint,
      data: {
        'sales_order_id': orderId,
        ...?extra,
      },
    );
    final response = _asMap(raw);
    _ensureSuccess(response);
    return SalesOrderDetailModel.fromJson(
      response['sales_order'] as Map<String, dynamic>,
    );
  }

  Future<SalesOrderDetailModel> updateOrder(
    int orderId,
    Map<String, dynamic> body,
  ) async {
    final raw = await api.post(
      EndPoints.salesOrderUpdate,
      data: {
        'sales_order_id': orderId,
        ...body,
      },
    );
    final response = _asMap(raw);
    _ensureSuccess(response);
    return SalesOrderDetailModel.fromJson(
      response['sales_order'] as Map<String, dynamic>,
    );
  }

  Future<SalesOrderDetailModel> uploadMedia(
    int orderId,
    List<MultipartFile> files,
  ) async {
    final formData = <String, dynamic>{
      'sales_order_id': orderId,
    };
    for (var i = 0; i < files.length; i++) {
      formData['media[$i]'] = files[i];
    }

    final raw = await api.post(
      EndPoints.salesOrderMedia,
      data: formData,
      isFormData: true,
    );
    final response = _asMap(raw);
    _ensureSuccess(response);
    return SalesOrderDetailModel.fromJson(
      response['sales_order'] as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> fetchStatement(int orderId) async {
    final raw = await api.get(
      EndPoints.salesOrderStatement,
      queryParameters: {'sales_order_id': orderId},
    );
    final response = _asMap(raw);
    _ensureSuccess(response);
    return response['report'] as Map<String, dynamic>? ?? {};
  }

  Future<List<CityModel>> fetchCities() async {
    final raw = await api.get(EndPoints.cities);
    final response = _asMap(raw);
    _ensureSuccess(response);
    final list = response['cities'] as List<dynamic>? ?? [];
    return list
        .map((e) => CityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DeliveryCompanyModel>> fetchDeliveryCompanies() async {
    final raw = await api.get(EndPoints.deliveryCompanies);
    final response = _asMap(raw);
    _ensureSuccess(response);
    final list = response['delivery_companies'] as List<dynamic>? ?? [];
    return list
        .map((e) => DeliveryCompanyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _ensureSuccess(Map<String, dynamic> response) {
    if (response['status'] != 'success') {
      throw ServerException(
        ErrorModel(
          errorMessage: response['message']?.toString() ?? 'Error',
          status: 400,
          data: response,
        ),
      );
    }
  }
}
