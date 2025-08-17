import '../../data/models/financial_details_model.dart';
import '../repositories/employee_section_repository.dart';

class FinancialDetailsUsecase {
  final EmployeeRepository employeeRepository;

  FinancialDetailsUsecase({required this.employeeRepository});

  Future<FinancialDetailsModel> call({required String employeeId}) {
    return employeeRepository.getfinancialDetails(employeeId: employeeId);
  }
}
