import '../../data/models/employee_advances_model.dart';
import '../repositories/employee_section_repository.dart';

class EmployeeAdvancesUsecase {
  EmployeeAdvancesUsecase({required this.employeeRepository});

  final EmployeeRepository employeeRepository;

  Future<EmployeeAdvancesResult> call({
    required int employeeId,
    required String month,
  }) {
    return employeeRepository.getEmployeeAdvances(
      employeeId: employeeId,
      month: month,
    );
  }
}
