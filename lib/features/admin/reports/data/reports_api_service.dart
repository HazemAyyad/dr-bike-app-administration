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
  }) async {
    try {
      final response = await api.get(
        EndPoints.adminSalesReport,
        queryParameters: {
          'period': period,
          'status': status,
          'payment_type': paymentType,
          if (fromDate != null) 'from_date': _formatDate(fromDate),
          if (toDate != null) 'to_date': _formatDate(toDate),
        },
      );
      _throwIfError(response.data);
      return Map<String, dynamic>.from(response.data['data'] ?? {});
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

  Future<Map<String, dynamic>> reportData({
    required String type,
    required String period,
    DateTime? fromDate,
    DateTime? toDate,
    String checkDirection = 'all',
    String? personType,
    String? personId,
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
          if (fromDate != null) 'from_date': _formatDate(fromDate),
          if (toDate != null) 'to_date': _formatDate(toDate),
        },
      );
      _throwIfError(response.data);
      return Map<String, dynamic>.from(response.data['data'] ?? {});
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

  Future<List<Map<String, dynamic>>> reportPeople() async {
    try {
      final response = await api.get(EndPoints.adminReportsPeople);
      _throwIfError(response.data);
      final data = Map<String, dynamic>.from(response.data['data'] ?? {});
      return (data['people'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
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
          status: responseData['status'] ?? 500,
          data: responseData['data'] ?? {},
        ),
      );
    }
  }
}
