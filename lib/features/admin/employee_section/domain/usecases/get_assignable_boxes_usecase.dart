import '../repositories/employee_section_repository.dart';

class GetAssignableBoxesUsecase {
  final EmployeeRepository employeeRepository;

  GetAssignableBoxesUsecase({required this.employeeRepository});

  Future<List<Map<String, dynamic>>> call() {
    return employeeRepository.getAssignableBoxes();
  }
}
