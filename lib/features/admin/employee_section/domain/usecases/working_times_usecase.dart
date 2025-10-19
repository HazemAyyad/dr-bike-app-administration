import '../../data/models/working_times_model.dart';
import '../repositories/employee_section_repository.dart';

class WorkingTimesUsecase {
  final EmployeeRepository employeeRepository;

  WorkingTimesUsecase({required this.employeeRepository});

  Future<List<WorkingTimesModel>> call() {
    return employeeRepository.getWorkingTimes();
  }
}
