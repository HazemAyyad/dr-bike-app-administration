import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failure.dart';
import '../repositories/employee_section_repository.dart';

class AddPointsUsecase {
  final EmployeeRepository employeeRepository;

  AddPointsUsecase({required this.employeeRepository});

  Future<Either<Failure, String>> call({
    required String token,
    required String employeeId,
    required String points,
    required bool isAdd,
  }) {
    return employeeRepository.addPointsToEmployee(
      token: token,
      employeeId: employeeId,
      points: points,
      isAdd: isAdd,
    );
  }
}
