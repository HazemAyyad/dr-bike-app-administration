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

  // download report
  Future<Uint8List> getReportByType({
    String? type,
    String? employeeId,
    DateTime? fromDate,
    DateTime? toDate,
    String? boxId,
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
