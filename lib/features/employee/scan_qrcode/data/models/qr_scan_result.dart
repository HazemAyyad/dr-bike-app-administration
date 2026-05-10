import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class QrScanResult {
  final String status;
  final String message;
  final String? scan; // in/out
  final int? segmentMinutes;
  final int? dayWorkedMinutes;
  final String? updatedSalary;

  // New fields (all optional)
  final String? workedHours;
  final String? requiredHours;
  final String? normalHours;
  final String? overtimeHours;
  final String? normalSalary;
  final String? overtimeSalary;
  final String? totalSalary;

  const QrScanResult({
    required this.status,
    required this.message,
    required this.scan,
    required this.segmentMinutes,
    required this.dayWorkedMinutes,
    required this.updatedSalary,
    required this.workedHours,
    required this.requiredHours,
    required this.normalHours,
    required this.overtimeHours,
    required this.normalSalary,
    required this.overtimeSalary,
    required this.totalSalary,
  });

  factory QrScanResult.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return QrScanResult(
      status: asString(j['status']).toLowerCase(),
      message: asString(j['message']),
      scan: asNullableString(j['scan']),
      segmentMinutes: j['segment_minutes'] == null ? null : asInt(j['segment_minutes']),
      dayWorkedMinutes: j['day_worked_minutes'] == null ? null : asInt(j['day_worked_minutes']),
      updatedSalary: asNullableString(j['updated_salary']),
      workedHours: asNullableString(j['worked_hours']),
      requiredHours: asNullableString(j['required_hours']),
      normalHours: asNullableString(j['normal_hours']),
      overtimeHours: asNullableString(j['overtime_hours']),
      normalSalary: asNullableString(j['normal_salary']),
      overtimeSalary: asNullableString(j['overtime_salary']),
      totalSalary: asNullableString(j['total_salary']),
    );
  }

  String? get bestShownSalary => totalSalary ?? normalSalary ?? updatedSalary;
}

