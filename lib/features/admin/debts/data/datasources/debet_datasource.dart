import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/helpers/json_safe_parser.dart';

void _debugLogDebtListSample(
  String flow,
  String endpoint,
  dynamic responseData,
) {
  if (!kDebugMode) return;
  final sample = extractMapListFromResponse(responseData, ApiKey.debts);
  if (sample.isEmpty) return;
  debugParseLog(
    'DebetDatasource.$flow',
    'endpoint=$endpoint model=DebtsWeOwe sample=${sample.first}',
  );
}

class DebetDatasource {
  final ApiConsumer api;

  DebetDatasource({required this.api});

  Future<Map<String, dynamic>> totalDebtsOwedToUs() async {
    try {
      final response = await api.get(EndPoints.totalDebtsOwedToUs);
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

  Future<Map<String, dynamic>> totalDebtsWeOwe() async {
    try {
      final response = await api.get(EndPoints.totalDebtsWeOwe);
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

  Future<Map<String, dynamic>> debtsOwedToUs() async {
    try {
      final response = await api.get(
        EndPoints.getDebtsOwedToUs,
      );
      _debugLogDebtListSample('debtsOwedToUs', EndPoints.getDebtsOwedToUs, response.data);
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

  Future<Map<String, dynamic>> debtsWeOwe() async {
    try {
      final response = await api.get(EndPoints.getDebtsWeOwe);
      _debugLogDebtListSample('debtsWeOwe', EndPoints.getDebtsWeOwe, response.data);
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

  Future<Map<String, dynamic>> userTransactionsData({
    required String customerId,
    required String sellerId,
  }) async {
    try {
      final response = await api.post(
        EndPoints.personDebts,
        data: {
          if (customerId != '0') 'customer_id': customerId,
          if (sellerId != '0') 'seller_id': sellerId,
        },
      );
      // final data = response.data;
      // print('Response data: $response');
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

  // addDebt
  Future<Map<String, dynamic>> addDebt({
    required bool isCustomer,
    required String customerId,
    required String type,
    required String dueDate,
    required String total,
    required List<File> receiptImage,
    required String notes,
    required String boxId,
  }) async {
    try {
      final response = await api.post(
        EndPoints.addDebt,
        data: {
          if (isCustomer) 'customer_id': customerId,
          if (!isCustomer) 'seller_id': customerId,
          'type': type,
          'due_date': dueDate,
          'total': total,
          'receipt_image[]': await Future.wait(
            receiptImage.map(
              (file) => MultipartFile.fromFile(
                file.path,
                filename: file.path.split('/').last,
              ),
            ),
          ),
          'notes': notes,
          'box_id': boxId,
        },
        isFormData: true,
      );
      // final data = response.data;
      // print('Response data: $response');
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

  Future<Uint8List> getDebtsReports({required String customerId}) async {
    try {
      final response = customerId.isNotEmpty
          ? await api.post(
              EndPoints.getDebtsReports,
              data: {'customer_id': customerId},
              options: Options(responseType: ResponseType.bytes),
              isFormData: true,
            )
          : await api.get(
              EndPoints.getAttendanceDetails,
              options: Options(responseType: ResponseType.bytes),
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
