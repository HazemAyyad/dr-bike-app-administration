import 'package:dio/dio.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';

class DebetDatasource {
  final ApiConsumer api;

  DebetDatasource({required this.api});

  Future<Map<String, dynamic>> totalDebtsOwedToUs(
      {required String token}) async {
    try {
      final response = await api.get(
        EndPoints.totalDebtsOwedToUs,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
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

  Future<Map<String, dynamic>> totalDebtsWeOwe({required String token}) async {
    try {
      final response = await api.get(
        EndPoints.totalDebtsWeOwe,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
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

  Future<Map<String, dynamic>> debtsOwedToUs({required String token}) async {
    try {
      final response = await api.get(
        EndPoints.getDebtsOwedToUs,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
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

  Future<Map<String, dynamic>> debtsWeOwe({required String token}) async {
    try {
      final response = await api.get(
        EndPoints.getDebtsWeOwe,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
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

  Future<Map<String, dynamic>> userTransactionsData({
    required String token,
    required String customerId,
  }) async {
    try {
      final response = await api.post(
        EndPoints.customerDebts,
        data: {'customer_id': customerId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
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
