class EmployeeTaskEntity {
  final int taskId;
  final int? occurrenceId;
  final String? parentId;
  final String source;
  final String taskName;
  final String employeeId;
  final String employeeName;
  final DateTime startTime;
  final DateTime endTime;
  final bool isCanceled;
  final String? employeeImg;
  final String? employeePhoto;
  final String? adminImg;
  final String? audio;
  final String status;
  final String priority;
  final int points;
  final int progress;
  final bool proofRequired;
  final String taskRecurrence;
  final List<String> taskRecurrenceTime;
  final int? templateId;

  EmployeeTaskEntity({
    required this.taskId,
    this.occurrenceId,
    this.parentId,
    this.source = 'legacy',
    this.templateId,
    required this.taskName,
    required this.employeeId,
    required this.employeeName,
    required this.startTime,
    required this.endTime,
    required this.isCanceled,
    this.employeeImg,
    this.employeePhoto,
    this.adminImg,
    this.audio,
    this.status = 'pending',
    this.priority = 'medium',
    this.points = 0,
    this.progress = 0,
    this.proofRequired = false,
    this.taskRecurrence = 'noRepeat',
    this.taskRecurrenceTime = const [],
  });

  bool get isRepeatedCopy =>
      parentId != null && parentId!.isNotEmpty && parentId != '0';

  bool get isOccurrence => source == 'occurrence';
}
