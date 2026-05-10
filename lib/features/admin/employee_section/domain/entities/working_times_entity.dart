class WorkingTimesEntity {
  final int id;
  final String employeeName;
  final String startWorkTime;
  final String endWorkTime;
  final String numberOfWorkHours;
  final String employeeImg;
  final bool hasAttendedToday;
  final bool isWorkingNow;
  final bool isCameOnTime;

  const WorkingTimesEntity({
    required this.id,
    required this.employeeName,
    required this.startWorkTime,
    required this.endWorkTime,
    required this.numberOfWorkHours,
    required this.employeeImg,
    required this.hasAttendedToday,
    required this.isWorkingNow,
    required this.isCameOnTime,
  });
}
