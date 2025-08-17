import '../entities/employee_entity.dart';
import '../repositories/employee_section_repository.dart';

class GetAllEmployeeUsecase {
  final EmployeeRepository employeeRepository;

  GetAllEmployeeUsecase({required this.employeeRepository});

  Future<List<EmployeeEntity>> call() {
    return employeeRepository.getEmployees();
  }
}
