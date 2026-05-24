import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/employee_tasks_repository.dart';

class CreateTaskUsecase {
  final CreateEmployeeTasksRepository employeeTasksRepository;

  CreateTaskUsecase({required this.employeeTasksRepository});

  Future<Either<Failure, String>> call({
    required int employeeTaskId,
    required String name,
    required String description,
    required String notes,
    required String employeeId,
    List<String> employeeIds = const [],
    required String points,
    required DateTime startTime,
    required DateTime endTime,
    required String taskRecurrence,
    required List<String> taskRecurrenceTime,
    required RxList subEmployeeTasks,
    required String notShownForEmployee,
    required String isForcedToUploadImg,
    required String requiresAdminReview,
    required List<File> adminImg,
    required File audio,
    String? priority,
    Map<String, dynamic>? recurrenceConfig,
    int? templateId,
    int? occurrenceId,
  }) {
    return employeeTasksRepository.creatEmployeeTasks(
      employeeTaskId: employeeTaskId,
      name: name,
      description: description,
      notes: notes,
      employeeId: employeeId,
      employeeIds: employeeIds,
      points: points,
      startTime: startTime,
      endTime: endTime,
      taskRecurrence: taskRecurrence,
      taskRecurrenceTime: taskRecurrenceTime,
      subEmployeeTasks: subEmployeeTasks,
      notShownForEmployee: notShownForEmployee,
      isForcedToUploadImg: isForcedToUploadImg,
      requiresAdminReview: requiresAdminReview,
      adminImg: adminImg,
      audio: audio,
      priority: priority,
      recurrenceConfig: recurrenceConfig,
      templateId: templateId,
      occurrenceId: occurrenceId,
    );
  }
}
