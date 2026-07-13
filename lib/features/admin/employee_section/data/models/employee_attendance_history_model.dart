import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class EmployeeAttendanceHead {
  final String id;
  final String? name;
  final String? startWorkTime;
  final String? numberOfWorkHours;
  final String? hourWorkPrice;

  /// From API; may be empty until backend sends it (or if not migrated).
  final List<String> weeklyDaysOff;
  final bool currentlyInToday;

  const EmployeeAttendanceHead({
    required this.id,
    required this.name,
    required this.startWorkTime,
    required this.numberOfWorkHours,
    required this.hourWorkPrice,
    required this.weeklyDaysOff,
    this.currentlyInToday = false,
  });

  factory EmployeeAttendanceHead.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return EmployeeAttendanceHead(
      id: asString(j['id']),
      name: asNullableString(j['name']),
      startWorkTime: asNullableString(j['start_work_time']),
      numberOfWorkHours: asNullableString(j['number_of_work_hours']),
      hourWorkPrice: asNullableString(j['hour_work_price']),
      weeklyDaysOff: asStringList(j['weekly_days_off']),
      currentlyInToday: asBool(j['currently_in_today']),
    );
  }
}

class EmployeeAttendanceScanRow {
  final DateTime at;
  final DateTime? serverAt;
  final String? source;
  final String direction;

  const EmployeeAttendanceScanRow({
    required this.at,
    required this.serverAt,
    required this.source,
    required this.direction,
  });

  factory EmployeeAttendanceScanRow.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return EmployeeAttendanceScanRow(
      at: parseApiDateTime(j['device_at'] ?? j['at']),
      serverAt:
          j['server_at'] == null ? null : parseApiDateTime(j['server_at']),
      source: asNullableString(j['source']),
      direction: asString(j['direction']),
    );
  }
}

class EmployeeAttendanceSegmentRow {
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final DateTime? checkInServerAt;
  final DateTime? checkOutServerAt;
  final int? workedMinutes;
  final bool open;

  const EmployeeAttendanceSegmentRow({
    required this.checkInAt,
    required this.checkOutAt,
    required this.checkInServerAt,
    required this.checkOutServerAt,
    required this.workedMinutes,
    required this.open,
  });

  factory EmployeeAttendanceSegmentRow.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return EmployeeAttendanceSegmentRow(
      checkInAt:
          j['check_in_at'] == null ? null : parseApiDateTime(j['check_in_at']),
      checkOutAt: j['check_out_at'] == null
          ? null
          : parseApiDateTime(j['check_out_at']),
      checkInServerAt: j['check_in_server_at'] == null
          ? null
          : parseApiDateTime(j['check_in_server_at']),
      checkOutServerAt: j['check_out_server_at'] == null
          ? null
          : parseApiDateTime(j['check_out_server_at']),
      workedMinutes:
          j['worked_minutes'] == null ? null : asInt(j['worked_minutes']),
      open: asBool(j['open']),
    );
  }
}

class EmployeeAttendanceDay {
  final String date;
  final String?
      source; // qr|fingerprint|manual (nullable for backward compatibility)
  final DateTime? firstCheckIn;
  final DateTime? firstCheckInServer;
  final String? firstCheckInSource;
  final DateTime? lastCheckOut;
  final DateTime? lastCheckOutServer;
  final String? lastCheckOutSource;
  final bool currentlyIn;
  final int workedMinutes;
  final int awayMinutes;
  final int expectedWorkMinutes;
  final bool? onTime;
  final int overtimeMinutes;
  // New (contract-based) overtime/salary fields — nullable for backward compatibility
  final String? workedHours;
  final String? requiredHours;
  final String? normalHours;
  final String? overtimeHours;
  final String? normalSalary;
  final String? overtimeSalary;
  final String? totalSalary;
  final int? contractOvertimeMinutes;
  final List<EmployeeAttendanceSegmentRow> segments;
  final List<EmployeeAttendanceScanRow> scans;
  final int? overtimeRequestId;
  final String? overtimeRequestStatus;
  final int overtimeRequestedMinutes;
  final int? overtimeApprovedMinutes;
  final bool canEditDay;
  final String? attendanceStatus;
  final String? attendanceStatusLabel;

  const EmployeeAttendanceDay({
    required this.date,
    required this.source,
    required this.firstCheckIn,
    required this.firstCheckInServer,
    required this.firstCheckInSource,
    required this.lastCheckOut,
    required this.lastCheckOutServer,
    required this.lastCheckOutSource,
    required this.currentlyIn,
    required this.workedMinutes,
    required this.awayMinutes,
    required this.expectedWorkMinutes,
    required this.onTime,
    required this.overtimeMinutes,
    required this.workedHours,
    required this.requiredHours,
    required this.normalHours,
    required this.overtimeHours,
    required this.normalSalary,
    required this.overtimeSalary,
    required this.totalSalary,
    required this.contractOvertimeMinutes,
    required this.segments,
    required this.scans,
    this.overtimeRequestId,
    this.overtimeRequestStatus,
    this.overtimeRequestedMinutes = 0,
    this.overtimeApprovedMinutes,
    this.canEditDay = false,
    this.attendanceStatus,
    this.attendanceStatusLabel,
  });

