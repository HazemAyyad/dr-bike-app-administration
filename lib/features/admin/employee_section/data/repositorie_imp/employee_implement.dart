import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:doctorbike/features/admin/employee_section/data/models/employee_details_model.dart';
import 'package:doctorbike/features/admin/employee_section/data/models/financial_details_model.dart';
import 'package:doctorbike/features/admin/employee_section/data/models/financial_dues_model.dart';
import 'package:doctorbike/features/admin/employee_section/data/models/overtime_and_loan_model.dart';
import 'package:doctorbike/features/admin/employee_section/data/models/qr_generation_model.dart';
import 'package:doctorbike/features/admin/employee_section/data/models/attendance_report_model.dart';
import 'package:doctorbike/features/admin/employee_section/data/models/employee_attendance_history_model.dart';
import 'package:doctorbike/features/admin/employee_section/data/models/employee_points_log_model.dart';
import 'package:doctorbike/features/admin/employee_section/data/models/employee_reward_rule_model.dart';
import 'package:doctorbike/features/admin/employee_section/data/models/qr_history_model.dart';
import 'package:doctorbike/features/admin/employee_section/data/models/working_times_model.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../domain/repositories/employee_section_repository.dart';
import '../datasources/employee_datasource.dart';
import '../models/employee_model.dart';
import '../models/logs_model.dart';

class EmployeeImplement implements EmployeeRepository {
  final NetworkInfo networkInfo;
  final EmployeeDatasource employeeDatasource;

  EmployeeImplement(
      {required this.networkInfo, required this.employeeDatasource});

  // creat new employee
  @override
  Future<Either<Failure, String>> creatEmployee({
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
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await employeeDatasource.creatEmployee(
        employeeId: employeeId,
        name: name,
        email: email,
        phone: phone,
        subPhone: subPhone,
        password: password,
        passwordConfirmation: passwordConfirmation,
        hourWorkPrice: hourWorkPrice,
        overtimeWorkPrice: overtimeWorkPrice,
        numberOfWorkHours: numberOfWorkHours,
        startWorkTime: startWorkTime,
        documentImg: documentImg,
        employeeImg: employeeImg,
        permissions: permissions,
        weeklyDaysOff: weeklyDaysOff,
      );
      if (result['status'] == 'success') {
        return Right(result['message']!);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  // add points or minus points
  @override
  Future<Either<Failure, String>> addPointsToEmployee({
    required String employeeId,
    required String points,
    required String notes,
    required bool isAdd,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await employeeDatasource.addPointsToEmployee(
        employeeId: employeeId,
        points: points,
        notes: notes,
        isAdd: isAdd,
      );
      if (result['status'] == 'success') {
        return Right(result['message']);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  // pay salary to employee
  @override
  Future<Either<Failure, String>> paySalaryToEmployeeUsecase({
    required String employeeId,
    required String salary,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await employeeDatasource.paySalaryToEmployeeUsecase(
        employeeId: employeeId,
        salary: salary,
      );
      if (result['status'] == 'success') {
        return Right(result['message']);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  // soft delete an employee
  @override
  Future<Either<Failure, String>> deleteEmployee({
    required String employeeId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await employeeDatasource.deleteEmployee(
        employeeId: employeeId,
      );
      if (result['status'] == 'success') {
        return Right(result['message'] ?? '');
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  // get all employees
  @override
  Future<List<EmployeeModel>> getEmployees() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await employeeDatasource.getEmployees();

        return result;
      } on ServerException catch (e) {
        throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
      }
    } else {
      throw ServerFailure('No internet connection', {});
    }
  }

  // get Working Times
  @override
  Future<List<WorkingTimesModel>> getWorkingTimes() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await employeeDatasource.getWorkingTimes();

        return result;
      } on ServerException catch (e) {
        throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
      }
    } else {
      throw ServerFailure('No internet connection', {});
    }
  }

  // get Financial Dues
  @override
  Future<List<FinancialDuesModel>> getFinancialDues() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await employeeDatasource.getFinancialDues();

        return result;
      } on ServerException catch (e) {
        throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
      }
    } else {
      throw ServerFailure('No internet connection', {});
    }
  }

  // get financial details
  @override
  Future<FinancialDetailsModel> getfinancialDetails(
      {required String employeeId}) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await employeeDatasource.getfinancialDetails(
          employeeId: employeeId,
        );

        return result;
      } on ServerException catch (e) {
        throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
      }
    } else {
      throw ServerFailure('No internet connection', {});
    }
  }

