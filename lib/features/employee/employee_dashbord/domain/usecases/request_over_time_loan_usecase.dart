import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/employee_dashbord_repository.dart';

class RequestOverTimeLoanUsecase {
  final EmployeeDashbordRepository employeeDashbordRepository;

  RequestOverTimeLoanUsecase({required this.employeeDashbordRepository});

  Future<Either<Failure, String>> call({
    required String value,
    required bool isOverTime,
  }) {
    return employeeDashbordRepository.requestOverTimeOrLoan(
      isOverTime: isOverTime,
      value: value,
    );
  }
}
