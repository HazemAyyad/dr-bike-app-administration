import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:doctorbike/features/admin/employee_section/data/models/employee_details_model.dart';
import 'package:doctorbike/features/admin/employee_section/data/models/financial_details_model.dart';
import 'package:doctorbike/features/admin/employee_section/data/models/financial_dues_model.dart';
import 'package:doctorbike/features/admin/employee_section/data/models/overtime_and_loan_model.dart';
import 'package:doctorbike/features/admin/employee_section/data/models/qr_generation_model.dart';
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
    required bool isAdd,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await employeeDatasource.addPointsToEmployee(
        employeeId: employeeId,
        points: points,
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
