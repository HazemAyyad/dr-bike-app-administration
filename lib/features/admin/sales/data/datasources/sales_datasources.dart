import 'dart:core';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:doctorbike/features/admin/sales/data/models/instant_sales_model.dart';
import 'package:doctorbike/features/admin/sales/data/models/product_price_update_result.dart';
import 'package:doctorbike/features/admin/sales/data/models/profit_sale_model.dart';
import 'package:doctorbike/features/admin/sales/data/models/suspended_instant_sale_model.dart';
import 'package:doctorbike/features/admin/sales/presentation/controllers/sales_controller.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/helpers/json_safe_parser.dart';
import '../../../stock/data/models/offer_package_model.dart';
import '../models/customer_product_price_history_model.dart';
import '../models/daily_session_model.dart';
import '../models/invoice_model.dart';
import '../models/product_model.dart';

class SalesDatasource {
  final ApiConsumer api;

  SalesDatasource({required this.api});

  void _instantSaleDebug(String message, [Object? details]) {
    if (!kDebugMode) return;
    debugPrint(
      details == null
          ? '[InstantSaleDebug][Datasource] $message'
          : '[InstantSaleDebug][Datasource] $message | $details',
    );
  }

  void _instantSaleDioError(String scope, DioException e) {
    if (!kDebugMode) return;
    debugPrint('[InstantSaleDebug][Datasource] $scope DioException');
    debugPrint('[InstantSaleDebug][Datasource] uri=${e.requestOptions.uri}');
    debugPrint(
        '[InstantSaleDebug][Datasource] method=${e.requestOptions.method}');
    debugPrint(
        '[InstantSaleDebug][Datasource] requestData=${e.requestOptions.data}');
    debugPrint(
        '[InstantSaleDebug][Datasource] status=${e.response?.statusCode}');
    debugPrint('[InstantSaleDebug][Datasource] response=${e.response?.data}');
    debugPrint('[InstantSaleDebug][Datasource] message=${e.message}');
  }

  void _instantSaleEditZeroDebug(String message, [Object? details]) {
    if (!kDebugMode) return;
    debugPrint(
      details == null
          ? '[InstantSaleEditZeroDebug][Datasource] $message'
          : '[InstantSaleEditZeroDebug][Datasource] $message | $details',
    );
  }

