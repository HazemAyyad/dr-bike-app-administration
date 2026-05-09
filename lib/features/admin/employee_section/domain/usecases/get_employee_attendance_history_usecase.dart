import '../../data/models/employee_attendance_history_model.dart';
import '../repositories/employee_section_repository.dart';

class GetEmployeeAttendanceHistoryUsecase {
  final EmployeeRepository employeeRepository;

  GetEmployeeAttendanceHistoryUsecase({required this.employeeRepository});

  Future<EmployeeAttendanceHistoryResult> call({
    required String employeeId,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return employeeRepository.getEmployeeAttendanceHistory(
      employeeId: employeeId,
      fromDate: fromDate,
      toDate: toDate,
    );
  }
}
