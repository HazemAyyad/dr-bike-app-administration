import '../../data/models/attendance_report_model.dart';
import '../repositories/employee_section_repository.dart';

class GetAttendanceReportUsecase {
  GetAttendanceReportUsecase({required this.employeeRepository});

  final EmployeeRepository employeeRepository;

  Future<AttendanceReportResult> call(AttendanceReportArgs args) {
    return employeeRepository.getAttendanceReport(
      reportType: args.reportType,
      month: args.month,
      year: args.year,
      day: args.day,
      week: args.week,
      employeeIds: args.allEmployees ? null : args.employeeIds,
    );
  }
}
