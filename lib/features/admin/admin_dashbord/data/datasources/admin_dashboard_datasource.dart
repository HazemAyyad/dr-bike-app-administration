// ignore_for_file: depend_on_referenced_packages

import 'package:dio/dio.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../employee_section/data/models/logs_model.dart';

class AdminDashboardDatasource {
  final ApiConsumer api;

  AdminDashboardDatasource({required this.api});

  Future<List<LogsModel>> getAdminLogs() async {
    try {
      final response = await api.get(EndPoints.adminLogs);
      final data = response.data['logs'] as List;
      return data.map((e) => LogsModel.fromJson(e)).toList();
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