  // get employee details
  @override
  Future<EmployeeDetailsModel> getEmployeeDetails(
      {required String employeeId}) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await employeeDatasource.getEmployeeDetails(
          employeeId: employeeId,
        );

        return result;
      } on ServerException catch (e) {
        throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
      }
    } else {
      throw ServerFailure('No internet connection', {});
    }
  }

  // generate QR code
  @override
  Future<QrGenerationModel> qrGeneration() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await employeeDatasource.qrGeneration();

        return result;
      } on ServerException catch (e) {
        throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
      }
    } else {
      throw ServerFailure('No internet connection', {});
    }
  }

  @override
  Future<QrHistoryResult> qrHistory({int page = 1, int perPage = 20}) async {
    if (await networkInfo.isConnected) {
      try {
        return await employeeDatasource.qrHistory(page: page, perPage: perPage);
      } on ServerException catch (e) {
        throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
      }
    } else {
      throw ServerFailure('No internet connection', {});
    }
  }

  @override
  Future<EmployeeAttendanceHistoryResult> getEmployeeAttendanceHistory({
    required String employeeId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        return await employeeDatasource.getEmployeeAttendanceHistory(
          employeeId: employeeId,
          fromDate: fromDate,
          toDate: toDate,
        );
      } on ServerException catch (e) {
        throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
      }
    } else {
      throw ServerFailure('No internet connection', {});
    }
  }

  @override
  Future<AttendanceReportResult> getAttendanceReport({
    required String reportType,
    required int month,
    required int year,
    int? day,
    int? week,
    List<int>? employeeIds,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        return await employeeDatasource.getAttendanceReport(
          reportType: reportType,
          month: month,
          year: year,
          day: day,
          week: week,
          employeeIds: employeeIds ?? const [],
        );
      } on ServerException catch (e) {
        throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
      } on FormatException catch (e) {
        throw ServerFailure(e.message, {});
      }
    } else {
      throw ServerFailure('No internet connection', {});
    }
  }

  @override
  Future<List<OvertimeAndLoanModel>> getOvertimeAndLoan({
    required bool isOvertime,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await employeeDatasource.getOvertimeAndLoan(
          isOvertime: isOvertime,
        );

        return result;
      } on ServerException catch (e) {
        throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
      }
    } else {
      throw ServerFailure('No internet connection', {});
    }
  }

  // reject employee order
  @override
  Future<Either<Failure, String>> rejectEmployeeOrder({
    required String employeeOrderId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await employeeDatasource.rejectEmployeeOrder(
        employeeOrderId: employeeOrderId,
      );
      if (result['status'] == 'success') {
        return Right(result['message']);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  // approve employee order
  @override
  Future<Either<Failure, String>> approveEmployeeOrder({
    required String employeeOrderId,
    required String overtimeValue,
    required String loanValue,
    required String extraWorkHoursValue,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await employeeDatasource.approveEmployeeOrder(
        employeeOrderId: employeeOrderId,
        overtimeValue: overtimeValue,
        loanValue: loanValue,
        extraWorkHoursValue: extraWorkHoursValue,
      );
      if (result['status'] == 'success') {
        return Right(result['message']);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  // get logs
  @override
  Future<List<LogsModel>> getLogs() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await employeeDatasource.getLogs();

        return result;
      } on ServerException catch (e) {
        throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
      }
    } else {
      throw ServerFailure('No internet connection', {});
    }
  }

  // ========================================================================
  // Employee Points & Rewards
  // ========================================================================

  @override
  Future<Either<Failure, EmployeePointsLogModel>> mutateEmployeePoints({
    required int employeeId,
    required bool isAdd,
    int? points,
    String? category,
    int? categoryId,
    String? reason,
    String? notes,
    String? pointsDate,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await employeeDatasource.mutateEmployeePoints(
        employeeId: employeeId,
        isAdd: isAdd,
        points: points,
        category: category,
        categoryId: categoryId,
        reason: reason,
        notes: notes,
        pointsDate: pointsDate,
      );
      if (result['status'] == 'success') {
        final logRaw = result['log'];
        if (logRaw is Map) {
          return Right(
            EmployeePointsLogModel.fromJson(
              Map<String, dynamic>.from(logRaw),
            ),
          );
        }
        return Left(
          ValidationFailure(result['message'] ?? 'Unknown error', result),
        );
      }
      return Left(
        ValidationFailure(result['message'] ?? 'Unknown error', result),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<EmployeePointsLogsPage> getEmployeePointsLogs({
    required int employeeId,
    int? month,
    int? year,
    String? category,
    String? operationType,
    int perPage = 50,
    int page = 1,
  }) async {
    if (!await networkInfo.isConnected) {
      throw ServerFailure('No internet connection', {});
    }
    try {
      return await employeeDatasource.getEmployeePointsLogs(
        employeeId: employeeId,
        month: month,
        year: year,
        category: category,
        operationType: operationType,
        perPage: perPage,
        page: page,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<EmployeePointsMonthlySummaryModel> getEmployeePointsMonthlySummary({
    required int employeeId,
    int? month,
    int? year,
  }) async {
    if (!await networkInfo.isConnected) {
      throw ServerFailure('No internet connection', {});
    }
    try {
      return await employeeDatasource.getEmployeePointsMonthlySummary(
        employeeId: employeeId,
        month: month,
        year: year,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<EmployeePointsCategoriesModel> getEmployeePointsCategories() async {
    if (!await networkInfo.isConnected) {
      throw ServerFailure('No internet connection', {});
    }
    try {
      return await employeeDatasource.getEmployeePointsCategories();
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<List<EmployeeRewardRuleModel>> getEmployeeRewardRules({
    bool? isActive,
  }) async {
    if (!await networkInfo.isConnected) {
      throw ServerFailure('No internet connection', {});
    }
    try {
      return await employeeDatasource.getEmployeeRewardRules(
        isActive: isActive,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<Either<Failure, EmployeeRewardRuleModel>> createEmployeeRewardRule({
    required int minPoints,
    int? maxPoints,
    required double rewardAmount,
    required bool isActive,
    String? statusLabel,
    String? statusColor,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await employeeDatasource.createEmployeeRewardRule(
        minPoints: minPoints,
        maxPoints: maxPoints,
        rewardAmount: rewardAmount,
        isActive: isActive,
        statusLabel: statusLabel,
        statusColor: statusColor,
      );
      if (result['status'] == 'success') {
        final ruleRaw = result['rule'];
        if (ruleRaw is Map) {
          return Right(
            EmployeeRewardRuleModel.fromJson(
              Map<String, dynamic>.from(ruleRaw),
            ),
          );
        }
      }
      return Left(
        ValidationFailure(result['message'] ?? 'Unknown error', result),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, EmployeeRewardRuleModel>> updateEmployeeRewardRule({
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
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await employeeDatasource.updateEmployeeRewardRule(
        id: id,
        minPoints: minPoints,
        maxPoints: maxPoints,
        clearMaxPoints: clearMaxPoints,
        rewardAmount: rewardAmount,
        statusLabel: statusLabel,
        statusColor: statusColor,
        clearStatusFields: clearStatusFields,
        isActive: isActive,
      );
      if (result['status'] == 'success') {
        final ruleRaw = result['rule'];
        if (ruleRaw is Map) {
          return Right(
            EmployeeRewardRuleModel.fromJson(
              Map<String, dynamic>.from(ruleRaw),
            ),
          );
        }
      }
      return Left(
        ValidationFailure(result['message'] ?? 'Unknown error', result),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, String>> deleteEmployeeRewardRule({
    required int id,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await employeeDatasource.deleteEmployeeRewardRule(id: id);
      if (result['status'] == 'success') {
        return Right(result['message']?.toString() ?? '');
      }
      return Left(
        ValidationFailure(result['message'] ?? 'Unknown error', result),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  // ========================================================================
  // Point Categories (configurable behaviors with default values)
  // ========================================================================

  @override
  Future<List<EmployeePointCategoryModel>> getEmployeePointCategories({
    String? operationType,
    bool? isActive,
  }) async {
    if (!await networkInfo.isConnected) {
      throw ServerFailure('No internet connection', {});
    }
    try {
      return await employeeDatasource.getEmployeePointCategories(
        operationType: operationType,
        isActive: isActive,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<Either<Failure, EmployeePointCategoryModel>>
      createEmployeePointCategory({
    required String nameAr,
    String? nameEn,
    required String code,
    required String operationType,
    required int defaultPoints,
    bool isActive = true,
    int sortOrder = 0,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await employeeDatasource.createEmployeePointCategory(
        nameAr: nameAr,
        nameEn: nameEn,
        code: code,
        operationType: operationType,
        defaultPoints: defaultPoints,
        isActive: isActive,
        sortOrder: sortOrder,
      );
      if (result['status'] == 'success') {
        final catRaw = result['category'];
        if (catRaw is Map) {
          return Right(
            EmployeePointCategoryModel.fromJson(
              Map<String, dynamic>.from(catRaw),
            ),
          );
        }
      }
      return Left(
        ValidationFailure(result['message'] ?? 'Unknown error', result),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, EmployeePointCategoryModel>>
      updateEmployeePointCategory({
    required int id,
    String? nameAr,
    String? nameEn,
    String? code,
    String? operationType,
    int? defaultPoints,
    bool? isActive,
    int? sortOrder,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await employeeDatasource.updateEmployeePointCategory(
        id: id,
        nameAr: nameAr,
        nameEn: nameEn,
        code: code,
        operationType: operationType,
        defaultPoints: defaultPoints,
        isActive: isActive,
        sortOrder: sortOrder,
      );
      if (result['status'] == 'success') {
        final catRaw = result['category'];
        if (catRaw is Map) {
          return Right(
            EmployeePointCategoryModel.fromJson(
              Map<String, dynamic>.from(catRaw),
            ),
          );
        }
      }
      return Left(
        ValidationFailure(result['message'] ?? 'Unknown error', result),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, String>> deleteEmployeePointCategory({
    required int id,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await employeeDatasource.deleteEmployeePointCategory(
        id: id,
      );
      if (result['status'] == 'success') {
        return Right(result['message']?.toString() ?? '');
      }
      return Left(
        ValidationFailure(result['message'] ?? 'Unknown error', result),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  // ========================================================================
  // Global points list + reports
  // ========================================================================

  @override
  Future<List<EmployeePointsRowModel>> getGlobalEmployeesPoints({
    int? month,
    int? year,
    String? search,
  }) async {
    if (!await networkInfo.isConnected) {
      throw ServerFailure('No internet connection', {});
    }
    try {
      return await employeeDatasource.getGlobalEmployeesPoints(
        month: month,
        year: year,
        search: search,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<EmployeePointsReportModel> getGlobalPointsReport({
    int? month,
    int? year,
    List<int>? employeeIds,
    String? operationType,
    int? categoryId,
    bool includeLogs = false,
  }) async {
    if (!await networkInfo.isConnected) {
      throw ServerFailure('No internet connection', {});
    }
    try {
      return await employeeDatasource.getGlobalPointsReport(
        month: month,
        year: year,
        employeeIds: employeeIds,
        operationType: operationType,
        categoryId: categoryId,
        includeLogs: includeLogs,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  // cancel log
  @override
  Future<Either<Failure, String>> cancelLog({required String logId}) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await employeeDatasource.cancelLog(
        logId: logId,
      );
      if (result['status'] == 'success') {
        return Right(result['message']);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }
}
