import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/employee_section_repository.dart';

class ApproveEmployeeOrderUsecase {
  final EmployeeRepository employeeRepository;

  ApproveEmployeeOrderUsecase({required this.employeeRepository});

  Future<Either<Failure, String>> call({
    required String employeeOrderId,
    required String overtimeValue,
    required String loanValue,
    required String extraWorkHoursValue,
  }) {
    return employeeRepository.approveEmployeeOrder(
      employeeOrderId: employeeOrderId,
      overtimeValue: overtimeValue,
      loanValue: loanValue,
      extraWorkHoursValue: extraWorkHoursValue,
    );
  }
}
