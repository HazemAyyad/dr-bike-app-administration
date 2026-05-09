import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class EmployeeAttendanceHead {
  final String id;
  final String? name;
  final String? startWorkTime;
  final String? numberOfWorkHours;

  const EmployeeAttendanceHead({
    required this.id,
    required this.name,
    required this.startWorkTime,
    required this.numberOfWorkHours,
  });

  factory EmployeeAttendanceHead.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return EmployeeAttendanceHead(
      id: asString(j['id']),
      name: asNullableString(j['name']),
      startWorkTime: asNullableString(j['start_work_time']),
      numberOfWorkHours: asNullableString(j['number_of_work_hours']),
    );
  }
}

class EmployeeAttendanceScanRow {
  final DateTime at;
  final String direction;

  const EmployeeAttendanceScanRow({
    required this.at,
    required this.direction,
  });

  factory EmployeeAttendanceScanRow.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return EmployeeAttendanceScanRow(
      at: parseApiDateTime(j['at']),
      direction: asString(j['direction']),
    );
  }
}

class EmployeeAttendanceSegmentRow {
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final int? workedMinutes;
  final bool open;

  const EmployeeAttendanceSegmentRow({
    required this.checkInAt,
    required this.checkOutAt,
    required this.workedMinutes,
    required this.open,
  });

  factory EmployeeAttendanceSegmentRow.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return EmployeeAttendanceSegmentRow(
      checkInAt:
          j['check_in_at'] == null ? null : parseApiDateTime(j['check_in_at']),
      checkOutAt:
          j['check_out_at'] == null ? null : parseApiDateTime(j['check_out_at']),
      workedMinutes: j['worked_minutes'] == null
          ? null
          : asInt(j['worked_minutes']),
      open: asBool(j['open']),
    );
  }
}

class EmployeeAttendanceDay {
  final String date;
  final DateTime? firstCheckIn;
  final DateTime? lastCheckOut;
  final bool currentlyIn;
  final int workedMinutes;
  final int awayMinutes;
  final int expectedWorkMinutes;
  final bool? onTime;
  final int overtimeMinutes;
  final List<EmployeeAttendanceSegmentRow> segments;
  final List<EmployeeAttendanceScanRow> scans;

  const EmployeeAttendanceDay({
    required this.date,
    required this.firstCheckIn,
    required this.lastCheckOut,
    required this.currentlyIn,
    required this.workedMinutes,
    required this.awayMinutes,
    required this.expectedWorkMinutes,
    required this.onTime,
    required this.overtimeMinutes,
    required this.segments,
    required this.scans,
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
      firstCheckIn: j['first_check_in'] == null
          ? null
          : parseApiDateTime(j['first_check_in']),
      lastCheckOut: j['last_check_out'] == null
          ? null
          : parseApiDateTime(j['last_check_out']),
      currentlyIn: asBool(j['currently_in']),
      workedMinutes: asInt(j['worked_minutes']),
      awayMinutes: asInt(j['away_minutes']),
      expectedWorkMinutes: asInt(j['expected_work_minutes']),
      onTime: onTime,
      overtimeMinutes: asInt(j['overtime_minutes']),
      segments: mapList(
        j['segments'],
        (m) => EmployeeAttendanceSegmentRow.fromJson(
            Map<String, dynamic>.from(m)),
      ),
      scans: mapList(
        j['scans'],
        (m) =>
            EmployeeAttendanceScanRow.fromJson(Map<String, dynamic>.from(m)),
      ),
    );
  }
}

class EmployeeAttendanceHistoryResult {
  final EmployeeAttendanceHead employee;
  final List<EmployeeAttendanceDay> days;

  const EmployeeAttendanceHistoryResult({
    required this.employee,
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
      days: mapList(
        j['days'],
        (m) => EmployeeAttendanceDay.fromJson(Map<String, dynamic>.from(m)),
      ),
    );
  }
}
