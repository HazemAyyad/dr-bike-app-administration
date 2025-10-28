import 'dart:io';

import 'package:dartz/dartz.dart';

import 'package:doctorbike/core/errors/failure.dart';
import 'package:doctorbike/features/admin/employee_tasks/data/models/employee_task_model.dart';

import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../domain/repositories/employee_tasks_repository.dart';
import '../datasources/employee_tasks_datasource.dart';

class EmployeeTasksImplement implements EmployeeTasksRepository {
  final NetworkInfo networkInfo;
  final EmployeeTasksDatasource employeeTasksDataSource;

  EmployeeTasksImplement(
      {required this.networkInfo, required this.employeeTasksDataSource});

  // create employee task
  @override
  Future<Either<Failure, String>> creatEmployeeTasks({
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
    required XFile? adminImg,
    required File audio,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await employeeTasksDataSource.creatEmployeeTasks(
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

  // get employee tasks
  @override
  Future<List<EmployeeTaskModel>> getEmployeeTasks({required int page}) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await employeeTasksDataSource.getEmployeeTasks(
        page: page,
      );
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  // cancel employee task
  @override
  Future<Either<Failure, String>> cancelEmployeeTask({
    required String employeeTaskId,
    required bool cancelWithRepetition,
    required bool isCompleted,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await employeeTasksDataSource.cancelEmployeeTask(
        employeeTaskId: employeeTaskId,
        cancelWithRepetition: cancelWithRepetition,
        isCompleted: isCompleted,
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

  // get task details
  @override
  Future<dynamic> getTaskDetails({required String taskId}) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result =
          await employeeTasksDataSource.getTaskDetails(taskId: taskId);
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  // uplode task image
  @override
  Future uplodeTaskImage({
    required bool isSubTask,
    required String taskId,
    required List<File> image,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await employeeTasksDataSource.uplodeTaskImage(
        taskId: taskId,
        image: image,
        isSubTask: isSubTask,
      );
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }
}
