import 'dart:io';

import '../repositories/employee_tasks_repository.dart';

class UploadTaskImageUsecase {
  final EmployeeTasksRepository employeeTasksRepository;

  UploadTaskImageUsecase({required this.employeeTasksRepository});

  Future<dynamic> call({required String taskId, required List<File> image}) {
    return employeeTasksRepository.uplodeTaskImage(
      taskId: taskId,
      image: image,
    );
  }
}
