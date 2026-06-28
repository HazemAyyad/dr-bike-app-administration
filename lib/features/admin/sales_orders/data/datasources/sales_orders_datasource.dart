import 'package:doctorbike/core/databases/api/api_consumer.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/errors/error_model.dart';
import 'package:doctorbike/core/errors/expentions.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../checks/data/models/check_model.dart';
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

  Future<SalesOrderStockCheckResult> checkStock({
    required List<Map<String, dynamic>> items,
    int? salesOrderId,
  }) async {
    final raw = await api.post(
      EndPoints.salesOrderCheckStock,
      data: {
        'items': items,
        if (salesOrderId != null) 'sales_order_id': salesOrderId,
      },
    );
    final response = _asMap(raw);
    _ensureSuccess(response);
    return SalesOrderStockCheckResult.fromJson(response);
  }

  Future<List<ProductStockAvailabilityModel>> fetchStockAvailability({
    required List<int> productIds,
    int? salesOrderId,
  }) async {
    final raw = await api.post(
      EndPoints.salesOrderStockAvailability,
      data: {
        'product_ids': productIds,
        if (salesOrderId != null) 'sales_order_id': salesOrderId,
      },
    );
    final response = _asMap(raw);
    _ensureSuccess(response);
    final list = response['availability'] as List<dynamic>? ?? [];
    return list
        .map((e) => ProductStockAvailabilityModel.fromJson(
              e as Map<String, dynamic>,
            ))
        .toList();
  }

  Future<SalesOrderDetailModel> postAction(
    String endpoint,
    int orderId, {
    Map<String, dynamic>? extra,
  }) async {
    final payload = <String, dynamic>{
      'sales_order_id': orderId,
      ...?extra,
    };
    final isHandover = endpoint == EndPoints.salesOrderHandover;
    if (isHandover) {
      debugPrint('[SHIPLY-HANDOVER] → POST $endpoint');
      debugPrint('[SHIPLY-HANDOVER]   body=$payload');
    }
    try {
      final raw = await api.post(endpoint, data: payload);
      final response = _asMap(raw);
      if (isHandover) {
        debugPrint('[SHIPLY-HANDOVER] ← status=${response['status']} '
            'message=${response['message']}');
        debugPrint('[SHIPLY-HANDOVER]   raw=$response');
      }
      _ensureSuccess(response);
      return SalesOrderDetailModel.fromJson(
        response['sales_order'] as Map<String, dynamic>,
      );
    } on ServerException catch (e) {
      if (isHandover) {
        debugPrint('[SHIPLY-HANDOVER] ✗ FAILED');
        debugPrint('[SHIPLY-HANDOVER]   message=${e.errorModel.errorMessage}');
        debugPrint('[SHIPLY-HANDOVER]   status=${e.errorModel.status}');
        debugPrint('[SHIPLY-HANDOVER]   data=${e.errorModel.data}');
      }
      rethrow;
    } catch (e) {
      if (isHandover) {
        debugPrint('[SHIPLY-HANDOVER] ✗ UNEXPECTED ERROR: $e');
      }
      rethrow;
    }
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
    List<MultipartFile> files, {
    String? category,
  }) async {
    final formData = FormData();
    formData.fields.add(MapEntry('sales_order_id', orderId.toString()));
    if (category != null && category.isNotEmpty) {
      formData.fields.add(MapEntry('category', category));
    }
    for (final file in files) {
      formData.files.add(MapEntry('media[]', file));
    }

    final raw = await api.post(
      EndPoints.salesOrderMedia,
      data: formData,
      isFormData: false,
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

  Future<ShiplyAddressOptionsResult> fetchShiplyAddressOptions() async {
    final raw = await api.get(EndPoints.shiplyAddressOptions);
    final response = _asMap(raw);
    _ensureSuccess(response);
    final list = response['cities'] as List<dynamic>? ?? [];
    final mode = response['shiply_mode']?.toString().toLowerCase();
    return ShiplyAddressOptionsResult(
      cities: list
          .map((e) => ShiplyCityModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isTestMode: mode != 'live',
    );
  }

  Future<double?> fetchShiplyDeliveryFee({
    required int villageId,
    double price = 0,
  }) async {
    final raw = await api.post(
      EndPoints.shiplyCalculateDeliveryFee,
      data: {
        'village_id': villageId,
        if (price > 0) 'price': price,
      },
    );
    final response = _asMap(raw);
    _ensureSuccess(response);
    final fees = response['fees'] as Map<String, dynamic>?;
    return (fees?['delivery_cost'] as num?)?.toDouble();
  }

  Future<List<SellerModel>> fetchCustomersList() async {
    final raw = await api.get(EndPoints.all_customers);
    final response = _asMap(raw);
    _ensureSuccess(response);
    final list = response['all_customers'] as List<dynamic>? ?? [];
    return list
        .map((e) => SellerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SellerModel>> fetchSellersList() async {
    final raw = await api.get(EndPoints.all_sellers);
    final response = _asMap(raw);
    _ensureSuccess(response);
    final list = response['all_sellers'] as List<dynamic>? ?? [];
    return list
        .map((e) => SellerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SellerModel> createPersonQuick({
    required String personType,
    required String name,
    required String phone,
  }) async {
    final raw = await api.post(
      EndPoints.createPerson,
      data: {
        'person_type': personType,
        'name': name,
        if (phone.isNotEmpty) 'phone': phone,
        'type': personType == 'customer' ? 'retail' : 'wholesale',
      },
    );
    final response = _asMap(raw);
    _ensureSuccess(response);
    final id = personType == 'customer'
        ? response['customer_id']
        : response['seller_id'];
    return SellerModel(
      id: int.parse(id.toString()),
      name: name,
      phone: phone,
    );
  }

  Future<void> updatePersonPhone({
    required bool isCustomer,
    required int personId,
    required String name,
    required String phone,
  }) async {
    final raw = await api.post(
      EndPoints.editPerson,
      data: {
        if (isCustomer) 'customer_id': personId,
        if (!isCustomer) 'seller_id': personId,
        'name': name,
        'phone': phone,
        'type': isCustomer ? 'retail' : 'wholesale',
      },
    );
    final response = _asMap(raw);
    _ensureSuccess(response);
  }

  Future<Map<String, dynamic>> bulkStatus({
    required List<int> orderIds,
    required String action,
  }) async {
    final raw = await api.post(
      EndPoints.salesOrdersBulkStatus,
      data: {
        'order_ids': orderIds,
        'action': action,
      },
    );
    final response = _asMap(raw);
    _ensureSuccess(response);
    return response;
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
