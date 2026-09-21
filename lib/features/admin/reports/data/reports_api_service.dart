import 'package:dio/dio.dart';

import '../../../../core/databases/api/api_consumer.dart';
import '../../../../core/databases/api/end_points.dart';
import '../../../../core/errors/error_model.dart';
import '../../../../core/errors/expentions.dart';

class ReportsApiService {
  ReportsApiService({required this.api});

  final ApiConsumer api;

  Future<Map<String, dynamic>> salesReport({
    required String period,
    DateTime? fromDate,
    DateTime? toDate,
    String status = 'all',
    String paymentType = 'all',
    String? boxId,
  }) async {
    try {
      final response = await api.get(
        EndPoints.adminSalesReport,
        queryParameters: {
          'period': period,
          'status': status,
          'payment_type': paymentType,
          if (boxId != null && boxId.isNotEmpty) 'box_id': boxId,
          if (fromDate != null) 'from_date': _formatDate(fromDate),
          if (toDate != null) 'to_date': _formatDate(toDate),
        },
      );
      _throwIfError(response.data);
      return Map<String, dynamic>.from(response.data['data'] ?? {});
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  Future<Map<String, dynamic>> reportData({
    required String type,
    required String period,
    DateTime? fromDate,
    DateTime? toDate,
    String checkDirection = 'all',
    String? personType,
    String? personId,
    String? boxId,
    String currency = 'شيكل',
    String? accountId,
  }) async {
    try {
      final response = await api.get(
        EndPoints.adminReportsData,
        queryParameters: {
          'type': type,
          'period': period,
          'check_direction': checkDirection,
          if (personType != null && personType.isNotEmpty)
            'person_type': personType,
          if (personId != null && personId.isNotEmpty) 'person_id': personId,
          if (boxId != null && boxId.isNotEmpty) 'box_id': boxId,
          'currency': currency,
          if (accountId != null && accountId.isNotEmpty)
            'account_id': accountId,
          if (fromDate != null) 'from_date': _formatDate(fromDate),
          if (toDate != null) 'to_date': _formatDate(toDate),
        },
      );
      _throwIfError(response.data);
      return Map<String, dynamic>.from(response.data['data'] ?? {});
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  Future<Map<String, dynamic>> reportOptions({String scope = 'all'}) async {
    try {
      final response = await api.get(
        EndPoints.adminReportsPeople,
        queryParameters: {'scope': scope},
      );
      _throwIfError(response.data);
      final data = Map<String, dynamic>.from(response.data['data'] ?? {});
      return data;
    } on DioException catch (e) {
      throw _serverException(e);
    }
  }

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  void _throwIfError(dynamic responseData) {
    if (responseData is Map && responseData['status'] == 'error') {
      throw ServerException(
        ErrorModel(
          errorMessage: responseData['message'] ?? 'Unknown error',
          status: responseData['status'] is int
              ? responseData['status'] as int
              : 500,
          data: responseData['data'] ?? {},
        ),
      );
    }
  }

  ServerException _serverException(DioException error) {
    final responseData = error.response?.data;
    final data = responseData is Map
        ? Map<String, dynamic>.from(responseData)
        : const <String, dynamic>{};
    final status = data['status'];
    return ServerException(
      ErrorModel(
        errorMessage: data['message']?.toString() ??
            error.message ??
            'تعذر الاتصال بالخادم',
        status: status is int ? status : error.response?.statusCode ?? 500,
        data: data['data'] is Map
            ? Map<String, dynamic>.from(data['data'] as Map)
            : const <String, dynamic>{},
      ),
    );
  }
}
