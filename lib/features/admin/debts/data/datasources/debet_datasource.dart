import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';

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

  Future<Map<String, dynamic>> userTransactionsData({
    required String customerId,
  }) async {
    try {
      final response = await api.post(
        EndPoints.customerDebts,
        data: {'customer_id': customerId},
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
    required String customerId,
    required String type,
    required String dueDate,
    required String total,
    required List<File> receiptImage,
    required String notes,
  }) async {
    try {
      final response = await api.post(
        EndPoints.addDebt,
        data: {
          'customer_id': customerId,
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
}
