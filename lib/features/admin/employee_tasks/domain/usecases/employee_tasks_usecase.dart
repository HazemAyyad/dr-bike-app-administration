import '../../data/models/employee_task_model.dart';
import '../repositories/employee_tasks_repository.dart';

class EmployeeTasksUsecase {
  final EmployeeTasksRepository employeeTasksRepository;

  EmployeeTasksUsecase({required this.employeeTasksRepository});

  Future<List<EmployeeTaskModel>> call({required int page}) {
    return employeeTasksRepository.getEmployeeTasks(page: page);
  }
}
