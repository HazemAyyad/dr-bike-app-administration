import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';

class EmployeeDatasource {
  final ApiConsumer api;

  EmployeeDatasource({required this.api});

  // create new employee
  Future<Map<String, dynamic>> creatEmployee({
    required String token,
    required String name,
    required String email,
    required String phone,
    required String subPhone,
    required String password,
    required String passwordConfirmation,
    required String hourWorkPrice,
    required String overtimeWorkPrice,
    required String numberOfWorkHours,
    required String startWorkTime,
    required XFile? documentImg,
    required XFile? employeeImg,
    required List<String> permissions,
  }) async {
    try {
      final response = await api.post(
        EndPoints.createEmployee,
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'sub_phone': subPhone,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'hour_work_price': hourWorkPrice,
          'overtime_work_price': overtimeWorkPrice,
          'number_of_work_hours': numberOfWorkHours,
          'start_work_time': startWorkTime,
          if (employeeImg != null)
            'employee_img': await MultipartFile.fromFile(
              employeeImg.path,
              filename: employeeImg.name,
            ),
          if (documentImg != null)
            'document_img': await MultipartFile.fromFile(
              documentImg.path,
              filename: documentImg.name,
            ),
          'permissions[]': permissions,
        },
        isFormData: true,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );
      final data = response.data;
      // print('Response data: $response');
      return data;
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

  // add or minus points
  Future<Map<String, dynamic>> addPointsToEmployee({
    required String token,
    required String employeeId,
    required String points,
    required bool isAdd,
  }) async {
    try {
      final response = await api.post(
        isAdd
            ? EndPoints.addPointsToEmployee
            : EndPoints.minusPointsFromEmployee,
        data: {
          'employee_id': employeeId,
          'points': points,
        },
        isFormData: true,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );
      final data = response.data;
      // print('Response data: $response');
      return data;
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

  // pay salary
  Future<Map<String, dynamic>> paySalaryToEmployeeUsecase({
    required String token,
    required String employeeId,
    required String salary,
  }) async {
    try {
      final response = await api.post(
        EndPoints.paySalaryToEmployee,
        data: {
          'employee_id': employeeId,
          'salary_to_pay': salary,
        },
        isFormData: true,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );
      final data = response.data;
      // print('Response data: $response');
      return data;
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
