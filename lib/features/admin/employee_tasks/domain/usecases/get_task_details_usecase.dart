import '../repositories/employee_tasks_repository.dart';

class GetTaskDetailsUsecase {
  final EmployeeTasksRepository employeeTasksRepository;

  GetTaskDetailsUsecase({required this.employeeTasksRepository});

  Future<dynamic> call({
    required String taskId,
    String? occurrenceId,
    String? taskDate,
  }) {
    return employeeTasksRepository.getTaskDetails(
      taskId: taskId,
      occurrenceId: occurrenceId,
      taskDate: taskDate,
    );
  }
}
