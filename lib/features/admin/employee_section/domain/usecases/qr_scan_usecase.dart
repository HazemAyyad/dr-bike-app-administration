import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/employee_section_repository.dart';

class QrScanUsecase {
  final EmployeeRepository employeeRepository;

  QrScanUsecase({required this.employeeRepository});

  Future<Either<Failure, String>> call({required String qrData}) {
    return employeeRepository.qrScan(qrData: qrData);
  }
}
