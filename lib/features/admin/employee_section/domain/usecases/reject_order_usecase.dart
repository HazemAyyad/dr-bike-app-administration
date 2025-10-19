import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/employee_section_repository.dart';

class RejectOrderUsecase {
  final EmployeeRepository employeeRepository;

  RejectOrderUsecase({required this.employeeRepository});

  Future<Either<Failure, String>> call({required String employeeOrderId}) {
    return employeeRepository.rejectEmployeeOrder(
        employeeOrderId: employeeOrderId);
  }
}
