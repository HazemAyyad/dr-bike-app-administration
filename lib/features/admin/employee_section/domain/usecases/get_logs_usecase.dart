import '../../data/models/logs_model.dart';
import '../repositories/employee_section_repository.dart';

class GetLogsUsecase {
  final EmployeeRepository employeeRepository;

  GetLogsUsecase({required this.employeeRepository});

  Future<List<LogsModel>> call() {
    return employeeRepository.getLogs();
  }
}
