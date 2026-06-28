import 'task_assignee_info.dart';

class TaskDetailsEntity {
  final int taskId;
  final String taskName;
  final String taskDescription;
  final String notes;
  final int points;
  final bool notShownForEmployee;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final bool isForcedToUploadImg;
  final String proofMediaType;
  final bool requiresAdminReview;
  final String taskRecurrence;
  final List<String> taskRecurrenceTime;
  final String employeeId;
  final List<int> assigneeIds;
  final List<TaskAssigneeInfo> assignees;
  final String employeeName;
  final bool isCanceled;
  final String? parentId;
  final List<String>? adminImg;
  final List<String>? adminVideos;
  final List<String>? employeeImg;
  final List<String>? employeeVideos;
  final String? audio;
  final List<SubTaskEntity> subTasks;
  final List<Map<String, dynamic>> timeline;
  final int progress;
  final String priority;
  final String? rejectionNotes;
  final int? templateId;
  final int? occurrenceId;
  final Map<String, dynamic>? recurrenceConfig;
  final String? reminderWhen;
  final String? reminderChannel;
  final int? completedByEmployeeId;
  final String? completedByName;

  const TaskDetailsEntity({
    required this.taskId,
    required this.taskName,
    required this.taskDescription,
    required this.notes,
    required this.points,
    required this.notShownForEmployee,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.isForcedToUploadImg,
    this.proofMediaType = 'none',
    this.requiresAdminReview = true,
    required this.taskRecurrence,
    required this.taskRecurrenceTime,
    required this.employeeId,
    this.assigneeIds = const [],
    this.assignees = const [],
    required this.employeeName,
    required this.isCanceled,
    this.parentId,
    this.adminImg,
    this.adminVideos,
    this.employeeImg,
    this.employeeVideos,
    this.audio,
    required this.subTasks,
    this.timeline = const [],
    this.progress = 0,
    this.priority = 'medium',
    this.rejectionNotes,
    this.templateId,
    this.occurrenceId,
    this.recurrenceConfig,
    this.reminderWhen,
    this.reminderChannel,
    this.completedByEmployeeId,
    this.completedByName,
  });

  bool get usesTemplateRecurrence => templateId != null && templateId! > 0;
}

class SubTaskEntity {
  final int id;
  final String name;
  final String description;
  final String status;
  final String? rejectionReason;
  final List<String>? adminImg;
  final List<String>? adminVideos;
  final String? adminAudio;
  final bool isForcedToUploadImg;
  final String proofMediaType;
  final List<String>? employeeImg;
  final List<String>? employeeVideos;
  final int? completedByEmployeeId;
  final String? completedByName;

  const SubTaskEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    this.rejectionReason,
    this.adminImg,
    this.adminVideos,
    this.adminAudio,
    required this.isForcedToUploadImg,
    this.proofMediaType = 'none',
    this.employeeImg,
    this.employeeVideos,
    this.completedByEmployeeId,
    this.completedByName,
  });

  bool get isRejected => status == 'rejected';
  bool get isCompleted => status == 'completed';
}

class ImagesPathInfoEntity {
  final String subtaskAdminImgPath;

  const ImagesPathInfoEntity({required this.subtaskAdminImgPath});
}
