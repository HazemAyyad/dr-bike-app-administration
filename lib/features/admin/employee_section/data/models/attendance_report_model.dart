import '../../../../../core/helpers/json_safe_parser.dart';

class AttendanceReportArgs {
  const AttendanceReportArgs({
    required this.reportType,
    required this.month,
    required this.year,
    this.day,
    this.week,
    this.dateFrom,
    this.dateTo,
    required this.allEmployees,
    this.employeeIds = const [],
  });

  final String reportType;
  final int month;
  final int year;
  final int? day;
  final int? week;
  final String? dateFrom;
  final String? dateTo;
  final bool allEmployees;
  final List<int> employeeIds;
}

/// Points summary embedded in an attendance/salary report row.
class AttendanceReportPointsSummary {
  const AttendanceReportPointsSummary({
    required this.earnedPoints,
    required this.deductedPoints,
    required this.netPoints,
    required this.rewardAmount,
    this.matchedRuleId,
  });

  final int earnedPoints;
  final int deductedPoints;
  final int netPoints;
  final String rewardAmount; // formatted "0.00"
  final int? matchedRuleId;

  double get rewardAmountDouble =>
      double.tryParse(rewardAmount.toString()) ?? 0.0;

  factory AttendanceReportPointsSummary.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return AttendanceReportPointsSummary(
      earnedPoints: asInt(j['earned_points']),
      deductedPoints: asInt(j['deducted_points']),
      netPoints: asInt(j['net_points']),
      rewardAmount: asString(j['reward_amount'], '0.00'),
      matchedRuleId: j['matched_rule_id'] == null
          ? null
          : asInt(j['matched_rule_id']),
    );
  }

  static AttendanceReportPointsSummary empty() =>
      const AttendanceReportPointsSummary(
        earnedPoints: 0,
        deductedPoints: 0,
        netPoints: 0,
        rewardAmount: '0.00',
        matchedRuleId: null,
      );
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
    required this.pointsSummary,
    required this.rewardAmount,
    required this.finalSalary,
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
  final AttendanceReportPointsSummary pointsSummary;
  final String rewardAmount;
  final String finalSalary;

  factory AttendanceReportEmployeeRow.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);

    final pointsRaw = j['points_summary'];
    final pointsMap = pointsRaw is Map
        ? Map<String, dynamic>.from(pointsRaw)
        : <String, dynamic>{};

    final pointsSummary = pointsMap.isNotEmpty
        ? AttendanceReportPointsSummary.fromJson(pointsMap)
        : AttendanceReportPointsSummary.empty();

    final reward = asString(
      j['reward_amount'] ?? pointsMap['reward_amount'],
      '0.00',
    );

    final totalSalary = asString(j['total_salary'], '0.00');
    final fallbackFinal = (double.tryParse(totalSalary) ?? 0.0) +
        (double.tryParse(reward) ?? 0.0);
    final finalSalary = asString(
      j['final_salary'],
      fallbackFinal.toStringAsFixed(2),
    );

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
      totalSalary: totalSalary,
      employeeDebts: asString(j['employee_debts'], '0.00'),
      pointsSummary: pointsSummary,
      rewardAmount: reward,
      finalSalary: finalSalary,
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
