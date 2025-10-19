import '../../data/models/employee_details_model.dart';
import '../repositories/employee_section_repository.dart';

class EmployeeDetailsUsecase {
  final EmployeeRepository employeeRepository;

  EmployeeDetailsUsecase({required this.employeeRepository});

  Future<EmployeeDetailsModel> call({required String employeeId}) {
    return employeeRepository.getEmployeeDetails(employeeId: employeeId);
  }
}
