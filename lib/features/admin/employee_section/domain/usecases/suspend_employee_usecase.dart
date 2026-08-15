import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/employee_section_repository.dart';

class SuspendEmployeeUsecase {
  final EmployeeRepository employeeRepository;

  SuspendEmployeeUsecase({required this.employeeRepository});

  Future<Either<Failure, String>> call({
    required String employeeId,
    String? reason,
  }) {
    return employeeRepository.suspendEmployee(
      employeeId: employeeId,
      reason: reason,
    );
  }
}

class RestoreSuspendedEmployeeUsecase {
  final EmployeeRepository employeeRepository;

  RestoreSuspendedEmployeeUsecase({required this.employeeRepository});

  Future<Either<Failure, String>> call({
    required String employeeId,
  }) {
    return employeeRepository.restoreSuspendedEmployee(employeeId: employeeId);
  }
}
