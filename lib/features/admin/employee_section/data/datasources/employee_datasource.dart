import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/helpers/json_safe_parser.dart';
import '../../../checks/data/datasources/checks_datasource.dart';
import '../models/employee_details_model.dart';
import '../models/employee_model.dart';
import '../models/financial_details_model.dart';
import '../models/financial_dues_model.dart';
import '../models/logs_model.dart';
import '../models/overtime_and_loan_model.dart';
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
    required List<File> documentImg,
    required List<File> employeeImg,
    required List<String> permissions,
  }) async {
    try {
      Map<String, dynamic> documentsImageList = {};

      documentsImageList['document_img[]'] = await Future.wait(
        documentImg.map((e) async {
          if (e.path.startsWith('http://') || e.path.startsWith('https://')) {
            // صورة جاية من السيرفر → رجعها كـ string
            return e.path;
          } else {
            // صورة محلية → حولها لـ MultipartFile
            final compressedImg = await compressImage(XFile(e.path));
            return await MultipartFile.fromFile(
              compressedImg.path,
              filename: compressedImg.path.split('/').last,
            );
          }
        }),
      );

      Map<String, dynamic> employeeImgList = {};
      // لو الصور جايه لينكات من الـ API (يعني فيها http)
      employeeImgList['employee_img[]'] = await Future.wait(
        employeeImg.map((e) async {
          if (e.path.startsWith('http://') || e.path.startsWith('https://')) {
            // صورة جاية من السيرفر → رجعها كـ string
            return e.path;
          } else {
            final compressedImg = await compressImage(XFile(e.path));

            // صورة محلية → حولها لـ MultipartFile
            return await MultipartFile.fromFile(
              compressedImg.path,
              filename: compressedImg.path.split('/').last,
            );
          }
        }),
      );
      final response = await api.post(
        employeeId != null ? EndPoints.editEmployee : EndPoints.createEmployee,
        data: {
          if (employeeId != null) 'employee_id': employeeId,
          'name': name,
          'email': email,
          'phone': phone,
          if (subPhone != '+972 ' && subPhone != '+970 ') 'sub_phone': subPhone,
          if (employeeId == null) 'password': password,
          if (employeeId == null) 'password_confirmation': passwordConfirmation,
          'hour_work_price': hourWorkPrice,
          'overtime_work_price': overtimeWorkPrice,
          'number_of_work_hours': numberOfWorkHours,
          'start_work_time': startWorkTime,
          ...employeeImgList,
          ...documentsImageList,
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
    required String notes,
  }) async {
    try {
      final response = await api.post(
        isAdd
            ? EndPoints.addPointsToEmployee
            : EndPoints.minusPointsFromEmployee,
        data: {
          'employee_id': employeeId,
          'points': points,
          'notes': notes,
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
      final raw = response.data;
      if (kDebugMode) {
        final sample = extractMapListFromResponse(raw, ApiKey.employees);
        if (sample.isNotEmpty) {
          debugParseLog(
            'EmployeeDatasource.getEmployees',
            'model=EmployeeModel sample=${sample.first}',
          );
        }
      }
      return mapListFromResponseKey(
        raw,
        ApiKey.employees,
        (Map<String, dynamic> m) => EmployeeModel.fromJson(m),
        debugScope: 'EmployeeDatasource.getEmployees',
      );
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
      final raw = response.data;
      if (kDebugMode) {
        final sample = extractMapListFromResponse(raw, ApiKey.working_times);
        if (sample.isNotEmpty) {
          debugParseLog(
            'EmployeeDatasource.getWorkingTimes',
            'model=WorkingTimesModel sample=${sample.first}',
          );
        }
      }
      return mapListFromResponseKey(
        raw,
        ApiKey.working_times,
        (Map<String, dynamic> m) => WorkingTimesModel.fromJson(m),
        debugScope: 'EmployeeDatasource.getWorkingTimes',
      );
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
      final raw = response.data;
      if (kDebugMode) {
        final sample = extractMapListFromResponse(raw, ApiKey.financial_dues);
        if (sample.isNotEmpty) {
          debugParseLog(
            'EmployeeDatasource.getFinancialDues',
            'model=FinancialDuesModel sample=${sample.first}',
          );
        }
      }
      return mapListFromResponseKey(
        raw,
        ApiKey.financial_dues,
        (Map<String, dynamic> m) => FinancialDuesModel.fromJson(m),
        debugScope: 'EmployeeDatasource.getFinancialDues',
      );
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
        asMap(response.data[ApiKey.financial_details]),
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
      final raw = response.data;
      final employee = EmployeeDetailsModel.fromJson(asMap(raw));
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
      final raw = response.data;
      final employee = QrGenerationModel.fromJson(asMap(raw));
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

  // get Overtime And Loan
  Future<List<OvertimeAndLoanModel>> getOvertimeAndLoan({
    required bool isOvertime,
  }) async {
    try {
      final response = await api
          .get(isOvertime ? EndPoints.overtimeOrders : EndPoints.loanOrders);
      final raw = response.data;
      const listKey = 'employee_orders';
      if (kDebugMode) {
        final sample = extractMapListFromResponse(raw, listKey);
        if (sample.isNotEmpty) {
          debugParseLog(
            'EmployeeDatasource.getOvertimeAndLoan',
            'model=OvertimeAndLoanModel isOvertime=$isOvertime sample=${sample.first}',
          );
        }
      }
      return mapListFromResponseKey(
        raw,
        listKey,
        (Map<String, dynamic> m) => OvertimeAndLoanModel.fromJson(m),
        debugScope: 'EmployeeDatasource.getOvertimeAndLoan',
      );
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

  // reject employee order
  Future<Map<String, dynamic>> rejectEmployeeOrder({
    required String employeeOrderId,
  }) async {
    try {
      final response = await api.post(EndPoints.rejectEmployeeOrder, data: {
        'employee_order_id': employeeOrderId,
      });
      final data = response.data;
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

  // approve employee order
  Future<Map<String, dynamic>> approveEmployeeOrder({
    required String employeeOrderId,
    required String overtimeValue,
    required String loanValue,
    required String extraWorkHoursValue,
  }) async {
    try {
      final response = await api.post(
        loanValue.isNotEmpty
            ? EndPoints.approveEmployeeLoanOrder
            : EndPoints.approveEmployeeOvertimeOrder,
        data: {
          'employee_order_id': employeeOrderId,
          if (loanValue.isNotEmpty) 'loan_value': loanValue,
          if (overtimeValue.isNotEmpty) 'overtime_value': overtimeValue,
          if (extraWorkHoursValue.isNotEmpty)
            'extra_work_hours': extraWorkHoursValue,
        },
      );
      final data = response.data;
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

  // get logs
  Future<List<LogsModel>> getLogs() async {
    try {
      final response = await api.get(EndPoints.employeeLogs);
      final raw = response.data;
      if (kDebugMode) {
        final sample = extractMapListFromResponse(raw, 'logs');
        if (sample.isNotEmpty) {
          debugParseLog(
            'EmployeeDatasource.getLogs',
            'model=LogsModel sample=${sample.first}',
          );
        }
      }
      return mapListFromResponseKey(
        raw,
        'logs',
        (Map<String, dynamic> m) => LogsModel.fromJson(m),
        debugScope: 'EmployeeDatasource.getLogs',
      );
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

  // cancel log
  Future<Map<String, dynamic>> cancelLog({required String logId}) async {
    try {
      final response = await api.post(EndPoints.cancelLog, data: {
        'log_id': logId,
      });
      final data = response.data;
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
