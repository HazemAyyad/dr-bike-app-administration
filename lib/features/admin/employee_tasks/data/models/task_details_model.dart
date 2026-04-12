import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/json_safe_parser.dart';
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
    final trt = json[ApiKey.task_recurrence_time];
    final List<String> recurrenceTimes = trt is List
        ? trt.map((e) => asString(e)).toList()
        : <String>[];

    List<String> mapImgList(dynamic raw) {
      if (raw is! List) return [];
      return raw
          .map((e) => ShowNetImage.getPhoto(asNullableString(e)))
          .toList();
    }

    return TaskDetailsModel(
      taskId: asInt(json[ApiKey.id]),
      taskName: asString(json[ApiKey.name], 'Unknown'),
      taskDescription: asString(json[ApiKey.description]),
      notes: asString(json[ApiKey.notes]),
      points: asInt(json[ApiKey.points]),
      notShownForEmployee: asBool(json[ApiKey.not_shown_for_employee]),
      startTime: parseApiDateTime(
        json[ApiKey.start_time],
        DateTime.fromMillisecondsSinceEpoch(0),
      ),
      endTime: parseApiDateTime(
        json[ApiKey.end_time],
        DateTime.fromMillisecondsSinceEpoch(0),
      ),
      status: asString(json[ApiKey.status]),
      isForcedToUploadImg: asBool(json[ApiKey.is_forced_to_upload_img]),
      taskRecurrence: asString(json[ApiKey.task_recurrence]),
      taskRecurrenceTime: recurrenceTimes,
      employeeId: asString(json[ApiKey.employee_id], 'Unknown'),
      employeeName: asString(json[ApiKey.employee_name]),
      isCanceled: asBool(json[ApiKey.is_canceled]),
      parentId: asNullableString(json[ApiKey.parent_id]),
      adminImg: mapImgList(json[ApiKey.admin_img]),
      employeeImg: mapImgList(json[ApiKey.employee_img]),
      audio: ShowNetImage.getPhoto(asNullableString(json[ApiKey.audio])),
      subTasks: mapList(json[ApiKey.sub_tasks], SubTaskModel.fromJson),
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
    List<String>? employeeImg,
  }) : super(
          id: id,
          name: name,
          description: description,
          status: status,
          adminImg: adminImg,
          isForcedToUploadImg: isForcedToUploadImg,
          employeeImg: employeeImg,
        );

  factory SubTaskModel.fromJson(Map<String, dynamic> json) {
    List<String> mapImgList(dynamic raw) {
      if (raw is! List) return [];
      return raw
          .map((e) => ShowNetImage.getPhoto(asNullableString(e)))
          .toList();
    }

    return SubTaskModel(
      id: asInt(json[ApiKey.id]),
      name: asString(json[ApiKey.name]),
      description: asString(json[ApiKey.description]),
      status: asString(json[ApiKey.status]),
      isForcedToUploadImg: asBool(json[ApiKey.is_forced_to_upload_img]),
      adminImg: mapImgList(json[ApiKey.admin_img]),
      employeeImg: mapImgList(json[ApiKey.employee_img]),
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
      ApiKey.employee_img: employeeImg,
    };
  }
}

class ImagesPathInfoModel extends ImagesPathInfoEntity {
  ImagesPathInfoModel({required String subtaskAdminImgPath})
      : super(subtaskAdminImgPath: subtaskAdminImgPath);

  factory ImagesPathInfoModel.fromJson(Map<String, dynamic> json) {
    return ImagesPathInfoModel(
      subtaskAdminImgPath: ShowNetImage.getPhoto(
        _emptyToNull(asNullableString(json[ApiKey.subtask_admin_img_path])),
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
