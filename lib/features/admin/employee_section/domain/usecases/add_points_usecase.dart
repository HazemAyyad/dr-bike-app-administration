import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failure.dart';
import '../repositories/employee_section_repository.dart';

class AddPointsUsecase {
  final EmployeeRepository employeeRepository;

  AddPointsUsecase({required this.employeeRepository});

  Future<Either<Failure, String>> call({
    required String employeeId,
    required String points,
    required bool isAdd,
    required String notes,
  }) {
    return employeeRepository.addPointsToEmployee(
      employeeId: employeeId,
      points: points,
      notes: notes,
      isAdd: isAdd,
    );
  }
}
