import '../../../../../core/helpers/json_safe_parser.dart';

class AttendanceReportArgs {
  const AttendanceReportArgs({
    required this.reportType,
    required this.month,
    required this.year,
    this.day,
    this.week,
    required this.allEmployees,
    this.employeeIds = const [],
  });

  final String reportType;
  final int month;
  final int year;
  final int? day;
  final int? week;
  final bool allEmployees;
  final List<int> employeeIds;
}

/// Row returned by `/employee-attendance/reports`.
class AttendanceReportEmployeeRow {
  const AttendanceReportEmployeeRow({
    required this.employeeId,
    required this.employeeName,
    required this.weeklyDaysOff,
    required this.hourWorkPrice,
    required this.overtimeHourPriceEffective,
    required this.requiredWorkingDays,
    required this.requiredHours,
    required this.workedHours,
    required this.normalHours,
    required this.overtimeHours,
    required this.normalSalary,
    required this.overtimeSalary,
    required this.totalSalary,
    required this.employeeDebts,
  });

  final int employeeId;
  final String employeeName;
  final List<String> weeklyDaysOff;
  final String hourWorkPrice;
  final String overtimeHourPriceEffective;
  final int requiredWorkingDays;
  final String requiredHours;
  final String workedHours;
  final String normalHours;
  final String overtimeHours;
  final String normalSalary;
  final String overtimeSalary;
  final String totalSalary;
  final String employeeDebts;

  factory AttendanceReportEmployeeRow.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return AttendanceReportEmployeeRow(
      employeeId: asInt(j['employee_id']),
      employeeName: asString(j['employee_name']),
      weeklyDaysOff: asStringList(j['weekly_days_off']),
      hourWorkPrice: asString(j['hour_work_price'], '0.00'),
      overtimeHourPriceEffective:
          asString(j['overtime_hour_price_effective'], '0.00'),
      requiredWorkingDays: asInt(j['required_working_days']),
      requiredHours: asString(j['required_hours']),
      workedHours: asString(j['worked_hours']),
      normalHours: asString(j['normal_hours']),
      overtimeHours: asString(j['overtime_hours']),
      normalSalary: asString(j['normal_salary']),
      overtimeSalary: asString(j['overtime_salary']),
      totalSalary: asString(j['total_salary']),
      employeeDebts: asString(j['employee_debts'], '0.00'),
    );
  }
}

class AttendanceReportResult {
  const AttendanceReportResult({
    required this.reportType,
    required this.month,
    required this.year,
    this.day,
    this.week,
    required this.periodFrom,
    required this.periodTo,
    required this.employees,
  });

  final String reportType;
  final int month;
  final int year;
  final int? day;
  final int? week;
  final String periodFrom;
  final String periodTo;
  final List<AttendanceReportEmployeeRow> employees;

  factory AttendanceReportResult.fromApiJson(Map<String, dynamic> json) {
    final j = unwrapDataEnvelope(asMap(json));
    final status = asString(j['status']).toLowerCase();
    if (status == 'error') {
      throw FormatException(asString(j['message'], 'Request failed'));
    }

    final rows = mapList(
      j['employees'],
      (Map<String, dynamic> m) => AttendanceReportEmployeeRow.fromJson(m),
    );

    return AttendanceReportResult(
      reportType: asString(j['report_type']),
      month: asInt(j['month']),
      year: asInt(j['year']),
      day: j['day'] == null ? null : asInt(j['day']),
      week: j['week'] == null ? null : asInt(j['week']),
      periodFrom: asString(j['period_from']),
      periodTo: asString(j['period_to']),
      employees: rows,
    );
  }
}
