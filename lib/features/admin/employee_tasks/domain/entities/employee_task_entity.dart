import 'task_assignee_info.dart';

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
  final List<int> assigneeIds;
  final List<TaskAssigneeInfo> assignees;
  final bool isShared;
  final String assigneeLabel;
  final List<String> subtaskNames;

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
    this.assigneeIds = const [],
    this.assignees = const [],
    this.isShared = false,
    this.assigneeLabel = '',
    this.subtaskNames = const [],
  });

  bool get isRepeatedCopy =>
      parentId != null && parentId!.isNotEmpty && parentId != '0';

  bool get isOccurrence => source == 'occurrence';

  String get displayAssigneeLabel =>
      assigneeLabel.isNotEmpty ? assigneeLabel : employeeName;

  bool matchesAssigneeFilter(int employeeId) {
    if (assigneeIds.contains(employeeId)) return true;
    return int.tryParse(this.employeeId) == employeeId;
  }

  bool matchesSearchQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (taskName.toLowerCase().contains(q)) return true;
    if (employeeName.toLowerCase().contains(q)) return true;
    if (assigneeLabel.toLowerCase().contains(q)) return true;
    for (final assignee in assignees) {
      if (assignee.name.toLowerCase().contains(q)) return true;
    }
    for (final subtask in subtaskNames) {
      if (subtask.toLowerCase().contains(q)) return true;
    }
    return false;
  }
}
