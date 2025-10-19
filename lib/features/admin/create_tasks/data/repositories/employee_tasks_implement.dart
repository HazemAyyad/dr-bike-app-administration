import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

import 'package:doctorbike/core/errors/failure.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../domain/repositories/employee_tasks_repository.dart';
import '../datasources/employee_tasks_remote_datasource.dart';

class CreateEmployeeTasksImplement implements CreateEmployeeTasksRepository {
  final NetworkInfo networkInfo;
  final CreateEmployeeTasksDatasource employeeTasksDataSource;

  CreateEmployeeTasksImplement({
    required this.networkInfo,
    required this.employeeTasksDataSource,
  });

  @override
  Future<Either<Failure, String>> creatEmployeeTasks({
    required int employeeTaskId,
    required String name,
    required String description,
    required String notes,
    required String employeeId,
    required String points,
    required DateTime startTime,
    required DateTime endTime,
    required String taskRecurrence,
    required List<String> taskRecurrenceTime,
    required RxList subEmployeeTasks,
    required String notShownForEmployee,
    required String isForcedToUploadImg,
    required List<File> adminImg,
    required File audio,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await employeeTasksDataSource.creatEmployeeTasks(
        employeeTaskId: employeeTaskId,
        name: name,
        description: description,
        notes: notes,
        employeeId: employeeId,
        points: points,
        startTime: startTime,
        endTime: endTime,
        taskRecurrence: taskRecurrence,
        taskRecurrenceTime: taskRecurrenceTime,
        subEmployeeTasks: subEmployeeTasks,
        notShownForEmployee: notShownForEmployee,
        isForcedToUploadImg: isForcedToUploadImg,
        adminImg: adminImg,
        audio: audio,
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

  @override
  Future<Either<Failure, String>> creatSpecialTasks({
    required String name,
    required String description,
    required String notes,
    required DateTime startDate,
    required DateTime endDate,
    required String notShownForEmployee,
    required String taskRecurrence,
    required List<String> taskRecurrenceTime,
    required bool forceEmployeeToAddImg,
    required List<File> adminImg,
    required File audio,
    required RxList subSpecialTasks,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await employeeTasksDataSource.creatSpecialTasks(
        name: name,
        description: description,
        notes: notes,
        startDate: startDate,
        endDate: endDate,
        taskRecurrence: taskRecurrence,
        taskRecurrenceTime: taskRecurrenceTime,
        subSpecialTasks: subSpecialTasks,
        notShownForEmployee: notShownForEmployee,
        forceEmployeeToAddImg: forceEmployeeToAddImg,
        adminImg: adminImg,
        audio: audio,
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
}
