import '../../../../admin/employee_section/data/models/employee_attendance_history_model.dart';
import '../repositories/employee_dashbord_repository.dart';

class GetMyAttendanceHistoryUsecase {
  GetMyAttendanceHistoryUsecase({required this.employeeDashbordRepository});

  final EmployeeDashbordRepository employeeDashbordRepository;

  Future<EmployeeAttendanceHistoryResult> call({
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return employeeDashbordRepository.getMyAttendanceHistory(
      fromDate: fromDate,
      toDate: toDate,
    );
  }
}
