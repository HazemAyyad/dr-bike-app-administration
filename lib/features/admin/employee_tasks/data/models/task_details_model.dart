import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/audio_helper.dart';
import '../../../../../core/helpers/json_safe_parser.dart';
import '../../../../../core/helpers/proof_media_type.dart';
import '../../../../../core/helpers/task_media_paths.dart';
import '../../domain/entities/task_assignee_info.dart';
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
    String proofMediaType = ProofMediaType.none,
    bool requiresAdminReview = true,
    required String taskRecurrence,
    required List<String> taskRecurrenceTime,
    required String employeeId,
    List<int> assigneeIds = const [],
    List<TaskAssigneeInfo> assignees = const [],
    required String employeeName,
    required bool isCanceled,
    String? parentId,
    List<String>? adminImg,
    List<String>? adminVideos,
    List<String>? employeeImg,
    List<String>? employeeVideos,
    String? audio,
    required List<SubTaskModel> subTasks,
    List<Map<String, dynamic>> timeline = const [],
    int progress = 0,
    String priority = 'medium',
    String? rejectionNotes,
    int? templateId,
    int? occurrenceId,
    Map<String, dynamic>? recurrenceConfig,
    String? reminderWhen,
    String? reminderChannel,
    int? completedByEmployeeId,
    String? completedByName,
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
          proofMediaType: proofMediaType,
          requiresAdminReview: requiresAdminReview,
          taskRecurrence: taskRecurrence,
          taskRecurrenceTime: taskRecurrenceTime,
          employeeId: employeeId,
          assigneeIds: assigneeIds,
          assignees: assignees,
          employeeName: employeeName,
          isCanceled: isCanceled,
          parentId: parentId,
          adminImg: adminImg,
          adminVideos: adminVideos,
          employeeImg: employeeImg,
          employeeVideos: employeeVideos,
          audio: audio,
          subTasks: subTasks,
          timeline: timeline,
          progress: progress,
          priority: priority,
          rejectionNotes: rejectionNotes,
          templateId: templateId,
          occurrenceId: occurrenceId,
          recurrenceConfig: recurrenceConfig,
          reminderWhen: reminderWhen,
          reminderChannel: reminderChannel,
          completedByEmployeeId: completedByEmployeeId,
          completedByName: completedByName,
        );

  factory TaskDetailsModel.fromJson(Map<String, dynamic> json) {
    final trt = json[ApiKey.task_recurrence_time];
    final List<String> recurrenceTimes =
        trt is List ? trt.map((e) => asString(e)).toList() : <String>[];

    final adminMedia = parseTaskMediaFromApi(json[ApiKey.admin_img]);
    final employeeMedia = parseTaskMediaFromApi(json[ApiKey.employee_img]);

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
      proofMediaType: ProofMediaType.normalize(
        asNullableString(json[ApiKey.proof_media_type]),
        required: asBool(json[ApiKey.is_forced_to_upload_img]),
      ),
      requiresAdminReview: asBool(json['requires_admin_review'], true),
      taskRecurrence: asString(json[ApiKey.task_recurrence]),
      taskRecurrenceTime: recurrenceTimes,
      employeeId: asString(json[ApiKey.employee_id], 'Unknown'),
      assigneeIds: json['assignee_ids'] is List
          ? (json['assignee_ids'] as List).map((e) => asInt(e)).toList()
          : const [],
      assignees: _parseAssignees(json['assignees']),
      employeeName: asString(json[ApiKey.employee_name]),
      isCanceled: asBool(json[ApiKey.is_canceled]),
      parentId: asNullableString(json[ApiKey.parent_id]),
      adminImg: adminMedia.images,
      adminVideos: adminMedia.videos,
      employeeImg: employeeMedia.images,
      employeeVideos: employeeMedia.videos,
      audio: parseAudioFromApi(asNullableString(json[ApiKey.audio])),
      subTasks: mapList(
        json[ApiKey.sub_tasks] ?? json['subtasks'],
        (Map<String, dynamic> m) => SubTaskModel.fromJson(m),
      ),
      timeline: json['timeline'] is List
          ? (json['timeline'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList()
          : [],
      progress: asInt(json['progress']),
      priority: asString(json['priority'], 'medium'),
      rejectionNotes: asNullableString(json['rejection_notes']),
      templateId:
          json['template_id'] != null ? asInt(json['template_id']) : null,
      occurrenceId:
          json['occurrence_id'] != null ? asInt(json['occurrence_id']) : null,
      recurrenceConfig: json['recurrence_config'] is Map
          ? Map<String, dynamic>.from(json['recurrence_config'] as Map)
          : null,
      reminderWhen: asNullableString(json['reminder_when']),
      reminderChannel: asNullableString(json['reminder_channel']),
      completedByEmployeeId: json['completed_by_employee_id'] != null
          ? asInt(json['completed_by_employee_id'])
          : null,
      completedByName: asNullableString(json['completed_by_name']),
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
      ApiKey.proof_media_type: proofMediaType,
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

List<TaskAssigneeInfo> _parseAssignees(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((m) => TaskAssigneeModel.fromJson(Map<String, dynamic>.from(m)))
      .toList();
}

class TaskAssigneeModel extends TaskAssigneeInfo {
  TaskAssigneeModel({
    required int id,
    required String name,
    String photoUrl = '',
  }) : super(id: id, name: name, photoUrl: photoUrl);

  factory TaskAssigneeModel.fromJson(Map<String, dynamic> json) {
    final photoRaw = asNullableString(json['photo']) ?? '';
    final photo =
        photoRaw.isEmpty || photoRaw == 'no images' || photoRaw == 'no image'
            ? ''
            : resolveTaskMediaUri(photoRaw);

    return TaskAssigneeModel(
      id: asInt(json['id']),
      name: asString(json['name']),
      photoUrl: photo,
    );
  }
}

class SubTaskModel extends SubTaskEntity {
  SubTaskModel({
    required int id,
    required String name,
    required String description,
    required String status,
    List<String>? adminImg,
    List<String>? adminVideos,
    String? adminAudio,
    required bool isForcedToUploadImg,
    String proofMediaType = ProofMediaType.none,
    List<String>? employeeImg,
    List<String>? employeeVideos,
    int? completedByEmployeeId,
    String? completedByName,
  }) : super(
          id: id,
          name: name,
          description: description,
          status: status,
          adminImg: adminImg,
          adminVideos: adminVideos,
          adminAudio: adminAudio,
          isForcedToUploadImg: isForcedToUploadImg,
          proofMediaType: proofMediaType,
          employeeImg: employeeImg,
          employeeVideos: employeeVideos,
          completedByEmployeeId: completedByEmployeeId,
          completedByName: completedByName,
        );

  factory SubTaskModel.fromJson(Map<String, dynamic> json) {
    final adminMedia = parseSubtaskAdminMediaFromApi(json[ApiKey.admin_img]);
    final employeeMedia = parseTaskMediaFromApi(json[ApiKey.employee_img]);

    return SubTaskModel(
      id: asInt(json[ApiKey.id]),
      name: asString(json[ApiKey.name]),
      description: asString(json[ApiKey.description]),
      status: asString(json[ApiKey.status]),
      isForcedToUploadImg: asBool(json[ApiKey.is_forced_to_upload_img]),
      proofMediaType: ProofMediaType.normalize(
        asNullableString(json[ApiKey.proof_media_type]),
        required: asBool(json[ApiKey.is_forced_to_upload_img]),
      ),
      adminImg: adminMedia.images,
      adminVideos: adminMedia.videos,
      adminAudio: adminMedia.audio,
      employeeImg: employeeMedia.images,
      employeeVideos: employeeMedia.videos,
      completedByEmployeeId: json['completed_by_employee_id'] != null
          ? asInt(json['completed_by_employee_id'])
          : null,
      completedByName: asNullableString(json['completed_by_name']),
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
      ApiKey.proof_media_type: proofMediaType,
      ApiKey.employee_img: employeeImg,
    };
  }
}

class ImagesPathInfoModel extends ImagesPathInfoEntity {
  ImagesPathInfoModel({required String subtaskAdminImgPath})
      : super(subtaskAdminImgPath: subtaskAdminImgPath);

  factory ImagesPathInfoModel.fromJson(Map<String, dynamic> json) {
    return ImagesPathInfoModel(
      subtaskAdminImgPath: resolveTaskMediaUri(
        asNullableString(json[ApiKey.subtask_admin_img_path]) ?? '',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.subtask_admin_img_path: subtaskAdminImgPath,
    };
  }
}
