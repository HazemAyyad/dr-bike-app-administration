import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/employee_tasks_repository.dart';

class CancelEmployeeTaskUsecase {
  final EmployeeTasksRepository employeeTasksRepository;

  CancelEmployeeTaskUsecase({required this.employeeTasksRepository});

  Future<Either<Failure, String>> call({
    required String employeeTaskId,
    int? occurrenceId,
    bool cancelWithRepetition = false,
    bool isCompleted = false,
  }) {
    return employeeTasksRepository.cancelEmployeeTask(
      employeeTaskId: employeeTaskId,
      occurrenceId: occurrenceId,
      cancelWithRepetition: cancelWithRepetition,
      isCompleted: isCompleted,
    );
  }
}
