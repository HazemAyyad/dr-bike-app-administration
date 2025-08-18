import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/errors/failure.dart';
import '../../data/models/employee_task_model.dart';

abstract class EmployeeTasksRepository {
  Future<Either<Failure, String>> cancelEmployeeTask({
    required String employeeTaskId,
    required bool cancelWithRepetition,
  });
  Future<List<EmployeeTaskModel>> getEmployeeTasks({required int page});

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
  });

  Future<dynamic> getTaskDetails({required String taskId});
}
