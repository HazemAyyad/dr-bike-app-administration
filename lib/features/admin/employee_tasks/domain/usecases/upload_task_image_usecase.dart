import 'dart:io';

import '../repositories/employee_tasks_repository.dart';

class UploadTaskImageUsecase {
  final EmployeeTasksRepository employeeTasksRepository;

  UploadTaskImageUsecase({required this.employeeTasksRepository});

  Future<dynamic> call({
    required String taskId,
    required List<File> image,
    required bool isSubTask,
  }) {
    return employeeTasksRepository.uplodeTaskImage(
      taskId: taskId,
      image: image,
      isSubTask: isSubTask,
    );
  }
}
