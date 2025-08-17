class WorkingTimesEntity {
  final int id;
  final String employeeName;
  final String startWorkTime;
  final String endWorkTime;
  final String numberOfWorkHours;
  final String employeeImg;

  const WorkingTimesEntity({
    required this.id,
    required this.employeeName,
    required this.startWorkTime,
    required this.endWorkTime,
    required this.numberOfWorkHours,
    required this.employeeImg,
  });
}
