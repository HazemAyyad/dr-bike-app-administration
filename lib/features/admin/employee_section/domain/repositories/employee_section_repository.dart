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
    required int points,
    required String category,
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
  });

  Future<Either<Failure, EmployeeRewardRuleModel>> updateEmployeeRewardRule({
    required int id,
    int? minPoints,
    int? maxPoints,
    bool clearMaxPoints,
    double? rewardAmount,
    bool? isActive,
  });

  Future<Either<Failure, String>> deleteEmployeeRewardRule({required int id});
}