  String _cleanAmount(String value) {
    const eastern = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
      '۰': '0',
      '۱': '1',
      '۲': '2',
      '۳': '3',
      '۴': '4',
      '۵': '5',
      '۶': '6',
      '۷': '7',
      '۸': '8',
      '۹': '9',
    };
    var text = value.trim().replaceAll(',', '').replaceAll('،', '');
    eastern.forEach((from, to) {
      text = text.replaceAll(from, to);
    });
    return text;
  }

  // add profit sale
  Future<dynamic> addProfitSales({
    required String notes,
    required String totalCost,
    String? buyerType,
    String? buyerId,
    String? sellerId,
    String? buyerName,
    String? paymentBoxId,
    String? paymentBoxName,
    String? paymentBoxValue,
    XFile? image,
    XFile? video,
  }) async {
    try {
      final response = await api.post(
        EndPoints.createProfitSale,
        data: {
          'notes': notes,
          'total_cost': _cleanAmount(totalCost),
          if (buyerType != null && buyerType.isNotEmpty)
            'buyer_type': buyerType,
          if (buyerId != null && buyerId.isNotEmpty) 'buyer_id': buyerId,
          if (sellerId != null && sellerId.isNotEmpty) 'seller_id': sellerId,
          if (buyerName != null && buyerName.isNotEmpty)
            'buyer_name': buyerName,
          if (paymentBoxId != null && paymentBoxId.isNotEmpty)
            'payment_box_id': paymentBoxId,
          if (paymentBoxName != null && paymentBoxName.isNotEmpty)
            'payment_box_name': paymentBoxName,
          if (paymentBoxValue != null && paymentBoxValue.isNotEmpty)
            'payment_box_value': _cleanAmount(paymentBoxValue),
          if (image != null)
            'image': await MultipartFile.fromFile(
              image.path,
              filename: image.path.split('/').last,
            ),
          if (video != null)
            'video': await MultipartFile.fromFile(
              video.path,
              filename: video.path.split('/').last,
            ),
        },
        isFormData: true,
      );
      return response.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['errors'] ?? {},
        ),
      );
    }
  }

  // get profit sales
  Future<List<ProfitSale>> getProfitSales() async {
    try {
      final response = await api.get(EndPoints.allProfitSales);
      return mapListFromResponseKey(
        response.data,
        'profit_sales',
        (Map<String, dynamic> m) => ProfitSale.fromJson(m),
        debugScope: 'SalesDatasource.getProfitSales',
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }

  // get instant sales
  Future<List<InstantSalesModel>> getInstantSales({
    String? search,
    String sortDirection = 'desc',
  }) async {
    try {
      final query = <String, dynamic>{
        'sort_direction': sortDirection,
      };
      final trimmed = search?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        query['search'] = trimmed;
      }
      final response = await api.get(
        EndPoints.allInstantSales,
        queryParameters: query,
      );
      return mapListFromResponseKey(
        response.data,
        'instant_sales',
        (Map<String, dynamic> m) => InstantSalesModel.fromJson(m),
        debugScope: 'SalesDatasource.getInstantSales',
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }

  // get all products
  Future<List<ProductModel>> getAllProducts({
    required String endPoint,
    String? customerId,
    String? sellerId,
    String? search,
    String? storeSectionId,
  }) async {
    try {
      final response = await api.get(
        endPoint.isNotEmpty ? endPoint : EndPoints.allProducts,
        queryParameters: {
          if (customerId != null && customerId.isNotEmpty)
            'customer_id': customerId,
          if (sellerId != null && sellerId.isNotEmpty) 'seller_id': sellerId,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (storeSectionId != null && storeSectionId.isNotEmpty)
            'store_section_id': storeSectionId,
        },
      );
      final listKey = endPoint == 'get/all/categories'
          ? 'categories'
          : endPoint == 'get/all/subcategories'
              ? 'sub_categories'
              : 'products';
      if (kDebugMode) {
        final rows = extractMapListFromResponse(response.data, listKey);
        if (rows.isNotEmpty) {
          debugParseLog(
            'SalesDatasource.getAllProducts',
            'listKey=$listKey sample=${rows.first}',
          );
        }
      }
      return mapListFromResponseKey(
        response.data,
        listKey,
        (Map<String, dynamic> m) => ProductModel.fromJson(m),
        debugScope: 'SalesDatasource.getAllProducts',
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }

  Future<List<OfferPackageModel>> getOfferPackagesForSale() async {
    try {
      final response = await api.get(EndPoints.offerPackagesForSale);
      return mapListFromResponseKey(
        response.data,
        'packages',
        (Map<String, dynamic> m) => OfferPackageModel.fromJson(m),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  Future<ProductPriceUpdateResult> updateProductRetailPrice({
    required String productId,
    required double normailPrice,
    double? wholesalePrice,
  }) async {
    try {
      final payload = <String, dynamic>{
        'product_id': int.tryParse(productId) ?? productId,
        'normail_price': normailPrice,
      };
      if (wholesalePrice != null && wholesalePrice > 0) {
        payload['wholesale_price'] = wholesalePrice;
      }
      final response = await api.post(
        EndPoints.updateProductRetailPrice,
        data: payload,
      );
      final data = response.data;
      if (data is Map && data['status'] == 'success') {
        return ProductPriceUpdateResult(
          retail: asDouble(data['normail_price'] ?? normailPrice),
          wholesale: asDouble(data['wholesale_price'] ?? wholesalePrice ?? 0),
        );
      }
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message']?.toString() ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message']?.toString() ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    }
  }

  Future<CustomerProductPriceHistory> getCustomerProductPriceHistory({
    String? personType,
    String? personId,
    required String productId,
    String? sizeColorId,
    int limit = 5,
  }) async {
    try {
      final query = <String, dynamic>{
        'product_id': int.tryParse(productId) ?? productId,
        'limit': limit,
      };
      if (personType != null &&
          personType.isNotEmpty &&
          personId != null &&
          personId.isNotEmpty) {
        query['person_type'] = personType;
        query['person_id'] = int.tryParse(personId) ?? personId;
      }
      if (sizeColorId != null && sizeColorId.isNotEmpty) {
        query['size_color_id'] = int.tryParse(sizeColorId) ?? sizeColorId;
      }
      final response = await api.get(
        EndPoints.instantSaleCustomerProductPrices,
        queryParameters: query,
      );
      final data = response.data;
      if (data is Map && data['status'] == 'success') {
        return CustomerProductPriceHistory.fromJson(
          Map<String, dynamic>.from(data),
        );
      }
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message']?.toString() ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message']?.toString() ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    }
  }

  // add instant sale
  Future<dynamic> addInstantSales({
    required String productId,
    required String quantity,
    required String cost,
    required String discount,
    required String totalCost,
    required String note,
    List<Map<String, dynamic>> additionalNotes = const [],
    required String type,
    required String projectId,
    required RxList<ItemModel> otherProducts,
    required String buyerType,
    String? buyerId,
    String? sellerId,
    String? buyerName,
    String? paymentBoxId,
    String? paymentBoxName,
    String? paymentBoxValue,
    String? offerPackageId,
    List<Map<String, dynamic>>? cartOtherProducts,
    String? instantSaleId,
  }) async {
    try {
      String resolvedProductId = productId;
      String resolvedQuantity = quantity;
      String resolvedCost = cost;
      String? resolvedSizeColorId;
      String? resolvedSizeId;

      late final List<Map<String, dynamic>> otherProductsList;

      if (offerPackageId != null && offerPackageId.isNotEmpty) {
        otherProductsList = cartOtherProducts ?? <Map<String, dynamic>>[];
      } else if (cartOtherProducts != null && cartOtherProducts.isNotEmpty) {
        final main = cartOtherProducts.first;
        resolvedProductId = main['product_id']?.toString() ?? productId;
        resolvedQuantity = main['quantity']?.toString() ?? quantity;
        resolvedCost = main['cost']?.toString() ?? cost;
        resolvedSizeColorId = main['size_color_id']?.toString();
        resolvedSizeId = main['size_id']?.toString();
        otherProductsList = cartOtherProducts.length > 1
            ? cartOtherProducts.skip(1).toList()
            : <Map<String, dynamic>>[];
      } else {
        otherProductsList = otherProducts
            .skip(1)
            .map((item) => {
                  'product_id': item.selectedItem.value,
                  'cost': item.priceController.text,
                  'quantity': item.quantityController.text,
                  'type': item.selectedCustomersSellers.value
                      ? 'project'
                      : 'normal',
                })
            .toList();
      }
      final additionalNotesMap = <String, dynamic>{};
      for (var i = 0; i < additionalNotes.length; i++) {
        final note = additionalNotes[i];
        additionalNotesMap['additional_notes[$i][text]'] =
            note['text']?.toString() ?? '';
        additionalNotesMap['additional_notes[$i][amount]'] =
            note['amount']?.toString() ?? '0';
      }

      final otherProductsMap = <String, dynamic>{};
      for (var i = 0; i < otherProductsList.length; i++) {
        final row = otherProductsList[i];
        otherProductsMap['other_products[$i][product_id]'] =
            row['product_id']?.toString() ?? '';
        otherProductsMap['other_products[$i][cost]'] =
            row['cost']?.toString() ?? '0';
        otherProductsMap['other_products[$i][quantity]'] =
            row['quantity']?.toString() ?? '1';
        otherProductsMap['other_products[$i][type]'] =
            row['type']?.toString() ?? 'normal';
        if (row['project_id'] != null &&
            row['project_id'].toString().isNotEmpty) {
          otherProductsMap['other_products[$i][project_id]'] =
              row['project_id'].toString();
        }
        if (row['size_color_id'] != null &&
            row['size_color_id'].toString().isNotEmpty) {
          otherProductsMap['other_products[$i][size_color_id]'] =
              row['size_color_id'].toString();
        }
        if (row['size_id'] != null && row['size_id'].toString().isNotEmpty) {
          otherProductsMap['other_products[$i][size_id]'] =
              row['size_id'].toString();
        }
      }

      final endpoint = instantSaleId != null && instantSaleId.isNotEmpty
          ? EndPoints.editInstantSale
          : EndPoints.createInstantSale;
      final isEdit = instantSaleId != null && instantSaleId.isNotEmpty;
      final data = {
        if (instantSaleId != null && instantSaleId.isNotEmpty)
          'instant_sale_id': instantSaleId,
        if (offerPackageId != null && offerPackageId.isNotEmpty)
          'offer_package_id': offerPackageId
        else
          'product_id': resolvedProductId,
        'quantity': resolvedQuantity,
        'cost': resolvedCost,
        if (resolvedSizeColorId != null && resolvedSizeColorId.isNotEmpty)
          'size_color_id': resolvedSizeColorId,
        if (resolvedSizeId != null && resolvedSizeId.isNotEmpty)
          'size_id': resolvedSizeId,
        'discount': discount,
        'total_cost': totalCost,
        'notes': note,
        ...additionalNotesMap,
        'type': type,
        if (projectId.isNotEmpty) 'project_id': projectId,
        'buyer_type': buyerType,
        if (buyerId != null && buyerId.isNotEmpty) 'buyer_id': buyerId,
        if (sellerId != null && sellerId.isNotEmpty) 'seller_id': sellerId,
        if (buyerName != null && buyerName.isNotEmpty) 'buyer_name': buyerName,
        if (paymentBoxId != null && paymentBoxId.isNotEmpty)
          'payment_box_id': paymentBoxId,
        if (paymentBoxName != null && paymentBoxName.isNotEmpty)
          'payment_box_name': paymentBoxName,
        if (paymentBoxId != null && paymentBoxId.isNotEmpty)
          'payment_box_value': paymentBoxValue ?? '0',
        ...otherProductsMap,
      };
      if (isEdit) {
        _instantSaleEditZeroDebug('POST edit instant sale payload', {
          'endpoint': endpoint,
          'instantSaleId': instantSaleId,
          'paymentBoxId': paymentBoxId,
          'paymentBoxName': paymentBoxName,
          'paymentBoxValueArg': paymentBoxValue,
          'paymentBoxValueSent': data['payment_box_value'],
          'totalCost': totalCost,
          'quantity': resolvedQuantity,
          'cost': resolvedCost,
          'data': data,
        });
      }
      _instantSaleDebug('POST addInstantSales', {
        'endpoint': endpoint,
        'mode': isEdit ? 'edit' : 'create',
        'data': data,
        'otherProductsCount': otherProductsList.length,
        'additionalNotesCount': additionalNotes.length,
      });
      final response = await api.post(
        endpoint,
        data: data,
        isFormData: true,
      );
      if (isEdit) {
        _instantSaleEditZeroDebug('edit instant sale response', response.data);
      }
      _instantSaleDebug('addInstantSales response', response.data);
      return response.data;
    } on DioException catch (e) {
      _instantSaleEditZeroDebug('addInstantSales DioException', {
        'message': e.message,
        'requestData': e.requestOptions.data,
        'status': e.response?.statusCode,
        'response': e.response?.data,
      });
      _instantSaleDioError('addInstantSales', e);
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message']?.toString() ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? data : {},
        ),
      );
    }
  }

  Future<dynamic> cancelInstantSale({required String instantSaleId}) async {
    try {
      final response = await api.post(
        EndPoints.cancelInstantSale,
        data: {'instant_sale_id': instantSaleId},
      );
      return response.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data ?? {},
        ),
      );
    }
  }

  Future<dynamic> cancelProfitSale({required String profitSaleId}) async {
    try {
      final response = await api.post(
        EndPoints.cancelProfitSale,
        data: {'profit_sale_id': profitSaleId},
      );
      return response.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data ?? {},
        ),
      );
    }
  }

  Future<dynamic> editInstantSale({
    required String instantSaleId,
    required String cost,
    required String quantity,
    required String totalCost,
    String? notes,
    String? paymentBoxValue,
  }) async {
    try {
      final response = await api.post(
        EndPoints.editInstantSale,
        data: {
          'instant_sale_id': instantSaleId,
          'cost': cost,
          'quantity': quantity,
          'total_cost': totalCost,
          if (notes != null) 'notes': notes,
          if (paymentBoxValue != null)
            'payment_box_value':
                paymentBoxValue.replaceAll(',', '').replaceAll('،', '').trim(),
        },
      );
      return response.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data ?? {},
        ),
      );
    }
  }

  Future<DailySessionPayload> getDailySessionCurrent() async {
    final response = await api.get(EndPoints.salesDailySessionCurrent);
    final raw = response.data['daily_session'];
    if (raw is! Map) {
      return const DailySessionPayload();
    }
    return DailySessionPayload.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<String> openDailySession({
    List<Map<String, dynamic>> openingCounts = const [],
    bool confirmOpeningVariance = false,
  }) async {
    final response = await api.post(
      EndPoints.salesDailySessionOpen,
      data: {
        'opening_counts': openingCounts,
        'confirm_opening_variance': confirmOpeningVariance,
      },
    );
    return _messageFromResponse(response.data);
  }

  Future<List<DailySessionSummaryModel>> getOpenDailySessions() async {
    final response = await api.get(EndPoints.salesDailySessionsOpen);
    return mapListFromResponseKey(
      response.data,
      'sessions',
      (Map<String, dynamic> m) => DailySessionSummaryModel.fromJson(m),
    );
  }

  Future<DailyTodayOverviewModel> getDailySessionsTodayOverview() async {
    final response = await api.get(EndPoints.salesDailySessionsTodayOverview);
    final raw = response.data['overview'];
    if (raw is! Map) {
      return const DailyTodayOverviewModel(businessDate: '');
    }
    return DailyTodayOverviewModel.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<List<DailySessionSummaryModel>> getDailySessionsHistory({
    String? fromDate,
    String? toDate,
    String? status,
    int page = 1,
  }) async {
    final response = await api.get(
      EndPoints.salesDailySessions,
      queryParameters: {
        if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
        if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
        'per_page': 30,
      },
    );
    return mapListFromResponseKey(
      response.data,
      'sessions',
      (Map<String, dynamic> m) => DailySessionSummaryModel.fromJson(m),
    );
  }

  Future<DailySessionDetailModel> getDailySessionDetail(int sessionId) async {
    final response =
        await api.get(EndPoints.salesDailySessionDetail(sessionId));
    final raw = response.data['session_detail'];
    if (raw is! Map) {
      throw ServerException(
        ErrorModel(
          errorMessage: 'Invalid session detail response',
          status: 500,
          data: const {},
        ),
      );
    }
    return DailySessionDetailModel.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<DailySessionPayload> getDailySessionClosePayload(int sessionId) async {
    final response = await api.get(
      EndPoints.salesDailySessionClosePayload(sessionId),
    );
    final raw = response.data['daily_session'];
    if (raw is! Map) {
      throw ServerException(
        ErrorModel(
          errorMessage: 'Invalid close payload response',
          status: 500,
          data: const {},
        ),
      );
    }
    return DailySessionPayload.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<String> requestDailyClosing({
    required List<Map<String, dynamic>> cashCounts,
    String? lateCloseReason,
    int? sessionId,
    List<Map<String, dynamic>>? transfers,
    String? reviewNotes,
  }) async {
    final response = await api.post(
      EndPoints.salesDailyClosingRequest,
      data: {
        'cash_counts': cashCounts,
        if (lateCloseReason != null && lateCloseReason.trim().isNotEmpty)
          'late_close_reason': lateCloseReason.trim(),
        if (sessionId != null) 'session_id': sessionId,
        if (transfers != null) 'transfers': transfers,
        if (reviewNotes != null && reviewNotes.trim().isNotEmpty)
          'review_notes': reviewNotes.trim(),
      },
    );
    return _messageFromResponse(response.data);
  }

  Future<String> directCloseDailySession({
    required List<Map<String, dynamic>> cashCounts,
    required int sessionId,
    List<Map<String, dynamic>> transfers = const [],
    String? reviewNotes,
  }) async {
    final response = await api.post(
      EndPoints.salesDailyClosingDirect,
      data: {
        'cash_counts': cashCounts,
        'session_id': sessionId,
        'transfers': transfers,
        if (reviewNotes != null && reviewNotes.trim().isNotEmpty)
          'review_notes': reviewNotes.trim(),
      },
    );
    return _messageFromResponse(response.data);
  }

  Future<List<DailyClosingRequestModel>> getPendingDailyClosing() async {
    final response = await api.get(EndPoints.salesDailyClosingPending);
    return mapListFromResponseKey(
      response.data,
      'closing_requests',
      (Map<String, dynamic> m) => DailyClosingRequestModel.fromJson(m),
    );
  }

  Future<String> approveDailyClosing({
    required int closingRequestId,
    required List<Map<String, dynamic>> transfers,
    String? reviewNotes,
  }) async {
    final response = await api.post(
      EndPoints.salesDailyClosingApprove,
      data: {
        'closing_request_id': closingRequestId,
        'transfers': transfers,
        if (reviewNotes != null && reviewNotes.trim().isNotEmpty)
          'review_notes': reviewNotes.trim(),
      },
    );
    return _messageFromResponse(response.data);
  }

  Future<String> rejectDailyClosing({
    required int closingRequestId,
    String? reviewNotes,
  }) async {
    final response = await api.post(
      EndPoints.salesDailyClosingReject,
      data: {
        'closing_request_id': closingRequestId,
        if (reviewNotes != null && reviewNotes.trim().isNotEmpty)
          'review_notes': reviewNotes.trim(),
      },
    );
    return _messageFromResponse(response.data);
  }

  Future<String> requestDailyReopen({required String reason}) async {
    final response = await api.post(
      EndPoints.salesDailyReopenRequest,
      data: {'reason': reason.trim()},
    );
    return _messageFromResponse(response.data);
  }

  Future<List<DailyReopenRequestModel>> getPendingDailyReopen() async {
    final response = await api.get(EndPoints.salesDailyReopenPending);
    return mapListFromResponseKey(
      response.data,
      'reopen_requests',
      (Map<String, dynamic> m) => DailyReopenRequestModel.fromJson(m),
    );
  }

  Future<String> approveDailyReopen({
    required int reopenRequestId,
    String? reviewNotes,
  }) async {
    final response = await api.post(
      EndPoints.salesDailyReopenApprove,
      data: {
        'reopen_request_id': reopenRequestId,
        if (reviewNotes != null && reviewNotes.trim().isNotEmpty)
          'review_notes': reviewNotes.trim(),
      },
    );
    return _messageFromResponse(response.data);
  }

  Future<String> rejectDailyReopen({
    required int reopenRequestId,
    String? reviewNotes,
  }) async {
    final response = await api.post(
      EndPoints.salesDailyReopenReject,
      data: {
        'reopen_request_id': reopenRequestId,
        if (reviewNotes != null && reviewNotes.trim().isNotEmpty)
          'review_notes': reviewNotes.trim(),
      },
    );
    return _messageFromResponse(response.data);
  }

  String _messageFromResponse(dynamic data) {
    if (data is! Map) {
      return 'OK';
    }
    final map = Map<String, dynamic>.from(data);
    if (map['status'] == 'error') {
      final validation = _validationMessage(map);
      throw ServerException(
        ErrorModel(
          errorMessage: validation.isNotEmpty
              ? validation
              : asString(map['message'], 'Unknown error'),
          status: 500,
          data: map,
        ),
      );
    }
    return asString(map['message'], 'OK');
  }

  String _validationMessage(Map<String, dynamic> map) {
    final raw = map['errors'];
    if (raw is! Map) return '';
    final parts = <String>[];
    raw.forEach((key, value) {
      if (value is List) {
        for (final item in value) {
          final text = '$item'.trim();
          if (text.isNotEmpty) parts.add(text);
        }
      } else {
        final text = '$value'.trim();
        if (text.isNotEmpty) parts.add(text);
      }
    });
    return parts.join('\n');
  }

  Future<void> requestSalesCancellation({
    required String saleType,
    required String saleId,
    required String reason,
  }) async {
    await api.post(
      EndPoints.salesCancellationRequest,
      data: {
        'sale_type': saleType,
        'sale_id': saleId,
        'reason': reason,
      },
    );
  }

  Future<List<SalesCancellationRequestModel>> getPendingCancellations() async {
    final response = await api.get(EndPoints.salesCancellationPending);
    return mapListFromResponseKey(
      response.data,
      'cancellation_requests',
      (Map<String, dynamic> m) => SalesCancellationRequestModel.fromJson(m),
    );
  }

  Future<void> approveSalesCancellation(int requestId, {String? notes}) async {
    await api.post(
      EndPoints.salesCancellationApprove,
      data: {
        'cancellation_request_id': requestId,
        if (notes != null && notes.trim().isNotEmpty) 'review_notes': notes,
      },
    );
  }

  Future<void> rejectSalesCancellation(int requestId, {String? notes}) async {
    await api.post(
      EndPoints.salesCancellationReject,
      data: {
        'cancellation_request_id': requestId,
        if (notes != null && notes.trim().isNotEmpty) 'review_notes': notes,
      },
    );
  }

  // get Invoice
  Future<InvoiceModel> getInvoice({required String invoiceId}) async {
    try {
      final parsedId = int.tryParse(invoiceId.trim());
      final response = await api.post(
        EndPoints.getInstantSaleInvoice,
        data: {
          'instant_sale_id': parsedId ?? invoiceId.trim(),
        },
      );
      final body = response.data;
      assert(() {
        // ignore: avoid_print
        print('[InvoiceDetails] $body');
        return true;
      }());

      if (body is! Map) {
        throw ServerException(
          ErrorModel(
            errorMessage: 'Invalid response',
            status: 500,
            data: {},
          ),
        );
      }

      final map = Map<String, dynamic>.from(body);
      if (map['status']?.toString() == 'error') {
        throw ServerException(
          ErrorModel(
            errorMessage: map['message']?.toString() ?? 'Unknown error',
            status: 500,
            data: map,
          ),
        );
      }

      final raw = map['instant_sale_invoice'];
      if (raw == null) {
        throw ServerException(
          ErrorModel(
            errorMessage: map['message']?.toString() ?? 'Unknown error',
            status: 500,
            data: map,
          ),
        );
      }

      try {
        final invoiceMap = raw is Map<String, dynamic>
            ? raw
            : Map<String, dynamic>.from(raw as Map);
        return InvoiceModel.fromJson(invoiceMap);
      } catch (e, st) {
        assert(() {
          // ignore: avoid_print
          print('[InvoiceDetails] parse error: $e\n$st');
          return true;
        }());
        throw ServerException(
          ErrorModel(
            errorMessage: 'Invalid invoice data',
            status: 500,
            data: {'parse_error': e.toString()},
          ),
        );
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }

  Future<List<SuspendedInstantSaleModel>> getSuspendedInstantSales({
    String? search,
    int? createdByUserId,
  }) async {
    try {
      _instantSaleDebug('GET suspended list', {
        'endpoint': EndPoints.suspendedInstantSales,
        'search': search,
        'createdByUserId': createdByUserId,
      });
      final response = await api.get(
        EndPoints.suspendedInstantSales,
        queryParameters: {
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (createdByUserId != null) 'created_by_user_id': createdByUserId,
        },
      );
      _instantSaleDebug('suspended list response', response.data);
      final raw = response.data['suspended_instant_sales'];
      if (raw is! List) return [];
      return raw
          .map((e) => SuspendedInstantSaleModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    } on DioException catch (e) {
      _instantSaleDioError('getSuspendedInstantSales', e);
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data?['message'] ?? 'Unknown error',
          status: data?['status'] ?? 500,
          data: data ?? {},
        ),
      );
    }
  }

  Future<int> getSuspendedInstantSalesCount() async {
    try {
      _instantSaleDebug(
          'GET suspended count', EndPoints.suspendedInstantSalesCount);
      final response = await api.get(EndPoints.suspendedInstantSalesCount);
      _instantSaleDebug('suspended count response', response.data);
      return asInt(response.data['suspended_count']);
    } on DioException catch (e) {
      _instantSaleDioError('getSuspendedInstantSalesCount', e);
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data?['message'] ?? 'Unknown error',
          status: data?['status'] ?? 500,
          data: data ?? {},
        ),
      );
    }
  }

  Future<SuspendedInstantSaleModel> getSuspendedInstantSale({
    required int id,
  }) async {
    try {
      _instantSaleDebug('GET suspended item', {
        'endpoint': EndPoints.suspendedInstantSale,
        'id': id,
      });
      final response = await api.get(
        EndPoints.suspendedInstantSale,
        queryParameters: {'suspended_instant_sale_id': id},
      );
      _instantSaleDebug('suspended item response', response.data);
      final raw = response.data['suspended_instant_sale'];
      return SuspendedInstantSaleModel.fromJson(
        Map<String, dynamic>.from(raw as Map),
      );
    } on DioException catch (e) {
      _instantSaleDioError('getSuspendedInstantSale', e);
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data?['message'] ?? 'Unknown error',
          status: data?['status'] ?? 500,
          data: data ?? {},
        ),
      );
    }
  }

  Future<Map<String, dynamic>> suspendInstantSale({
    required String currentStep,
    required Map<String, dynamic> payload,
    int? suspendedInstantSaleId,
    String? note,
  }) async {
    try {
      final data = {
        'current_step': currentStep,
        'payload': payload,
        if (suspendedInstantSaleId != null)
          'suspended_instant_sale_id': suspendedInstantSaleId,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      };
      _instantSaleDebug('POST suspend instant sale', {
        'endpoint': EndPoints.suspendedInstantSale,
        'data': data,
      });
      final response = await api.post(
        EndPoints.suspendedInstantSale,
        data: data,
      );
      _instantSaleDebug('suspend instant sale response', response.data);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      _instantSaleDioError('suspendInstantSale', e);
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data?['message'] ?? 'Unknown error',
          status: data?['status'] ?? 500,
          data: data ?? {},
        ),
      );
    }
  }

  Future<SuspendedInstantSaleModel> addSuspendedInstantSaleNote({
    required int suspendedInstantSaleId,
    required String note,
  }) async {
    try {
      final data = {
        'suspended_instant_sale_id': suspendedInstantSaleId,
        'note': note.trim(),
      };
      _instantSaleDebug('POST suspended note', {
        'endpoint': EndPoints.suspendedInstantSaleNote,
        'id': suspendedInstantSaleId,
      });
      final response = await api.post(
        EndPoints.suspendedInstantSaleNote,
        data: data,
      );
      _instantSaleDebug('suspended note response', response.data);
      final body = response.data;
      if (body is! Map) {
        throw ServerException(
          ErrorModel(
            errorMessage: 'Invalid suspended invoice note response',
            status: 500,
            data: const {},
          ),
        );
      }
      final map = Map<String, dynamic>.from(body);
      if (map['status'] == 'error') {
        final validation = _validationMessage(map);
        throw ServerException(
          ErrorModel(
            errorMessage: validation.isNotEmpty
                ? validation
                : asString(map['message'], 'Unknown error'),
            status: 500,
            data: map,
          ),
        );
      }
      final raw = map['suspended_instant_sale'];
      if (raw is! Map) {
        throw ServerException(
          ErrorModel(
            errorMessage: 'Invalid suspended invoice note response',
            status: 500,
            data: map,
          ),
        );
      }
      return SuspendedInstantSaleModel.fromJson(
        Map<String, dynamic>.from(raw),
      );
    } on DioException catch (e) {
      _instantSaleDioError('addSuspendedInstantSaleNote', e);
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data?['message'] ?? 'Unknown error',
          status: data?['status'] ?? 500,
          data: data ?? {},
        ),
      );
    }
  }

  Future<Map<String, dynamic>> completeSuspendedInstantSale({
    required int suspendedInstantSaleId,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final data = {
        'suspended_instant_sale_id': suspendedInstantSaleId,
        if (payload != null) 'payload': payload,
      };
      _instantSaleDebug('POST complete suspended instant sale', {
        'endpoint': EndPoints.suspendedInstantSaleComplete,
        'data': data,
      });
      final response = await api.post(
        EndPoints.suspendedInstantSaleComplete,
        data: data,
      );
      _instantSaleDebug('complete suspended response', response.data);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      _instantSaleDioError('completeSuspendedInstantSale', e);
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data?['message'] ?? 'Unknown error',
          status: data?['status'] ?? 500,
          data: data ?? {},
        ),
      );
    }
  }

  Future<Map<String, dynamic>> cancelSuspendedInstantSale({
    required int suspendedInstantSaleId,
  }) async {
    try {
      final data = {'suspended_instant_sale_id': suspendedInstantSaleId};
      _instantSaleDebug('POST cancel suspended instant sale', {
        'endpoint': EndPoints.suspendedInstantSaleCancel,
        'data': data,
      });
      final response = await api.post(
        EndPoints.suspendedInstantSaleCancel,
        data: data,
      );
      _instantSaleDebug('cancel suspended response', response.data);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      _instantSaleDioError('cancelSuspendedInstantSale', e);
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data?['message'] ?? 'Unknown error',
          status: data?['status'] ?? 500,
          data: data ?? {},
        ),
      );
    }
  }
}
