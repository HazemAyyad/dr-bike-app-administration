import 'package:dio/dio.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/json_safe_parser.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../admin/employee_section/data/models/employee_attendance_history_model.dart';
import '../models/dashbord_employee_details_model.dart';

class EmployeeDashbordDatasource {
  final ApiConsumer api;

  EmployeeDashbordDatasource({required this.api});

  // Request over time or loan
  Future<Map<String, dynamic>> requestOverTimeOrLoan({
    required bool isOverTime,
    required String value,
  }) async {
    try {
      final response = await api.post(
        isOverTime ? EndPoints.addOvertimeOrder : EndPoints.addLoanOrder,
        data: {
          if (isOverTime) 'overtime_value': value,
          if (!isOverTime) 'loan_value': value,
        },
      );
      // final data = response.data;
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

  // get employee data
  Future<DashbordEmployeeDetailsModel> getEmployeeData() async {
    try {
      final response = await api.get(EndPoints.employeeHomeData);
      final raw = response.data;
      if (raw is! Map) {
        debugParseLog(
          'EmployeeDashDS',
          'getEmployeeData: expected Map, got ${raw.runtimeType}',
        );
        return DashbordEmployeeDetailsModel.fromJson(<String, dynamic>{});
      }
      final map = Map<String, dynamic>.from(raw);
      final details = map['employee_details'];
      return DashbordEmployeeDetailsModel.fromJson(asMap(details));
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

  Future<EmployeeAttendanceHistoryResult> getMyAttendanceHistory({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      String fmt(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final response = await api.get(
        EndPoints.employeeMyAttendanceHistory,
        queryParameters: {
          if (fromDate != null) 'from_date': fmt(fromDate),
          if (toDate != null) 'to_date': fmt(toDate),
        },
      );
      final raw = response.data;
      try {
        return EmployeeAttendanceHistoryResult.fromJson(asMap(raw));
      } on FormatException catch (e) {
        throw ServerException(
          ErrorModel(
            errorMessage: e.message,
            status: 400,
            data: asMap(raw),
          ),
        );
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage:
              data is Map ? (data['message'] ?? 'Unknown error') : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    }
  }

  // change employee task to completed
  Future<Map<String, dynamic>> changeEmployeeTaskToCompleted({
    required bool isSubTask,
    required int taskId,
  }) async {
    try {
      final response = await api.post(
          isSubTask
              ? EndPoints.changeSubEmployeeTaskToCompleted
              : EndPoints.changeEmployeeTaskToCompleted,
          data: {
            if (isSubTask) 'sub_task_id': taskId,
            if (!isSubTask) 'employee_task_id': taskId,
          });
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
