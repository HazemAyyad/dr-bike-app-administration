class EmployeeEntity {
  final int id;
  final String employeeName;
  final String hourWorkPrice;
  final String points;
  final String employeeImg;
  final bool hasAttendedToday;
  final bool isWorkingNow;
  final bool isCameOnTime;

  const EmployeeEntity({
    required this.id,
    required this.employeeName,
    required this.hourWorkPrice,
    required this.points,
    required this.employeeImg,
    required this.hasAttendedToday,
    required this.isWorkingNow,
    required this.isCameOnTime,
  });
}
