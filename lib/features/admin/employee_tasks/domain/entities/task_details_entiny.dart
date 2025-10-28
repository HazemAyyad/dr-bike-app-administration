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
  final String taskRecurrence;
  final List<String> taskRecurrenceTime;
  final String employeeId;
  final String employeeName;
  final bool isCanceled;
  final String? parentId;
  final List<String>? adminImg;
  final List<String>? employeeImg;
  final String? audio;
  final List<SubTaskEntity> subTasks;

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
    required this.taskRecurrence,
    required this.taskRecurrenceTime,
    required this.employeeId,
    required this.employeeName,
    required this.isCanceled,
    this.parentId,
    this.adminImg,
    this.employeeImg,
    this.audio,
    required this.subTasks,
  });
}

class SubTaskEntity {
  final int id;
  final String name;
  final String description;
  final String status;
  final List<String>? adminImg;
  final bool isForcedToUploadImg;
  final List<String>? employeeImg;

  const SubTaskEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    this.adminImg,
    required this.isForcedToUploadImg,
    this.employeeImg,
  });
}

class ImagesPathInfoEntity {
  final String subtaskAdminImgPath;

  const ImagesPathInfoEntity({required this.subtaskAdminImgPath});
}
