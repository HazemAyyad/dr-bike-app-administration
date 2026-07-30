import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/employee_section_repository.dart';

class ChangeEmployeePasswordUsecase {
  final EmployeeRepository employeeRepository;

  ChangeEmployeePasswordUsecase({required this.employeeRepository});

  Future<Either<Failure, String>> call({
    required String employeeId,
    required String password,
    required String passwordConfirmation,
  }) {
    return employeeRepository.changeEmployeePassword(
      employeeId: employeeId,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }
}
