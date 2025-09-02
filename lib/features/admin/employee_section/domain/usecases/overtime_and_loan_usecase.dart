import '../../data/models/overtime_and_loan_model.dart';
import '../repositories/employee_section_repository.dart';

class OvertimeAndLoanUsecase {
  final EmployeeRepository employeeRepository;

  OvertimeAndLoanUsecase({required this.employeeRepository});

  Future<List<OvertimeAndLoanModel>> call({
    required bool isOvertime,
  }) {
    return employeeRepository.getOvertimeAndLoan(isOvertime: isOvertime);
  }
}
