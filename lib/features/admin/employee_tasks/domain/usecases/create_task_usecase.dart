import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/employee_tasks_repository.dart';

class CreateTaskUsecase {
  final EmployeeTasksRepository employeeTasksRepository;

  CreateTaskUsecase({required this.employeeTasksRepository});

  Future<Either<Failure, String>> call({
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
  }) {
    return employeeTasksRepository.creatEmployeeTasks(
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
  }
}
