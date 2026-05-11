import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/employee_section_repository.dart';

class DeleteEmployeeUsecase {
  final EmployeeRepository employeeRepository;

  DeleteEmployeeUsecase({required this.employeeRepository});

  Future<Either<Failure, String>> call({
    required String employeeId,
  }) {
    return employeeRepository.deleteEmployee(employeeId: employeeId);
  }
}
