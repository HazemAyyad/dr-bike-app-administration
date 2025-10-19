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
  });
}
