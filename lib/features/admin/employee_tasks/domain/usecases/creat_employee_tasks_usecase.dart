// import '../repositories/employee_tasks_repository.dart';

// class CreatEmployeeTasksUsecase {
//   final EmployeeTasksRepository employeeTasksRepository;

//   CreatEmployeeTasksUsecase({required this.employeeTasksRepository});

//   Future<void> call({
//     required String employeeId,
//     required String taskName,
//     required String taskDescription,
//     required DateTime dueDate,
//   }) async {
//     try {
//       await employeeTasksRepository.creatEmployeeTasks(
//         employeeId: employeeId,
//         taskName: taskName,
//         taskDescription: taskDescription,
//         dueDate: dueDate,
//       );
//     } catch (e) {
//       throw Exception('Failed to create employee task: $e');
//     }
//   }
// }