  factory EmployeeAttendanceDay.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    final onRaw = j['on_time'];
    bool? onTime;
    if (onRaw is bool) {
      onTime = onRaw;
    }
    return EmployeeAttendanceDay(
      date: asString(j['date']),
      source: asNullableString(j['source']),
      firstCheckIn: j['first_check_in'] == null
          ? null
          : parseApiDateTime(j['first_check_in']),
      firstCheckInServer: j['first_check_in_server'] == null
          ? null
          : parseApiDateTime(j['first_check_in_server']),
      firstCheckInSource: asNullableString(j['first_check_in_source']),
      lastCheckOut: j['last_check_out'] == null
          ? null
          : parseApiDateTime(j['last_check_out']),
      lastCheckOutServer: j['last_check_out_server'] == null
          ? null
          : parseApiDateTime(j['last_check_out_server']),
      lastCheckOutSource: asNullableString(j['last_check_out_source']),
      currentlyIn: asBool(j['currently_in']),
      workedMinutes: asInt(j['worked_minutes']),
      awayMinutes: asInt(j['away_minutes']),
      expectedWorkMinutes: asInt(j['expected_work_minutes']),
      onTime: onTime,
      overtimeMinutes: asInt(j['overtime_minutes']),
      workedHours: asNullableString(j['worked_hours']),
      requiredHours: asNullableString(j['required_hours']),
      normalHours: asNullableString(j['normal_hours']),
      overtimeHours: asNullableString(j['overtime_hours']),
      normalSalary: asNullableString(j['normal_salary']),
      overtimeSalary: asNullableString(j['overtime_salary']),
      totalSalary: asNullableString(j['total_salary']),
      contractOvertimeMinutes: j['contract_overtime_minutes'] == null
          ? null
          : asInt(j['contract_overtime_minutes']),
      segments: mapList(
        j['segments'],
        (m) =>
            EmployeeAttendanceSegmentRow.fromJson(Map<String, dynamic>.from(m)),
      ),
      scans: mapList(
        j['scans'],
        (m) => EmployeeAttendanceScanRow.fromJson(Map<String, dynamic>.from(m)),
      ),
      overtimeRequestId: j['overtime_request_id'] == null
          ? null
          : asInt(j['overtime_request_id']),
      overtimeRequestStatus: asNullableString(j['overtime_request_status']),
      overtimeRequestedMinutes: asInt(j['overtime_requested_minutes']),
      overtimeApprovedMinutes: j['overtime_approved_minutes'] == null
          ? null
          : asInt(j['overtime_approved_minutes']),
      canEditDay: asBool(j['can_edit_day']),
      attendanceStatus: asNullableString(j['attendance_status']),
      attendanceStatusLabel: asNullableString(j['attendance_status_label']),
    );
  }
}

class EmployeeAttendanceMonthlySummary {
  final String? month;
  final String? monthStart;
  final String? monthEnd;
  final int? requiredWorkDaysInMonth;

  final int? monthlyWorkedMinutes;
  final int? monthlyRequiredMinutes;
  final int? monthlyOvertimeMinutes;
  final String? monthlyWorkedHours;
  final String? monthlyRequiredHours;
  final String? monthlyNormalHours;
  final String? monthlyOvertimeHours;

  final String? rangeFrom;
  final String? rangeTo;
  final int? rangeWorkedMinutes;
  final int? rangeRequiredMinutes;
  final int? rangeOvertimeMinutes;
  final String? rangeWorkedHours;
  final String? rangeRequiredHours;
  final String? rangeNormalHours;
  final String? rangeOvertimeHours;
  final String? rangeNormalSalary;
  final String? rangeOvertimeSalary;
  final String? rangeTotalSalary;
  final List<String> weeklyDaysOff;
  final int? monthlyWorkingDaysCount;

  const EmployeeAttendanceMonthlySummary({
    required this.month,
    required this.monthStart,
    required this.monthEnd,
    required this.requiredWorkDaysInMonth,
    required this.monthlyWorkedMinutes,
    required this.monthlyRequiredMinutes,
    required this.monthlyOvertimeMinutes,
    required this.monthlyWorkedHours,
    required this.monthlyRequiredHours,
    required this.monthlyNormalHours,
    required this.monthlyOvertimeHours,
    required this.rangeFrom,
    required this.rangeTo,
    required this.rangeWorkedMinutes,
    required this.rangeRequiredMinutes,
    required this.rangeOvertimeMinutes,
    required this.rangeWorkedHours,
    required this.rangeRequiredHours,
    required this.rangeNormalHours,
    required this.rangeOvertimeHours,
    required this.rangeNormalSalary,
    required this.rangeOvertimeSalary,
    required this.rangeTotalSalary,
    required this.weeklyDaysOff,
    required this.monthlyWorkingDaysCount,
  });

