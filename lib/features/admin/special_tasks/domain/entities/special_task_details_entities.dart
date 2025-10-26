class SpecialTaskDetailsEntities {
  final int taskId;
  final String taskName;
  final String taskDescription;
  final List<String> adminImg;
  final String taskRecurrence;
  final String notes;
  final List<String> taskRecurrenceTime;
  final List<SubTaskEntity> subTasks;
  final DateTime startTime;
  final DateTime endTime;
  final String audio;

  SpecialTaskDetailsEntities({
    required this.taskId,
    required this.taskName,
    required this.taskDescription,
    required this.notes,
    required this.adminImg,
    required this.taskRecurrence,
    required this.taskRecurrenceTime,
    required this.subTasks,
    required this.startTime,
    required this.endTime,
    required this.audio,
  });
}

class SubTaskEntity {
  final int subTaskId;
  final String specialTaskId;
  final String subTaskName;
  final String subTaskDescription;
  final String status;
  final List<String> adminImg;
  final bool forceEmployeeToAddImg;

  SubTaskEntity({
    required this.subTaskId,
    required this.specialTaskId,
    required this.subTaskName,
    required this.subTaskDescription,
    required this.status,
    required this.adminImg,
    required this.forceEmployeeToAddImg,
  });
}
