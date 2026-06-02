import 'dart:core';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:doctorbike/features/admin/sales/data/models/instant_sales_model.dart';
import 'package:doctorbike/features/admin/sales/data/models/product_price_update_result.dart';
import 'package:doctorbike/features/admin/sales/data/models/profit_sale_model.dart';
import 'package:doctorbike/features/admin/sales/presentation/controllers/sales_controller.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/helpers/json_safe_parser.dart';
import '../../../stock/data/models/offer_package_model.dart';
import '../models/invoice_model.dart';
import '../models/product_model.dart';

class SalesDatasource {
  final ApiConsumer api;

  SalesDatasource({required this.api});

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
  Future<List<ProductModel>> getAllProducts({required String endPoint}) async {
    try {
      final response =
          await api.get(endPoint.isNotEmpty ? endPoint : EndPoints.allProducts);
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
  }) async {
    try {
      final otherProductsList =
          (offerPackageId != null && offerPackageId.isNotEmpty)
              ? (cartOtherProducts ?? <Map<String, dynamic>>[])
              : otherProducts
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
      final additionalNotesMap = <String, dynamic>{};
      for (var i = 0; i < additionalNotes.length; i++) {
        final note = additionalNotes[i];
        additionalNotesMap['additional_notes[$i][text]'] =
            note['text']?.toString() ?? '';
        additionalNotesMap['additional_notes[$i][amount]'] =
            note['amount']?.toString() ?? '0';
      }

      final response = await api.post(
        EndPoints.createInstantSale,
        data: {
          if (offerPackageId != null && offerPackageId.isNotEmpty)
            'offer_package_id': offerPackageId
          else
            'product_id': productId,
          'quantity': quantity,
          'cost': cost,
          'discount': discount,
          'total_cost': totalCost,
          'notes': note,
          ...additionalNotesMap,
          'type': type,
          if (projectId.isNotEmpty) 'project_id': projectId,
          'buyer_type': buyerType,
          if (buyerId != null && buyerId.isNotEmpty) 'buyer_id': buyerId,
          if (sellerId != null && sellerId.isNotEmpty) 'seller_id': sellerId,
          if (buyerName != null && buyerName.isNotEmpty)
            'buyer_name': buyerName,
          if (paymentBoxId != null && paymentBoxId.isNotEmpty)
            'payment_box_id': paymentBoxId,
          if (paymentBoxName != null && paymentBoxName.isNotEmpty)
            'payment_box_name': paymentBoxName,
          if (paymentBoxId != null && paymentBoxId.isNotEmpty)
            'payment_box_value': paymentBoxValue ?? '0',
          'other_products': otherProductsList,
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
          data: data['data'] ?? {},
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

  // get Invoice
  Future<InvoiceModel> getInvoice({required String invoiceId}) async {
    try {
      final response = await api.post(EndPoints.getInstantSaleInvoice,
          data: {'instant_sale_id': invoiceId});
      assert(() {
        // ignore: avoid_print
        print('[InvoiceDetails] ${response.data}');
        return true;
      }());
      final raw = response.data['instant_sale_invoice'];
      if (raw == null) {
        throw ServerException(
          ErrorModel(
            errorMessage:
                response.data['message']?.toString() ?? 'Unknown error',
            status: 500,
            data: {},
          ),
        );
      }
      final Map<String, dynamic> invoiceMap = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw as Map);
      return InvoiceModel.fromJson(invoiceMap);
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
}
