import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/employee_tasks_repository.dart';

class CreatSpecialTasksUsecase {
  final CreateEmployeeTasksRepository createEmployeeTasksRepository;

  CreatSpecialTasksUsecase({required this.createEmployeeTasksRepository});

  Future<Either<Failure, String>> call({
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
  }) {
    return createEmployeeTasksRepository.creatSpecialTasks(
      name: name,
      description: description,
      notes: notes,
      startDate: startDate,
      endDate: endDate,
      notShownForEmployee: notShownForEmployee,
      taskRecurrence: taskRecurrence,
      taskRecurrenceTime: taskRecurrenceTime,
      forceEmployeeToAddImg: forceEmployeeToAddImg,
      adminImg: adminImg,
      audio: audio,
      subSpecialTasks: subSpecialTasks,
    );
  }
}
