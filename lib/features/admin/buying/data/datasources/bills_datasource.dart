import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/helpers/json_safe_parser.dart';
import '../../presentation/controllers/bills_controller.dart';

class BillsDatasource {
  final ApiConsumer api;

  BillsDatasource({required this.api});

  // get Bills
  Future<dynamic> getBills({required String page}) async {
    try {
      final response = await api.get(
        page == '0'
            ? EndPoints.unfinishedBills
            : page == '1'
                ? EndPoints.archivedBills
                : page == '2'
                    ? EndPoints.unfinishedBills
                    : page == '3'
                        ? EndPoints.unmatchedBills
                        : page == '4'
                            ? EndPoints.finishedBills
                            : page == '5'
                                ? EndPoints.securitiesBills
                                : page == '6'
                                    ? EndPoints.getPendingReturnPurchases
                                    : EndPoints.getDeliveredReturnPurchases,
      );
      final data = response.data;
      if (kDebugMode && data is Map) {
        final m = Map<String, dynamic>.from(data);
        final bills = m['bills'];
        if (bills is List && bills.isNotEmpty) {
          debugParseLog(
            'BillsDatasource.getBills',
            'page=$page sampleBill=${bills.first}',
          );
        }
        final rp = m['return_products'];
        if (rp is List && rp.isNotEmpty) {
          debugParseLog(
            'BillsDatasource.getBills',
            'page=$page sampleReturnProduct=${rp.first}',
          );
        }
      }
      return data;
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

  // add Bill
  Future<dynamic> addBill({
    required String page,
    required String sellerId,
    String customerId = '',
    required List<BillModel> products,
    required String total,
    String initialPayment = '0',
    String? boxId,
  }) async {
    final Map<String, dynamic> productsList = {};

    for (var i = 0; i < products.length; i++) {
      if (sellerId.isNotEmpty) productsList['seller_id'] = sellerId;
      if (customerId.isNotEmpty) productsList['customer_id'] = customerId;
      if (products[i].productIdController.text.isNotEmpty) {
        productsList['products[$i][product_id]'] =
            products[i].productIdController.text;
      }
      if (products[i].quantityController.text.isNotEmpty) {
        productsList['products[$i][quantity]'] =
            products[i].quantityController.text;
      }
      if (products[i].priceController.text.isNotEmpty) {
        productsList['products[$i][purchase_price]'] =
            products[i].priceController.text;
      }
      if (products[i].sizeId?.isNotEmpty == true) {
        productsList['products[$i][size_id]'] = products[i].sizeId;
      }
      if (products[i].sizeColorId?.isNotEmpty == true) {
        productsList['products[$i][size_color_id]'] = products[i].sizeColorId;
      }
      if (total.isNotEmpty) productsList['total'] = total;
    }
    final paid = num.tryParse(initialPayment) ?? 0;
    if (paid > 0) {
      productsList['initial_payment'] = initialPayment;
      if (boxId != null && boxId.isNotEmpty) {
        productsList['box_id'] = boxId;
      }
    }

    try {
      final response = await api.post(
        page == '3'
            ? EndPoints.addReturnPurchase
            : sellerId.isEmpty && customerId.isEmpty
                ? EndPoints.addBillQuantity
                : EndPoints.addBill,
        data: productsList,
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

  Future<dynamic> receivePurchase({
    required String billId,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    try {
      final response = await api.post(
        EndPoints.purchaseReceive,
        data: {
          'bill_id': billId,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          'items': items,
        },
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

  Future<dynamic> updatePurchaseDraft({
    required String billId,
    required String sellerId,
    String customerId = '',
    required List<BillModel> products,
    required String total,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      'bill_id': billId,
      if (sellerId.isNotEmpty) 'seller_id': sellerId,
      if (customerId.isNotEmpty) 'customer_id': customerId,
      'total': total,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    for (var i = 0; i < products.length; i++) {
      final product = products[i];
      data['products[$i][product_id]'] = product.productIdController.text;
      data['products[$i][quantity]'] = product.quantityController.text;
      data['products[$i][purchase_price]'] = product.priceController.text;
      if (product.sizeId?.isNotEmpty == true) {
        data['products[$i][size_id]'] = product.sizeId;
      }
      if (product.sizeColorId?.isNotEmpty == true) {
        data['products[$i][size_color_id]'] = product.sizeColorId;
      }
    }
    try {
      final response = await api.post(
        EndPoints.purchaseUpdateDraft,
        data: data,
        isFormData: true,
      );
      return response.data;
    } on DioException catch (e) {
      final error = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: error['message'] ?? 'Unknown error',
          status: error['status'] ?? 500,
          data: error['data'] ?? {},
        ),
      );
    }
  }

  Future<dynamic> deletePurchaseDraft({required String billId}) async {
    try {
      final response = await api.post(
        EndPoints.purchaseDeleteDraft,
        data: {'bill_id': billId},
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

  Future<dynamic> finalizePurchase({
    required String billId,
    String initialPayment = '0',
    String? boxId,
  }) async {
    try {
      final response = await api.post(
        EndPoints.purchaseFinalize,
        data: {
          'bill_id': billId,
          'initial_payment': initialPayment,
          if (boxId != null && boxId.isNotEmpty) 'box_id': boxId,
        },
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

  Future<dynamic> payPurchase({
    required String billId,
    required String amount,
    required String boxId,
    String? note,
    List<MultipartFile> evidenceFiles = const [],
  }) async {
    try {
      final data = {
        'bill_id': billId,
        'amount': amount,
        'box_id': boxId,
        if (note != null && note.isNotEmpty) 'note': note,
        if (evidenceFiles.isNotEmpty) 'receipt_images[]': evidenceFiles,
      };
      final response = await api.post(
        EndPoints.purchasePayment,
        data: data,
        isFormData: evidenceFiles.isNotEmpty,
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

  Future<dynamic> paySupplierAccount({
    String sellerId = '',
    String customerId = '',
    required String amount,
    required String boxId,
    String? note,
    bool allocateOldestFirst = true,
    List<Map<String, dynamic>> allocations = const [],
    List<MultipartFile> evidenceFiles = const [],
  }) async {
    try {
      final data = {
        if (sellerId.isNotEmpty) 'seller_id': sellerId,
        if (customerId.isNotEmpty) 'customer_id': customerId,
        'amount': amount,
        'box_id': boxId,
        'allocate_oldest_first': allocateOldestFirst,
        if (allocations.isNotEmpty) 'allocations': allocations,
        if (note != null && note.isNotEmpty) 'note': note,
        if (evidenceFiles.isNotEmpty) 'receipt_images[]': evidenceFiles,
      };
      final response = await api.post(
        EndPoints.purchaseAccountPayment,
        data: data,
        isFormData: evidenceFiles.isNotEmpty,
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

  Future<dynamic> purchaseAccountOpenBills({
    String sellerId = '',
    String customerId = '',
    String? currency,
  }) async {
    try {
      final response = await api.get(
        EndPoints.purchaseAccountOpenBills,
        queryParameters: {
          if (sellerId.isNotEmpty) 'seller_id': sellerId,
          if (customerId.isNotEmpty) 'customer_id': customerId,
          if (currency != null && currency.isNotEmpty) 'currency': currency,
        },
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

  Future<dynamic> createPurchaseReturn({
    String sellerId = '',
    String customerId = '',
    String? billId,
    required List<BillModel> products,
    required String total,
    required String resolution,
    String? refundBoxId,
    String? note,
  }) async {
    final Map<String, dynamic> data = {
      if (sellerId.isNotEmpty) 'seller_id': sellerId,
      if (customerId.isNotEmpty) 'customer_id': customerId,
      if (billId != null && billId.isNotEmpty) 'bill_id': billId,
      if (total.isNotEmpty) 'total': total,
      'resolution': resolution,
      if (refundBoxId != null && refundBoxId.isNotEmpty)
        'refund_box_id': refundBoxId,
      if (note != null && note.isNotEmpty) 'note': note,
    };
    for (var i = 0; i < products.length; i++) {
      data['products[$i][product_id]'] = products[i].productIdController.text;
      data['products[$i][quantity]'] = products[i].quantityController.text;
      data['products[$i][purchase_price]'] = products[i].priceController.text;
      if (products[i].sizeId?.isNotEmpty == true) {
        data['products[$i][size_id]'] = products[i].sizeId;
      }
      if (products[i].sizeColorId?.isNotEmpty == true) {
        data['products[$i][size_color_id]'] = products[i].sizeColorId;
      }
    }

    try {
      final response = await api.post(
        EndPoints.addReturnPurchase,
        data: data,
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

  Future<dynamic> getPurchaseReturns({String? status, String? search}) async {
    final response = await api.get(
      'purchase/returns',
      queryParameters: {
        if (status?.isNotEmpty == true) 'status': status,
        if (search?.isNotEmpty == true) 'search': search,
        'per_page': 100,
      },
    );
    return response.data;
  }

  Future<dynamic> getReturnablePurchaseBills() async {
    final response = await api.get('purchase/returns/returnable-bills');
    return response.data;
  }

  Future<dynamic> getPurchaseReturnAvailableItems(String billId) async {
    final response = await api.get(
      'purchase/returns/bills/$billId/available-items',
    );
    return response.data;
  }

  Future<dynamic> getPurchaseReturnDetails(String returnId) async {
    final response = await api.get('purchase/returns/$returnId');
    return response.data;
  }

  Future<dynamic> uploadPurchaseReturnAttachments({
    required String returnId,
    required List<MultipartFile> files,
  }) async {
    final formData = FormData();
    formData.fields.add(const MapEntry('category', 'return_evidence'));
    for (final file in files) {
      formData.files.add(MapEntry('files[]', file));
    }
    final response = await api.post(
      'purchase/returns/$returnId/attachments',
      data: formData,
      isFormData: false,
    );
    return response.data;
  }

  Future<List<int>> downloadPurchaseReturnPdf(String returnId) async {
    final response = await api.get(
      'purchase/returns/$returnId/print',
      options: Options(responseType: ResponseType.bytes),
    );
    return List<int>.from(response.data);
  }

  Future<dynamic> createPurchaseReturnDraft({
    required String billId,
    required List<Map<String, dynamic>> items,
    String? reason,
    String? notes,
  }) async {
    final response = await api.post('purchase/returns', data: {
      'bill_id': billId,
      'items': items,
      if (reason?.isNotEmpty == true) 'reason': reason,
      if (notes?.isNotEmpty == true) 'notes': notes,
    });
    return response.data;
  }

  Future<dynamic> purchaseReturnAction({
    required String returnId,
    required String action,
    Map<String, dynamic> data = const {},
  }) async {
    final response = await api.post(
      'purchase/returns/$returnId/$action',
      data: data,
    );
    return response.data;
  }

  Future<dynamic> purchaseAmanat({
    required String amanatId,
    required String quantity,
    required String unitPrice,
  }) async {
    try {
      final response = await api.post(
        EndPoints.purchaseAmanatPurchase,
        data: {
          'amanat_id': amanatId,
          'quantity': quantity,
          'unit_price': unitPrice,
        },
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

  Future<dynamic> returnAmanat({
    required String amanatId,
    required String quantity,
    String? note,
  }) async {
    try {
      final response = await api.post(
        EndPoints.purchaseAmanatReturn,
        data: {
          'amanat_id': amanatId,
          'quantity': quantity,
          if (note != null && note.isNotEmpty) 'note': note,
        },
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

  Future<dynamic> resolvePurchaseIssue({
    required String billId,
    required String billItemId,
    required String issueType,
    required String resolution,
    required String quantity,
    String? negotiatedUnitPrice,
    String? financialAdjustment,
    String? reason,
    String? notes,
  }) async {
    try {
      final response = await api.post(
        EndPoints.purchaseIssueResolve,
        data: {
          'bill_id': billId,
          'bill_item_id': billItemId,
          'issue_type': issueType,
          'resolution': resolution,
          'quantity': quantity,
          if (negotiatedUnitPrice != null && negotiatedUnitPrice.isNotEmpty)
            'negotiated_unit_price': negotiatedUnitPrice,
          if (financialAdjustment != null && financialAdjustment.isNotEmpty)
            'financial_adjustment': financialAdjustment,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
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

  Future<dynamic> purchaseTimeline({required String billId}) async {
    try {
      final response = await api.get(
        EndPoints.purchaseTimeline,
        queryParameters: {'bill_id': billId},
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

  Future<dynamic> purchasePriceIntelligence({
    required String productId,
    String? sellerId,
    String? customerId,
  }) async {
    try {
      final response = await api.get(
        EndPoints.purchasePriceIntelligence,
        queryParameters: {
          'product_id': productId,
          if (sellerId != null && sellerId.isNotEmpty) 'seller_id': sellerId,
          if (customerId != null && customerId.isNotEmpty)
            'customer_id': customerId,
        },
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

  Future<dynamic> purchaseAmanatIndex({
    String? status,
    String? search,
  }) async {
    try {
      final response = await api.get(
        EndPoints.purchaseAmanatIndex,
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          if (search != null && search.isNotEmpty) 'search': search,
        },
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

  Future<dynamic> purchaseDiscrepancies({
    String? type,
    String? search,
  }) async {
    try {
      final response = await api.get(
        EndPoints.purchaseDiscrepancies,
        queryParameters: {
          if (type != null && type.isNotEmpty) 'type': type,
          if (search != null && search.isNotEmpty) 'search': search,
        },
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

  Future<dynamic> uploadPurchaseAttachments({
    required String billId,
    required List<MultipartFile> files,
    String category = 'evidence',
    String? attachableType,
    String? attachableId,
  }) async {
    try {
      final formData = FormData();
      formData.fields.add(MapEntry('bill_id', billId));
      formData.fields.add(MapEntry('category', category));
      if (attachableType != null && attachableType.isNotEmpty) {
        formData.fields.add(MapEntry('attachable_type', attachableType));
      }
      if (attachableId != null && attachableId.isNotEmpty) {
        formData.fields.add(MapEntry('attachable_id', attachableId));
      }
      for (final file in files) {
        formData.files.add(MapEntry('files[]', file));
      }
      final response = await api.post(
        EndPoints.purchaseAttachments,
        data: formData,
        isFormData: false,
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

  // get Bill Details
  Future<dynamic> getBillDetails({
    required String billId,
    required bool isDownload,
  }) async {
    try {
      final response = await api.post(
        isDownload ? EndPoints.billReport : EndPoints.getBillDetails,
        data: {'bill_id': billId},
        options: isDownload ? Options(responseType: ResponseType.bytes) : null,
        isFormData: true,
      );
      final raw = response.data;
      if (kDebugMode && !isDownload) {
        final ep = isDownload ? EndPoints.billReport : EndPoints.getBillDetails;
        debugParseLog(
          'BillsDatasource.getBillDetails',
          'endpoint=$ep billId=$billId rawKeys=${asMap(raw).keys.toList()}',
        );
        dynamic bd = asMap(raw)['bill_details'];
        bd ??= asMap(asMap(raw)['data'])['bill_details'];
        final bdm = asMap(bd);
        final prods = bdm['products'];
        if (prods is List && prods.isNotEmpty) {
          debugParseLog(
            'BillsDatasource.getBillDetails',
            'sampleProduct=${prods.first}',
          );
        }
      }
      return raw;
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

  // cancel Bill
  Future<dynamic> cancelBill({required String billId}) async {
    try {
      final response = await api.post(
        EndPoints.cancelBill,
        data: {'bill_id': billId},
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

  // change Product Status
  Future<dynamic> changeProductStatus({
    required String billId,
    required String productId,
    required String status,
    required String extraAmount,
    required String missingAmount,
    required String notCompatibleAmount,
    required String notCompatibleDescription,
  }) async {
    try {
      final response = await api.post(
        EndPoints.changeProductStatus,
        data: {
          'bill_id': billId,
          'product_id': productId,
          'status': status,
          'extra_amount': extraAmount,
          'missing_amount': missingAmount,
          'not_compatible_amount': notCompatibleAmount,
          'not_compatible_description': notCompatibleDescription,
        },
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

  // change One Product Status
  Future<dynamic> changeOneProductStatus({
    required String billId,
    required String productId,
    required String price,
    required bool isDeliver,
  }) async {
    try {
      final response = await api.post(
        price.isNotEmpty
            ? EndPoints.purchaseNewPrice
            : isDeliver
                ? EndPoints.deliverOneProduct
                : EndPoints.purchaseExtraProducts,
        data: {
          'bill_id': billId,
          'product_id': productId,
          'price': price,
        },
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

  // archive Bill
  Future<dynamic> changeReturnToDelivered(
      {required String returnPurchaseId}) async {
    try {
      final response = await api.post(
        EndPoints.changeReturnPurchaseToDelivered,
        data: {'return_purchase_id': returnPurchaseId},
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
}
