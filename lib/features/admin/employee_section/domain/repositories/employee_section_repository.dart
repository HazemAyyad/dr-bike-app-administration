import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:doctorbike/features/admin/employee_section/data/models/financial_details_model.dart';
import '../../../../../core/errors/failure.dart';
import '../../data/models/employee_details_model.dart';
import '../../data/models/financial_dues_model.dart';
import '../../data/models/logs_model.dart';
import '../../data/models/overtime_and_loan_model.dart';
import '../../data/models/qr_generation_model.dart';
import '../../data/models/attendance_report_model.dart';
import '../../data/models/employee_attendance_history_model.dart';
import '../../data/models/employee_points_log_model.dart';
import '../../data/models/employee_reward_rule_model.dart';
import '../../data/models/qr_history_model.dart';
import '../../data/models/working_times_model.dart';
import '../entities/employee_entity.dart';

abstract class EmployeeRepository {
  Future<List<EmployeeEntity>> getEmployees();

  Future<List<WorkingTimesModel>> getWorkingTimes();

  Future<List<FinancialDuesModel>> getFinancialDues();

  Future<FinancialDetailsModel> getfinancialDetails(
      {required String employeeId});

  Future<QrGenerationModel> qrGeneration();
  Future<QrHistoryResult> qrHistory({int page = 1, int perPage = 20});

  Future<EmployeeAttendanceHistoryResult> getEmployeeAttendanceHistory({
    required String employeeId,
    DateTime? fromDate,
    DateTime? toDate,
  });

  Future<AttendanceReportResult> getAttendanceReport({
    required String reportType,
    required int month,
    required int year,
    int? day,
    int? week,
    List<int>? employeeIds,
  });

  Future<EmployeeDetailsModel> getEmployeeDetails({required String employeeId});

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
  });

  Future<Either<Failure, String>> addPointsToEmployee({
    required String employeeId,
    required String points,
    required bool isAdd,
    required String notes,
  });

  Future<Either<Failure, String>> paySalaryToEmployeeUsecase({
    required String employeeId,
    required String salary,
  });

  Future<Either<Failure, String>> deleteEmployee({
    required String employeeId,
  });

  Future<List<OvertimeAndLoanModel>> getOvertimeAndLoan({
    required bool isOvertime,
  });

  Future<Either<Failure, String>> rejectEmployeeOrder({
    required String employeeOrderId,
  });

  Future<Either<Failure, String>> approveEmployeeOrder({
    required String employeeOrderId,
    required String overtimeValue,
    required String loanValue,
    required String extraWorkHoursValue,
  });

  Future<List<LogsModel>> getLogs();

  Future<Either<Failure, String>> cancelLog({required String logId});

  // Employee Points & Rewards
  Future<Either<Failure, EmployeePointsLogModel>> mutateEmployeePoints({
    required int employeeId,
    required bool isAdd,
    int? points,
    String? category,
    int? categoryId,
    String? reason,
    String? notes,
    String? pointsDate,
  });

  Future<EmployeePointsLogsPage> getEmployeePointsLogs({
    required int employeeId,
    int? month,
    int? year,
    String? category,
    String? operationType,
    int perPage,
    int page,
  });

  Future<EmployeePointsMonthlySummaryModel> getEmployeePointsMonthlySummary({
    required int employeeId,
    int? month,
    int? year,
  });

  Future<EmployeePointsCategoriesModel> getEmployeePointsCategories();

  Future<List<EmployeeRewardRuleModel>> getEmployeeRewardRules({bool? isActive});

  Future<Either<Failure, EmployeeRewardRuleModel>> createEmployeeRewardRule({
    required int minPoints,
    int? maxPoints,
    required double rewardAmount,
    required bool isActive,
    String? statusLabel,
    String? statusColor,
  });

  Future<Either<Failure, EmployeeRewardRuleModel>> updateEmployeeRewardRule({
    required int id,
    int? minPoints,
    int? maxPoints,
    bool clearMaxPoints,
    double? rewardAmount,
    String? statusLabel,
    String? statusColor,
    bool clearStatusFields,
    bool? isActive,
  });

  Future<Either<Failure, String>> deleteEmployeeRewardRule({required int id});

  // Point categories (configurable behaviors with default values)
  Future<List<EmployeePointCategoryModel>> getEmployeePointCategories({
    String? operationType,
    bool? isActive,
  });

  Future<Either<Failure, EmployeePointCategoryModel>>
      createEmployeePointCategory({
    required String nameAr,
    String? nameEn,
    required String code,
    required String operationType,
    required int defaultPoints,
    bool isActive,
    int sortOrder,
  });

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
  });

  Future<Either<Failure, String>> deleteEmployeePointCategory({
    required int id,
  });

  // Global points (admin)
  Future<List<EmployeePointsRowModel>> getGlobalEmployeesPoints({
    int? month,
    int? year,
    String? search,
  });

  Future<EmployeePointsReportModel> getGlobalPointsReport({
    int? month,
    int? year,
    List<int>? employeeIds,
    String? operationType,
    int? categoryId,
    bool includeLogs,
  });
}
