import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/employee_dashbord_repository.dart';

class ChangeTaskCompletedUasecase {
  final EmployeeDashbordRepository employeeDashbordRepository;

  ChangeTaskCompletedUasecase({required this.employeeDashbordRepository});

  Future<Either<Failure, String>> call({
    required bool isSubTask,
    required int taskId,
  }) {
    return employeeDashbordRepository.changeEmployeeTaskToCompleted(
      isSubTask: isSubTask,
      taskId: taskId,
    );
  }
}
