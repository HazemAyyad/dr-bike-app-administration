import 'package:dartz/dartz.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../domain/repositories/employee_dashbord_repository.dart';
import '../datasources/employee_dashbord_datasource.dart';
import '../../../../admin/employee_section/data/models/employee_attendance_history_model.dart';
import '../models/dashbord_employee_details_model.dart';

class EmployeeDashbordImplement implements EmployeeDashbordRepository {
  final NetworkInfo networkInfo;
  final EmployeeDashbordDatasource employeeDashbordDatasource;

  EmployeeDashbordImplement({
    required this.networkInfo,
    required this.employeeDashbordDatasource,
  });

  // request over time or loan
  @override
  Future<Either<Failure, String>> requestOverTimeOrLoan({
    required String value,
    required bool isOverTime,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await employeeDashbordDatasource.requestOverTimeOrLoan(
        isOverTime: isOverTime,
        value: value,
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

  // get employee data
  @override
  Future<DashbordEmployeeDetailsModel> getEmployeeData() async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await employeeDashbordDatasource.getEmployeeData();
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<EmployeeAttendanceHistoryResult> getMyAttendanceHistory({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      return await employeeDashbordDatasource.getMyAttendanceHistory(
        fromDate: fromDate,
        toDate: toDate,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

// change employee task to completed
  @override
  Future<Either<Failure, String>> changeEmployeeTaskToCompleted({
    required bool isSubTask,
    required int taskId,
    bool isOccurrence = false,
    int? occurrenceId,
    String? taskDate,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result =
          await employeeDashbordDatasource.changeEmployeeTaskToCompleted(
        isSubTask: isSubTask,
        taskId: taskId,
        isOccurrence: isOccurrence,
        occurrenceId: occurrenceId,
        taskDate: taskDate,
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
