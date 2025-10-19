import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:doctorbike/features/admin/employee_section/data/models/financial_details_model.dart';
import '../../../../../core/errors/failure.dart';
import '../../data/models/employee_details_model.dart';
import '../../data/models/financial_dues_model.dart';
import '../../data/models/logs_model.dart';
import '../../data/models/overtime_and_loan_model.dart';
import '../../data/models/qr_generation_model.dart';
import '../../data/models/working_times_model.dart';
import '../entities/employee_entity.dart';

abstract class EmployeeRepository {
  Future<List<EmployeeEntity>> getEmployees();

  Future<List<WorkingTimesModel>> getWorkingTimes();

  Future<List<FinancialDuesModel>> getFinancialDues();

  Future<FinancialDetailsModel> getfinancialDetails(
      {required String employeeId});

  Future<QrGenerationModel> qrGeneration();

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
}
