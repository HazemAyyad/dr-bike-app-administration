import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failure.dart';
import '../repositories/employee_section_repository.dart';

class PaySalaryToEmployeeUsecase {
  final EmployeeRepository employeeRepository;

  PaySalaryToEmployeeUsecase({required this.employeeRepository});

  Future<Either<Failure, String>> call({
    required String employeeId,
    required String salary,
  }) {
    return employeeRepository.paySalaryToEmployeeUsecase(
      employeeId: employeeId,
      salary: salary,
    );
  }
}
