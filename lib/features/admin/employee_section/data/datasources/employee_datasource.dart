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
import '../models/employee_advances_model.dart';
import '../models/employee_model.dart';
import '../models/financial_details_model.dart';
import '../models/financial_dues_model.dart';
import '../models/logs_model.dart';
import '../models/overtime_and_loan_model.dart';
import '../models/qr_generation_model.dart';
import '../models/attendance_report_model.dart';
import '../models/employee_attendance_history_model.dart';
import '../models/employee_points_log_model.dart';
import '../models/employee_reward_rule_model.dart';
import '../models/qr_history_model.dart';
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
    required List<String> weeklyDaysOff,
    required bool fingerprintEnabled,
    String? deviceUserId,
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
          'fingerprint_enabled': fingerprintEnabled ? 1 : 0,
          if (deviceUserId != null && deviceUserId.trim().isNotEmpty)
            'device_user_id': deviceUserId.trim(),
          ...employeeImgList,
          ...documentsImageList,
          'permissions[]': permissions,
          if (weeklyDaysOff.isNotEmpty)
            '${ApiKey.weekly_days_off}[]': weeklyDaysOff,
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

  // soft delete an employee
  Future<Map<String, dynamic>> deleteEmployee({
    required String employeeId,
  }) async {
    try {
      final response = await api.post(
        EndPoints.deleteEmployee,
        data: {
          'employee_id': employeeId,
        },
        isFormData: true,
      );
      final data = response.data;
      return data;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    }
  }

  // get all employees
  Future<Map<String, dynamic>> impersonateEmployee(int employeeId) async {
    try {
      final response = await api.post(
        EndPoints.adminImpersonateEmployee(employeeId),
      );
      final data = response.data;
      Map<String, dynamic> map;
      if (data is Map<String, dynamic>) {
        map = data;
      } else if (data is Map) {
        map = Map<String, dynamic>.from(data);
      } else {
        throw ServerException(
          ErrorModel(
            errorMessage: 'Invalid response',
            status: 500,
            data: {},
          ),
        );
      }
      if (map['status']?.toString() != 'success') {
        throw ServerException(
          ErrorModel(
            errorMessage: map['message']?.toString() ?? 'impersonationFailed',
            status: map['status'] ?? 'error',
            data: map['data'] is Map ? map['data'] : {},
          ),
        );
      }
      return map;
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 500;
      final raw = e.response?.data;
      String message = 'فشل الدخول كموظف';
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.response == null) {
        message =
            'تعذر الاتصال بالسيرفر. تأكد أن Laragon يعمل وأن رابط API في التطبيق صحيح، ثم أعد المحاولة.';
      } else if (code == 404) {
        message =
            'مسار الدخول كموظف غير منشور على السيرفر. انشر آخر نسخة من routes/api.php و AdminImpersonationController.php.';
      } else if (code == 503 || code == 502 || code == 504) {
        message =
            'السيرفر غير متاح حالياً. تحقق من Laragon/الاستضافة ثم أعد المحاولة.';
      } else if (raw is Map && raw['message'] != null) {
        message = raw['message'].toString();
      }
      throw ServerException(
        ErrorModel(
          errorMessage: message,
          status: raw is Map ? (raw['status'] ?? code) : code,
          data: raw is Map ? (raw['data'] ?? {}) : {},
        ),
      );
    }
  }

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
    String? month,
    String? date,
  }) async {
    try {
      final response =
          await api.post(EndPoints.employeeFinancialDetails, data: {
        'employee_id': employeeId,
        if (month != null && month.isNotEmpty) 'month': month,
        if (date != null && date.isNotEmpty) 'date': date,
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

  Future<EmployeeAdvancesResult> getEmployeeAdvances({
    required int employeeId,
    required String month,
  }) async {
    try {
      final response = await api.get(
        EndPoints.employeeAdvances(employeeId),
        queryParameters: {'month': month},
      );
      return EmployeeAdvancesResult.fromJson(asMap(response.data));
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
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
      if (raw is Map && raw['status']?.toString() != 'success') {
        throw ServerException(
          ErrorModel(
            errorMessage: raw['message']?.toString() ?? 'Unknown error',
            status: raw['status'] ?? 500,
            data: raw['data'] ?? {},
          ),
        );
      }
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
      // Add a cache-busting query param so we always fetch a fresh QR
      final response = await api.get(
        EndPoints.qrGeneration,
        queryParameters: {'t': DateTime.now().millisecondsSinceEpoch},
      );
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

  Future<Map<String, dynamic>> manualEmployeeCheckout({
    required String employeeId,
  }) async {
    try {
      final response = await api.post(
        EndPoints.adminEmployeeManualCheckout(employeeId),
        data: const {},
      );
      return asMap(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    }
  }

  Future<Map<String, dynamic>> updateEmployeeAttendanceDay({
    required String employeeId,
    required String workDate,
    required DateTime checkInAt,
    DateTime? checkOutAt,
  }) async {
    try {
      final response = await api.put(
        EndPoints.adminEmployeeUpdateAttendanceDay(employeeId),
        data: {
          'work_date': workDate,
          'check_in_at': checkInAt.toIso8601String(),
          if (checkOutAt != null) 'check_out_at': checkOutAt.toIso8601String(),
        },
      );
      return asMap(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceOvertimeRequests({
    String status = 'pending',
  }) async {
    try {
      final response = await api.get(
        EndPoints.attendanceOvertimeRequests,
        queryParameters: {'status': status},
      );
      final data = asMap(response.data);
      final list = data['requests'];
      if (list is List) {
        return list
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    }
  }

  Future<Map<String, dynamic>> reviewAttendanceOvertimeRequest({
    required int requestId,
    required bool approve,
    int? approvedMinutes,
    String? adminNote,
  }) async {
    try {
      final endpoint = approve
          ? EndPoints.approveAttendanceOvertimeRequest(requestId)
          : EndPoints.rejectAttendanceOvertimeRequest(requestId);
      final response = await api.post(
        endpoint,
        data: {
          if (approvedMinutes != null) 'approved_minutes': approvedMinutes,
          if (adminNote != null && adminNote.isNotEmpty) 'admin_note': adminNote,
        },
      );
      return asMap(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    }
  }

  Future<EmployeeAttendanceHistoryResult> getEmployeeAttendanceHistory({
    required String employeeId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      String? fmt(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final response = await api.get(
        EndPoints.employeeAttendanceHistory,
        queryParameters: {
          'employee_id': employeeId,
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
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    }
  }

  Future<AttendanceReportResult> getAttendanceReport({
    required String reportType,
    required int month,
    required int year,
    int? day,
    int? week,
    List<int> employeeIds = const [],
  }) async {
    try {
      final parts = <String>[
        'report_type=${Uri.encodeQueryComponent(reportType)}',
        'month=$month',
        'year=$year',
      ];
      if (day != null) {
        parts.add('day=$day');
      }
      if (week != null) {
        parts.add('week=$week');
      }
      for (final id in employeeIds) {
        parts.add('employee_ids[]=$id');
      }

      final path = '${EndPoints.employeeAttendanceReports}?${parts.join('&')}';
      final response = await api.get(path);
      return AttendanceReportResult.fromApiJson(asMap(response.data));
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    }
  }

  Future<QrHistoryResult> qrHistory({int page = 1, int perPage = 20}) async {
    try {
      final response = await api.get(
        EndPoints.qrHistory,
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );
      final raw = response.data;
      return QrHistoryResult.fromJson(asMap(raw));
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    } catch (e) {
      throw ServerException(
        ErrorModel(
          errorMessage: e.toString(),
          status: 500,
          data: {},
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

  // ========================================================================
  // Employee Points & Rewards APIs
  // ========================================================================

  /// Persist a new positive/negative points log row for the given employee.
  ///
  /// When [categoryId] is provided the backend resolves the operation type
  /// and default points from the configured point category, so [points] +
  /// [category] become optional overrides.
  Future<Map<String, dynamic>> mutateEmployeePoints({
    required int employeeId,
    required bool isAdd,
    int? points,
    String? category,
    int? categoryId,
    String? reason,
    String? notes,
    String? pointsDate,
  }) async {
    try {
      final response = await api.post(
        isAdd
            ? EndPoints.employeePointsAdd(employeeId)
            : EndPoints.employeePointsDeduct(employeeId),
        data: {
          if (points != null) 'points': points,
          if (category != null && category.isNotEmpty) 'category': category,
          if (categoryId != null) 'category_id': categoryId,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (pointsDate != null && pointsDate.isNotEmpty)
            'points_date': pointsDate,
        },
      );
      final data = response.data;
      return data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data as Map);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    }
  }

  Future<EmployeePointsLogsPage> getEmployeePointsLogs({
    required int employeeId,
    int? month,
    int? year,
    String? category,
    String? operationType,
    int perPage = 50,
    int page = 1,
  }) async {
    try {
      final response = await api.get(
        EndPoints.employeePointsLogs(employeeId),
        queryParameters: {
          if (month != null) 'month': month,
          if (year != null) 'year': year,
          if (category != null && category.isNotEmpty) 'category': category,
          if (operationType != null && operationType.isNotEmpty)
            'operation_type': operationType,
          'per_page': perPage,
          'page': page,
        },
      );
      final raw = response.data;
      return EmployeePointsLogsPage.fromJson(asMap(raw));
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    }
  }

  Future<EmployeePointsMonthlySummaryModel> getEmployeePointsMonthlySummary({
    required int employeeId,
    int? month,
    int? year,
  }) async {
    try {
      final response = await api.get(
        EndPoints.employeePointsMonthlySummary(employeeId),
        queryParameters: {
          if (month != null) 'month': month,
          if (year != null) 'year': year,
        },
      );
      return EmployeePointsMonthlySummaryModel.fromJson(asMap(response.data));
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    }
  }

  Future<EmployeePointsCategoriesModel> getEmployeePointsCategories() async {
    try {
      final response = await api.get(EndPoints.employeePointsCategories);
      return EmployeePointsCategoriesModel.fromJson(asMap(response.data));
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    }
  }

  Future<List<EmployeeRewardRuleModel>> getEmployeeRewardRules({
    bool? isActive,
  }) async {
    try {
      final response = await api.get(
        EndPoints.employeeRewardRules,
        queryParameters: {
          if (isActive != null) 'is_active': isActive ? 1 : 0,
        },
      );
      return mapListFromResponseKey(
        response.data,
        'rules',
        (Map<String, dynamic> m) => EmployeeRewardRuleModel.fromJson(m),
        debugScope: 'EmployeeDatasource.getEmployeeRewardRules',
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    }
  }

  Future<Map<String, dynamic>> createEmployeeRewardRule({
    required int minPoints,
    int? maxPoints,
    required double rewardAmount,
    required bool isActive,
    String? statusLabel,
    String? statusColor,
  }) async {
    try {
      final response = await api.post(
        EndPoints.employeeRewardRules,
        data: {
          'min_points': minPoints,
          if (maxPoints != null) 'max_points': maxPoints,
          'reward_amount': rewardAmount,
          if (statusLabel != null && statusLabel.isNotEmpty)
            'status_label': statusLabel,
          if (statusColor != null && statusColor.isNotEmpty)
            'status_color': statusColor,
          'is_active': isActive ? 1 : 0,
        },
      );
      final data = response.data;
      return data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data as Map);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    }
  }

  Future<Map<String, dynamic>> updateEmployeeRewardRule({
    required int id,
    int? minPoints,
    int? maxPoints,
    bool clearMaxPoints = false,
    double? rewardAmount,
    String? statusLabel,
    String? statusColor,
    bool clearStatusFields = false,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (minPoints != null) body['min_points'] = minPoints;
      if (clearMaxPoints) {
        body['max_points'] = null;
      } else if (maxPoints != null) {
        body['max_points'] = maxPoints;
      }
      if (rewardAmount != null) body['reward_amount'] = rewardAmount;
      if (clearStatusFields) {
        body['status_label'] = null;
        body['status_color'] = null;
      } else {
        if (statusLabel != null) body['status_label'] = statusLabel;
        if (statusColor != null) body['status_color'] = statusColor;
      }
      if (isActive != null) body['is_active'] = isActive ? 1 : 0;

      final response = await api.put(
        EndPoints.employeeRewardRule(id),
        data: body,
      );
      final data = response.data;
      return data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data as Map);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    }
  }

  Future<Map<String, dynamic>> deleteEmployeeRewardRule({
    required int id,
  }) async {
    try {
      final response = await api.delete(EndPoints.employeeRewardRule(id));
      final data = response.data;
      return data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data as Map);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    }
  }

  // ========================================================================
  // Configurable point categories CRUD (admin defines behaviors)
  // ========================================================================

  Future<List<EmployeePointCategoryModel>> getEmployeePointCategories({
    String? operationType,
    bool? isActive,
  }) async {
    try {
      final response = await api.get(
        EndPoints.employeePointCategories,
        queryParameters: {
          if (operationType != null && operationType.isNotEmpty)
            'operation_type': operationType,
          if (isActive != null) 'is_active': isActive ? 1 : 0,
        },
      );
      return mapListFromResponseKey(
        response.data,
        'categories',
        (Map<String, dynamic> m) => EmployeePointCategoryModel.fromJson(m),
        debugScope: 'EmployeeDatasource.getEmployeePointCategories',
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    }
  }

  Future<Map<String, dynamic>> createEmployeePointCategory({
    required String nameAr,
    String? nameEn,
    required String code,
    required String operationType,
    required int defaultPoints,
    bool isActive = true,
    int sortOrder = 0,
  }) async {
    try {
      final response = await api.post(
        EndPoints.employeePointCategories,
        data: {
          'name_ar': nameAr,
          if (nameEn != null && nameEn.isNotEmpty) 'name_en': nameEn,
          'code': code,
          'operation_type': operationType,
          'default_points': defaultPoints,
          'is_active': isActive ? 1 : 0,
          'sort_order': sortOrder,
        },
      );
      final data = response.data;
      return data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data as Map);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    }
  }

  Future<Map<String, dynamic>> updateEmployeePointCategory({
    required int id,
    String? nameAr,
    String? nameEn,
    String? code,
    String? operationType,
    int? defaultPoints,
    bool? isActive,
    int? sortOrder,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (nameAr != null) body['name_ar'] = nameAr;
      if (nameEn != null) body['name_en'] = nameEn;
      if (code != null) body['code'] = code;
      if (operationType != null) body['operation_type'] = operationType;
      if (defaultPoints != null) body['default_points'] = defaultPoints;
      if (isActive != null) body['is_active'] = isActive ? 1 : 0;
      if (sortOrder != null) body['sort_order'] = sortOrder;

      final response = await api.put(
        EndPoints.employeePointCategory(id),
        data: body,
      );
      final data = response.data;
      return data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data as Map);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    }
  }

  Future<Map<String, dynamic>> deleteEmployeePointCategory({
    required int id,
  }) async {
    try {
      final response = await api.delete(EndPoints.employeePointCategory(id));
      final data = response.data;
      return data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data as Map);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    }
  }

  // ========================================================================
  // Global points: list + report
  // ========================================================================

  Future<List<EmployeePointsRowModel>> getGlobalEmployeesPoints({
    int? month,
    int? year,
    String? search,
  }) async {
    try {
      final response = await api.get(
        EndPoints.globalEmployeePoints,
        queryParameters: {
          if (month != null) 'month': month,
          if (year != null) 'year': year,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      return mapListFromResponseKey(
        response.data,
        'employees',
        (Map<String, dynamic> m) => EmployeePointsRowModel.fromJson(m),
        debugScope: 'EmployeeDatasource.getGlobalEmployeesPoints',
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
        ),
      );
    }
  }

  Future<EmployeePointsReportModel> getGlobalPointsReport({
    int? month,
    int? year,
    List<int>? employeeIds,
    String? operationType,
    int? categoryId,
    bool includeLogs = false,
  }) async {
    try {
      final response = await api.get(
        EndPoints.globalPointsReport,
        queryParameters: {
          if (month != null) 'month': month,
          if (year != null) 'year': year,
          if (employeeIds != null && employeeIds.isNotEmpty)
            'employee_ids[]': employeeIds,
          if (operationType != null && operationType.isNotEmpty)
            'operation_type': operationType,
          if (categoryId != null) 'category_id': categoryId,
          'include_logs': includeLogs ? 1 : 0,
        },
      );
      return EmployeePointsReportModel.fromJson(asMap(response.data));
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data is Map
              ? (data['message'] ?? 'Unknown error')
              : 'Unknown error',
          status: data is Map ? (data['status'] ?? 500) : 500,
          data: data is Map ? (data['data'] ?? {}) : {},
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
