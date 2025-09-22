import 'package:dio/dio.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
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

  // add Bill
  Future<dynamic> addBill({
    required String page,
    required String sellerId,
    required List<BillModel> products,
    required String total,
  }) async {
    final Map<String, dynamic> productsList = {};

    for (var i = 0; i < products.length; i++) {
      if (sellerId.isNotEmpty) productsList['seller_id'] = sellerId;
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
      if (total.isNotEmpty) productsList['total'] = total;
    }

    try {
      final response = await api.post(
        page == '3'
            ? EndPoints.addReturnPurchase
            : sellerId.isEmpty
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
