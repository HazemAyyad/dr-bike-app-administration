class FinancialDetailsEntity {
  final int employeeId;
  final String employeeName;
  final String salary;
  final String debts;
  final String points;
  final String hourWorkPrice;
  final String totalWorkHours;
  final String numberOfWorkHours;
  final dynamic pointsRevenue;
  final dynamic total;
  final String month;
  final String selectedMonth;
  final String baseSalary;
  final String attendanceDays;
  final String absentDays;
  final String lateDays;
  final String delayHours;
  final String overtimeHours;
  final String overtimeSalary;
  final String deductions;
  final String bonuses;
  final String additions;
  final String advances;
  final String finalNetEntitlement;

  const FinancialDetailsEntity({
    required this.employeeId,
    required this.employeeName,
    required this.salary,
    required this.debts,
    required this.points,
    required this.hourWorkPrice,
    required this.totalWorkHours,
    required this.numberOfWorkHours,
    required this.pointsRevenue,
    required this.total,
    required this.month,
    required this.selectedMonth,
    required this.baseSalary,
    required this.attendanceDays,
    required this.absentDays,
    required this.lateDays,
    required this.delayHours,
    required this.overtimeHours,
    required this.overtimeSalary,
    required this.deductions,
    required this.bonuses,
    required this.additions,
    required this.advances,
    required this.finalNetEntitlement,
  });
}
