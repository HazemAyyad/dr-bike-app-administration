import '../../data/models/financial_dues_model.dart';
import '../repositories/employee_section_repository.dart';

class FinancialDuesUsecase {
  final EmployeeRepository employeeRepository;

  FinancialDuesUsecase({required this.employeeRepository});

  Future<List<FinancialDuesModel>> call() {
    return employeeRepository.getFinancialDues();
  }
}