  factory EmployeeAttendanceMonthlySummary.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return EmployeeAttendanceMonthlySummary(
      month: asNullableString(j['month']),
      monthStart: asNullableString(j['month_start']),
      monthEnd: asNullableString(j['month_end']),
      requiredWorkDaysInMonth: j['required_work_days_in_month'] == null
          ? null
          : asInt(j['required_work_days_in_month']),
      monthlyWorkedMinutes: j['monthly_worked_minutes'] == null
          ? null
          : asInt(j['monthly_worked_minutes']),
      monthlyRequiredMinutes: j['monthly_required_minutes'] == null
          ? null
          : asInt(j['monthly_required_minutes']),
      monthlyOvertimeMinutes: j['monthly_overtime_minutes'] == null
          ? null
          : asInt(j['monthly_overtime_minutes']),
      monthlyWorkedHours: asNullableString(j['monthly_worked_hours']),
      monthlyRequiredHours: asNullableString(j['monthly_required_hours']),
      monthlyNormalHours: asNullableString(j['monthly_normal_hours']),
      monthlyOvertimeHours: asNullableString(j['monthly_overtime_hours']),
      rangeFrom: asNullableString(j['range_from']),
      rangeTo: asNullableString(j['range_to']),
      rangeWorkedMinutes: j['range_worked_minutes'] == null
          ? null
          : asInt(j['range_worked_minutes']),
      rangeRequiredMinutes: j['range_required_minutes'] == null
          ? null
          : asInt(j['range_required_minutes']),
      rangeOvertimeMinutes: j['range_overtime_minutes'] == null
          ? null
          : asInt(j['range_overtime_minutes']),
      rangeWorkedHours: asNullableString(j['range_worked_hours']),
      rangeRequiredHours: asNullableString(j['range_required_hours']),
      rangeNormalHours: asNullableString(j['range_normal_hours']),
      rangeOvertimeHours: asNullableString(j['range_overtime_hours']),
      rangeNormalSalary: asNullableString(j['range_normal_salary']),
      rangeOvertimeSalary: asNullableString(j['range_overtime_salary']),
      rangeTotalSalary: asNullableString(j['range_total_salary']),
      weeklyDaysOff: asStringList(j['weekly_days_off']),
      monthlyWorkingDaysCount: j['monthly_working_days_count'] == null
          ? null
          : asInt(j['monthly_working_days_count']),
    );
  }
}

class EmployeeAttendanceHistoryResult {
  final EmployeeAttendanceHead employee;
  final EmployeeAttendanceMonthlySummary? monthlySummary;
  final List<EmployeeAttendanceDay> days;

  const EmployeeAttendanceHistoryResult({
    required this.employee,
    required this.monthlySummary,
    required this.days,
  });

  factory EmployeeAttendanceHistoryResult.fromJson(Map<String, dynamic> json) {
    final j = unwrapDataEnvelope(asMap(json));
    final status = asString(j['status']).toLowerCase();
    if (status == 'error') {
      throw FormatException(asString(j['message'], 'Request failed'));
    }
    return EmployeeAttendanceHistoryResult(
      employee: EmployeeAttendanceHead.fromJson(asMap(j['employee'])),
      monthlySummary: j['monthly_summary'] == null
          ? null
          : EmployeeAttendanceMonthlySummary.fromJson(
              asMap(j['monthly_summary']),
            ),
      days: mapList(
        j['days'],
        (m) => EmployeeAttendanceDay.fromJson(Map<String, dynamic>.from(m)),
      ),
    );
  }
}

class WeeklyOffAttendanceImportCandidate {
  final String date;
  final int logsCount;
  final DateTime? firstScanAt;
  final DateTime? lastScanAt;
  final String deviceUserId;

  const WeeklyOffAttendanceImportCandidate({
    required this.date,
    required this.logsCount,
    required this.firstScanAt,
    required this.lastScanAt,
    required this.deviceUserId,
  });

  factory WeeklyOffAttendanceImportCandidate.fromJson(
    Map<String, dynamic> json,
  ) {
    final j = Map<String, dynamic>.from(json);
    return WeeklyOffAttendanceImportCandidate(
      date: asString(j['date']),
      logsCount: asInt(j['logs_count']),
      firstScanAt: j['first_scan_at'] == null
          ? null
          : parseApiDateTime(j['first_scan_at']),
      lastScanAt: j['last_scan_at'] == null
          ? null
          : parseApiDateTime(j['last_scan_at']),
      deviceUserId: asString(j['device_user_id']),
    );
  }
}
