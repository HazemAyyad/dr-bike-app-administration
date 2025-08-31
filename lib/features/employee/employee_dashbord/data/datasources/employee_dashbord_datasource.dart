// ignore_for_file: depend_on_referenced_packages

import 'package:dio/dio.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
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
      print('Response data: $response');
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
      final response = await api.post(EndPoints.employeeHomeData);
      return DashbordEmployeeDetailsModel.fromJson(
          response.data['employee_details']);
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
