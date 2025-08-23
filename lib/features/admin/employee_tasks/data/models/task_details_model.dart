import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/show_net_image.dart';
import '../../domain/entities/task_details_entiny.dart';

class TaskDetailsModel extends TaskDetailsEntity {
  TaskDetailsModel({
    required int taskId,
    required String taskName,
    required String taskDescription,
    required String notes,
    required int points,
    required bool notShownForEmployee,
    required DateTime startTime,
    required DateTime endTime,
    required String status,
    required bool isForcedToUploadImg,
    required String taskRecurrence,
    required List<String> taskRecurrenceTime,
    required String employeeId,
    required String employeeName,
    required bool isCanceled,
    String? parentId,
    List<String>? adminImg,
    List<String>? employeeImg,
    String? audio,
    required List<SubTaskModel> subTasks,
  }) : super(
          taskId: taskId,
          taskName: taskName,
          taskDescription: taskDescription,
          notes: notes,
          points: points,
          notShownForEmployee: notShownForEmployee,
          startTime: startTime,
          endTime: endTime,
          status: status,
          isForcedToUploadImg: isForcedToUploadImg,
          taskRecurrence: taskRecurrence,
          taskRecurrenceTime: taskRecurrenceTime,
          employeeId: employeeId,
          employeeName: employeeName,
          isCanceled: isCanceled,
          parentId: parentId,
          adminImg: adminImg,
          employeeImg: employeeImg,
          audio: audio,
          subTasks: subTasks,
        );

  factory TaskDetailsModel.fromJson(Map<String, dynamic> json) {
    return TaskDetailsModel(
      taskId: json[ApiKey.id] ?? 0,
      taskName: json[ApiKey.name] ?? 'Unknown',
      taskDescription: json[ApiKey.description] ?? '',
      notes: json[ApiKey.notes] ?? '',
      points: int.tryParse(json[ApiKey.points]?.toString() ?? "0") ?? 0,
      notShownForEmployee:
          (json[ApiKey.not_shown_for_employee]?.toString() ?? "0") == "1",
      startTime: DateTime.tryParse(json[ApiKey.start_time] ?? "") ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endTime: DateTime.tryParse(json[ApiKey.end_time] ?? "") ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: json[ApiKey.status] ?? '',
      isForcedToUploadImg:
          (json[ApiKey.is_forced_to_upload_img]?.toString() ?? "0") == "1",
      taskRecurrence: json[ApiKey.task_recurrence] ?? '',
      taskRecurrenceTime:
          List<String>.from(json[ApiKey.task_recurrence_time] ?? []),
      employeeId: json[ApiKey.employee_id] ?? 'Unknown',
      employeeName: json[ApiKey.employee_name] ?? '',
      isCanceled: (json[ApiKey.is_canceled]?.toString() ?? "0") == "1",
      parentId: json[ApiKey.parent_id]?.toString(),
      adminImg:
          (json[ApiKey.admin_img] != null && json[ApiKey.admin_img] is List)
              ? List<String>.from(
                  json[ApiKey.admin_img].map((e) => ShowNetImage.getPhoto(e)))
              : [],
      employeeImg: (json[ApiKey.employee_img] != null &&
              json[ApiKey.employee_img] is List)
          ? List<String>.from(
              json[ApiKey.employee_img].map((e) => ShowNetImage.getPhoto(e)))
          : [],
      audio: ShowNetImage.getPhoto(json[ApiKey.audio] ?? ''),
      subTasks: (json[ApiKey.sub_tasks] as List<dynamic>? ?? [])
          .map((e) => SubTaskModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.id: taskId,
      ApiKey.name: taskName,
      ApiKey.description: taskDescription,
      ApiKey.notes: notes,
      ApiKey.points: points.toString(),
      ApiKey.not_shown_for_employee: notShownForEmployee ? "1" : "0",
      ApiKey.start_time: startTime.toIso8601String(),
      ApiKey.end_time: endTime.toIso8601String(),
      ApiKey.status: status,
      ApiKey.is_forced_to_upload_img: isForcedToUploadImg ? "1" : "0",
      ApiKey.task_recurrence: taskRecurrence,
      ApiKey.task_recurrence_time: taskRecurrenceTime,
      ApiKey.employee_id: employeeId,
      ApiKey.employee_name: employeeName,
      ApiKey.is_canceled: isCanceled ? "1" : "0",
      ApiKey.parent_id: parentId,
      ApiKey.admin_img: adminImg,
      ApiKey.employee_img: employeeImg,
      ApiKey.audio: audio,
      ApiKey.sub_tasks:
          subTasks.map((e) => (e as SubTaskModel).toJson()).toList(),
    };
  }
}

class SubTaskModel extends SubTaskEntity {
  SubTaskModel({
    required int id,
    required String name,
    required String description,
    required String status,
    List<String>? adminImg,
    required bool isForcedToUploadImg,
  }) : super(
          id: id,
          name: name,
          description: description,
          status: status,
          adminImg: adminImg,
          isForcedToUploadImg: isForcedToUploadImg,
        );

  factory SubTaskModel.fromJson(Map<String, dynamic> json) {
    return SubTaskModel(
      id: json[ApiKey.id] ?? 0,
      name: json[ApiKey.name] ?? '',
      description: json[ApiKey.description] ?? '',
      status: json[ApiKey.status] ?? '',
      isForcedToUploadImg:
          (json[ApiKey.is_forced_to_upload_img]?.toString() ?? "0") == "1",
      adminImg:
          (json[ApiKey.admin_img] != null && json[ApiKey.admin_img] is List)
              ? List<String>.from(
                  json[ApiKey.admin_img].map((e) => ShowNetImage.getPhoto(e)))
              : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.id: id,
      ApiKey.name: name,
      ApiKey.description: description,
      ApiKey.status: status,
      ApiKey.admin_img: adminImg,
      ApiKey.is_forced_to_upload_img: isForcedToUploadImg ? "1" : "0",
    };
  }
}

class ImagesPathInfoModel extends ImagesPathInfoEntity {
  ImagesPathInfoModel({required String subtaskAdminImgPath})
      : super(subtaskAdminImgPath: subtaskAdminImgPath);

  factory ImagesPathInfoModel.fromJson(Map<String, dynamic> json) {
    return ImagesPathInfoModel(
      subtaskAdminImgPath: ShowNetImage.getPhoto(
        _emptyToNull(
          json[ApiKey.subtask_admin_img_path],
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.subtask_admin_img_path: subtaskAdminImgPath,
    };
  }

  static String? _emptyToNull(String? value) {
    if (value == null) return null;
    return (value.startsWith('public/') ||
            value != 'no employee image' &&
                value != 'no admin image' &&
                value != 'no audio')
        ? value
        : null;
  }
}
