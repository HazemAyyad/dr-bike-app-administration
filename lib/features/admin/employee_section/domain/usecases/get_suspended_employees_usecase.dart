import '../entities/employee_entity.dart';
import '../repositories/employee_section_repository.dart';

class GetSuspendedEmployeesUsecase {
  final EmployeeRepository employeeRepository;

  GetSuspendedEmployeesUsecase({required this.employeeRepository});

  Future<List<EmployeeEntity>> call() {
    return employeeRepository.getSuspendedEmployees();
  }
}
