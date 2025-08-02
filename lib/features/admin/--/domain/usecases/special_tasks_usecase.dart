import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/admin_repository.dart';

class CreatSpecialTasksUsecase {
  final AdminRepository adminRepository;

  CreatSpecialTasksUsecase({required this.adminRepository});

  Future<Either<Failure, bool>> call({
    required String token,
    required String name,
    required String description,
    required String notes,
    required String points,
    required String startDate,
    required String endDate,
    required String notShownForEmployee,
    required String taskRecurrence,
    required String taskRecurrenceTime,
    required String subSpecialTaskName,
    required String subSpecialTaskDescription,
  }) {
    return adminRepository.creatSpecialTasks(
      token: token,
      name: name,
      description: description,
      notes: notes,
      points: points,
      startDate: startDate,
      endDate: endDate,
      notShownForEmployee: notShownForEmployee,
      taskRecurrence: taskRecurrence,
      taskRecurrenceTime: taskRecurrenceTime,
      subSpecialTaskName: subSpecialTaskName,
      subSpecialTaskDescription: subSpecialTaskDescription,
    );
  }
}
