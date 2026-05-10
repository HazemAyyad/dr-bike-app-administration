class EmployeeEntity {
  final int id;
  final String employeeName;
  final String hourWorkPrice;
  final String points;
  final String employeeImg;
  final bool hasAttendedToday;
  final bool isWorkingNow;
  final bool isCameOnTime;
  final EmployeePointsSummaryEntity? pointsSummary;

  const EmployeeEntity({
    required this.id,
    required this.employeeName,
    required this.hourWorkPrice,
    required this.points,
    required this.employeeImg,
    required this.hasAttendedToday,
    required this.isWorkingNow,
    required this.isCameOnTime,
    this.pointsSummary,
  });
}

/// Lightweight points summary attached to each employee in the listing so the
/// employees screen can render the live monthly net points badge instead of
/// the legacy static `points` field.
class EmployeePointsSummaryEntity {
  const EmployeePointsSummaryEntity({
    required this.earnedPoints,
    required this.deductedPoints,
    required this.netPoints,
    required this.rewardAmount,
    this.rewardRuleId,
    this.rewardStatusLabel,
    this.rewardStatusColor,
  });

  final int earnedPoints;
  final int deductedPoints;
  final int netPoints;
  final String rewardAmount;
  final int? rewardRuleId;
  final String? rewardStatusLabel;
  final String? rewardStatusColor;
}
