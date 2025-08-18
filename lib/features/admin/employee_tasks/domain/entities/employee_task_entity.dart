class EmployeeTaskEntity {
  final int taskId;
  final String taskName;
  final String employeeId;
  final String employeeName;
  final DateTime startTime;
  final DateTime endTime;
  final bool isCanceled;
  final String? employeeImg;
  final String? adminImg;
  final String? audio;

  EmployeeTaskEntity({
    required this.taskId,
    required this.taskName,
    required this.employeeId,
    required this.employeeName,
    required this.startTime,
    required this.endTime,
    required this.isCanceled,
    this.employeeImg,
    this.adminImg,
    this.audio,
  });
}
