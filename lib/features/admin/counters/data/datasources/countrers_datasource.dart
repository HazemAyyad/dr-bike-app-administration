import 'package:dio/dio.dart';
import 'dart:typed_data';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../models/report_information_model.dart';

class CountrersDatasource {
  final ApiConsumer api;

  CountrersDatasource({required this.api});

  Future<ReportInformationModel> getReportInformation() async {
    try {
      final response = await api.get(EndPoints.getAllReportInformation);
      return ReportInformationModel.fromJson(response.data['data']);
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

  Future<Map<String, dynamic>> getAnalytics({
    required String period,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final response = await api.get(
      EndPoints.adminReportsAnalytics,
      queryParameters: {
        'period': period,
        if (fromDate != null) 'from_date': _date(fromDate),
        if (toDate != null) 'to_date': _date(toDate),
      },
    );
    final body = response.data;
    if (body is! Map || body['status'] != 'success') {
      throw ServerException(ErrorModel(
        errorMessage:
            body is Map ? body['message'] ?? 'Unknown error' : 'Unknown error',
        status: 500,
        data: body is Map ? body['data'] ?? {} : {},
      ));
    }
    return Map<String, dynamic>.from(body['data'] ?? {});
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  // download report
  Future<Uint8List> getReportByType({
    String? type,
    String? employeeId,
    DateTime? fromDate,
    DateTime? toDate,
    String? boxId,
    String? direction,
    List<String>? movementTypes,
    String? search,
    double? minAmount,
    double? maxAmount,
  }) async {
    try {
      final response = await api.post(
        boxId != null
            ? EndPoints.boxLogsReport
            : employeeId != null
                ? EndPoints.employeeFinancialDataReport
                : EndPoints.getReportByType,
        data: {
          if (type != null) 'type': type,
          if (employeeId != null) 'employee_id': employeeId,
          if (boxId != null) 'box_id': boxId,
          if (direction != null && direction.isNotEmpty) 'direction': direction,
          if (movementTypes != null && movementTypes.isNotEmpty)
            'types': movementTypes,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (minAmount != null) 'min_amount': minAmount,
          if (maxAmount != null) 'max_amount': maxAmount,
          'from_date': fromDate,
          'to_date': toDate,
        },
        options: Options(responseType: ResponseType.bytes),
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
}
