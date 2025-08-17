import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../models/employee_details_model.dart';
import '../models/employee_model.dart';
import '../models/financial_details_model.dart';
import '../models/financial_dues_model.dart';
import '../models/qr_generation_model.dart';
import '../models/working_times_model.dart';

class EmployeeDatasource {
  final ApiConsumer api;

  EmployeeDatasource({required this.api});

  // create or edit employee
  Future<Map<String, dynamic>> creatEmployee({
    String? employeeId,
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
        employeeId != null ? EndPoints.editEmployee : EndPoints.createEmployee,
        data: {
          if (employeeId != null) 'employee_id': employeeId,
          'name': name,
          'email': email,
          'phone': phone,
          'sub_phone': subPhone,
          if (employeeId == null) 'password': password,
          if (employeeId == null) 'password_confirmation': passwordConfirmation,
          'hour_work_price': hourWorkPrice,
          'overtime_work_price': overtimeWorkPrice,
          'number_of_work_hours': numberOfWorkHours,
          'start_work_time': startWorkTime,
          if (employeeImg != null && employeeImg.path.contains('http://'))
            'employee_img': employeeImg.path,
          if (employeeImg != null && !employeeImg.path.contains('http://'))
            'employee_img': await MultipartFile.fromFile(
              employeeImg.path,
              filename: employeeImg.name,
            ),
          if (employeeImg == null) 'employee_img': '',
          if (documentImg != null && documentImg.path.contains('http://'))
            'document_img': documentImg.path,
          if (documentImg != null && !documentImg.path.contains('http://'))
            'document_img': await MultipartFile.fromFile(
              documentImg.path,
              filename: documentImg.name,
            ),
          if (employeeImg == null) 'document_img': '',
          'permissions[]': permissions,
        },
        isFormData: true,
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

  // get all employees
  Future<List<EmployeeModel>> getEmployees() async {
    try {
      final response = await api.get(EndPoints.employees);
      List<EmployeeModel> employees = (response.data['employees'] as List)
          .map((e) => EmployeeModel.fromJson(e))
          .toList();
      return employees;
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

  // get Working Times
  Future<List<WorkingTimesModel>> getWorkingTimes() async {
    try {
      final response = await api.get(EndPoints.workingTimes);
      List<WorkingTimesModel> employees =
          (response.data[ApiKey.working_times] as List)
              .map((e) => WorkingTimesModel.fromJson(e))
              .toList();
      return employees;
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

  // get Financial Dues
  Future<List<FinancialDuesModel>> getFinancialDues() async {
    try {
      final response = await api.get(EndPoints.financialDues);
      List<FinancialDuesModel> employees =
          (response.data[ApiKey.financial_dues] as List)
              .map((e) => FinancialDuesModel.fromJson(e))
              .toList();
      return employees;
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

  // get Financial Details
  Future<FinancialDetailsModel> getfinancialDetails({
    required String employeeId,
  }) async {
    try {
      final response =
          await api.post(EndPoints.employeeFinancialDetails, data: {
        'employee_id': employeeId,
      });
      final employee = FinancialDetailsModel.fromJson(
        response.data[ApiKey.financial_details] as Map<String, dynamic>,
      );
      return employee;
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

  // get Employee Details
  Future<EmployeeDetailsModel> getEmployeeDetails({
    required String employeeId,
  }) async {
    try {
      final response = await api.post(EndPoints.employeePermissions, data: {
        'employee_id': employeeId,
      });
      final employee =
          EmployeeDetailsModel.fromJson(response.data as Map<String, dynamic>);
      return employee;
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

  // generate QR code
  Future<QrGenerationModel> qrGeneration() async {
    try {
      final response = await api.get(EndPoints.qrGeneration);
      final employee =
          QrGenerationModel.fromJson(response.data as Map<String, dynamic>);
      return employee;
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

  // scan QR code
  Future<Map<String, dynamic>> qrScan({required String qrData}) async {
    try {
      final response =
          await api.post(EndPoints.qrScan, data: {'qr_data': qrData});
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
