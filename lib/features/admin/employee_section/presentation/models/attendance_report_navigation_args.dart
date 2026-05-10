import '../../data/models/attendance_report_model.dart';
import '../../domain/entities/working_times_entity.dart';

/// يُمرَّر إلى شاشة التقرير: نسخة الفلتر + قائمة الموظفين لإعادة فتح الفلتر.
class AttendanceReportNavigationArgs {
  const AttendanceReportNavigationArgs({
    required this.reportFilters,
    required this.employees,
  });

  final AttendanceReportArgs reportFilters;
  final List<WorkingTimesEntity> employees;
}
