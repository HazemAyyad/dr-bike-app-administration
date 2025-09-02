import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/employee_section_repository.dart';

class CancelLogUsecase {
  final EmployeeRepository employeeRepository;
  CancelLogUsecase({required this.employeeRepository});

  Future<Either<Failure, String>> call({required String logId}) async {
    return await employeeRepository.cancelLog(logId: logId);
  }
}
