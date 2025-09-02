import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/employee_tasks_repository.dart';

class CancelEmployeeTaskUsecase {
  final EmployeeTasksRepository employeeTasksRepository;

  CancelEmployeeTaskUsecase({required this.employeeTasksRepository});

  Future<Either<Failure, String>> call({
    required String employeeTaskId,
    bool cancelWithRepetition = false,
    bool isCompleted = false,
  }) {
    return employeeTasksRepository.cancelEmployeeTask(
      employeeTaskId: employeeTaskId,
      cancelWithRepetition: cancelWithRepetition,
      isCompleted: isCompleted,
    );
  }
}
