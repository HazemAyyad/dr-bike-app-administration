import '../repositories/employee_section_repository.dart';

class GetPermissionsUsecase {
  final EmployeeRepository employeeRepository;

  GetPermissionsUsecase({required this.employeeRepository});

  Future<List<Map<String, dynamic>>> call() {
    return employeeRepository.getAllPermissions();
  }
}
