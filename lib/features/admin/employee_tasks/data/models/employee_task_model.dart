import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/task_recurrence_rules.dart';
import 'package:doctorbike/core/helpers/audio_helper.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';
import 'package:doctorbike/core/helpers/task_media_paths.dart';

import '../../domain/entities/employee_task_entity.dart';
import '../../domain/entities/task_assignee_info.dart';

class EmployeeTaskModel extends EmployeeTaskEntity {
  EmployeeTaskModel({
    required int taskId,
    int? occurrenceId,
    String? parentId,
    String source = 'legacy',
    required String taskName,
    required String employeeId,
    required String employeeName,
    required DateTime startTime,
    required DateTime endTime,
    required bool isCanceled,
    String? employeeImg,
    String? employeePhoto,
    String? adminImg,
    String? audio,
    String status = 'pending',
    String priority = 'medium',
    int points = 0,
    int progress = 0,
    bool proofRequired = false,
    String taskRecurrence = 'noRepeat',
    List<String> taskRecurrenceTime = const [],
    int? templateId,
    List<int> assigneeIds = const [],
    List<TaskAssigneeInfo> assignees = const [],
    bool isShared = false,
    String assigneeLabel = '',
    List<String> subtaskNames = const [],
  }) : super(
          taskId: taskId,
          occurrenceId: occurrenceId,
          parentId: parentId,
          source: source,
          taskName: taskName,
          employeeId: employeeId,
          employeeName: employeeName,
          startTime: startTime,
          endTime: endTime,
          isCanceled: isCanceled,
          employeeImg: employeeImg,
          employeePhoto: employeePhoto,
          adminImg: adminImg,
          audio: audio,
          status: status,
          priority: priority,
          points: points,
          progress: progress,
          proofRequired: proofRequired,
          taskRecurrence: taskRecurrence,
          taskRecurrenceTime: taskRecurrenceTime,
          templateId: templateId,
          assigneeIds: assigneeIds,
          assignees: assignees,
          isShared: isShared,
          assigneeLabel: assigneeLabel,
          subtaskNames: subtaskNames,
        );

  factory EmployeeTaskModel.fromJson(Map<String, dynamic> json) {
    final trt = json[ApiKey.task_recurrence_time];
    final List<String> recurrenceTimes = trt is List
        ? trt.map((e) => e.toString()).toList()
        : const [];
    final assignees = _parseAssignees(json['assignees']);
    final assigneeIds = json['assignee_ids'] is List
        ? (json['assignee_ids'] as List).map((e) => asInt(e)).toList()
        : assignees.map((a) => a.id).toList();
    final assigneeLabel = asString(json['assignee_label']);
    final resolvedAssigneeLabel = assigneeLabel.isNotEmpty
        ? assigneeLabel
        : assignees.map((a) => a.name).where((n) => n.isNotEmpty).join(' · ');

    return EmployeeTaskModel(
      taskId: asInt(json[ApiKey.task_id]),
      occurrenceId:
          json['occurrence_id'] != null ? asInt(json['occurrence_id']) : null,
      parentId: asNullableString(json[ApiKey.parent_id]),
      source: asString(json['source'], 'legacy'),
      taskName: asString(json[ApiKey.task_name], 'Unknown'),
      employeeId: asString(json[ApiKey.employee_id], 'Unknown'),
      employeeName: asString(json[ApiKey.employee_name], 'Unknown'),
      startTime: parseApiDateTime(json[ApiKey.start_time]),
      endTime: parseApiDateTime(json[ApiKey.end_time]),
      isCanceled: asBool(json[ApiKey.is_canceled]),
      employeeImg:
          ShowNetImage.getPhoto(asNullableString(json[ApiKey.employee_img])),
      employeePhoto: ShowNetImage.getPhoto(
        asNullableString(json[ApiKey.employee_photo]),
      ),
      adminImg: ShowNetImage.getPhoto(asNullableString(json[ApiKey.admin_img])),
      audio: parseAudioFromApi(asNullableString(json[ApiKey.audio])),
      status: asString(json['status'], 'pending'),
      priority: asString(json['priority'], 'medium'),
      points: asInt(json['points']),
      progress: asInt(json['progress']),
      proofRequired: asBool(json['is_forced_to_upload_img']),
      taskRecurrence: asString(json[ApiKey.task_recurrence], 'noRepeat'),
      taskRecurrenceTime: recurrenceTimes,
      templateId: json['template_id'] != null ? asInt(json['template_id']) : null,
      assigneeIds: assigneeIds,
      assignees: assignees,
      isShared: json.containsKey('is_shared')
          ? asBool(json['is_shared'])
          : assigneeIds.length > 1,
      assigneeLabel: resolvedAssigneeLabel,
      subtaskNames: json['subtask_names'] is List
          ? (json['subtask_names'] as List)
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList()
          : const [],
    );
  }

  EmployeeTaskModel copyWithDisplayDate(DateTime day) {
    final start = DateTime(
      day.year,
      day.month,
      day.day,
      startTime.hour,
      startTime.minute,
      startTime.second,
      startTime.millisecond,
      startTime.microsecond,
    );
    var end = DateTime(
      day.year,
      day.month,
      day.day,
      endTime.hour,
      endTime.minute,
      endTime.second,
      endTime.millisecond,
      endTime.microsecond,
    );
    if (!end.isAfter(start)) {
      end = end.add(const Duration(days: 1));
    }
    return EmployeeTaskModel(
      taskId: taskId,
      occurrenceId: occurrenceId,
      parentId: parentId,
      source: source,
      taskName: taskName,
      employeeId: employeeId,
      employeeName: employeeName,
      startTime: start,
      endTime: end,
      isCanceled: isCanceled,
      employeeImg: employeeImg,
      employeePhoto: employeePhoto,
      adminImg: adminImg,
      audio: audio,
      status: status,
      priority: priority,
      points: points,
      progress: progress,
      proofRequired: proofRequired,
      taskRecurrence: taskRecurrence,
      taskRecurrenceTime: taskRecurrenceTime,
      templateId: templateId,
      assigneeIds: assigneeIds,
      assignees: assignees,
      isShared: isShared,
      assigneeLabel: assigneeLabel,
      subtaskNames: subtaskNames,
    );
  }

  /// Fresh calendar-day row for legacy recurring parents (not the anchor day).
  EmployeeTaskModel virtualDayInstance(DateTime day) {
    final displayed = copyWithDisplayDate(day);
    final isAnchorDay = TaskRecurrenceRules.sameDay(startTime, day);
    final isRecurringParent = TaskRecurrenceRules.isRecurringParent(
      source: source,
      parentId: parentId,
      recurrence: taskRecurrence,
    );
    if (!isRecurringParent || isAnchorDay) {
      return displayed;
    }
    return EmployeeTaskModel(
      taskId: taskId,
      occurrenceId: occurrenceId,
      parentId: parentId,
      source: source,
      taskName: taskName,
      employeeId: employeeId,
      employeeName: employeeName,
      startTime: displayed.startTime,
      endTime: displayed.endTime,
      isCanceled: isCanceled,
      employeeImg: null,
      employeePhoto: employeePhoto,
      adminImg: adminImg,
      audio: audio,
      status: 'pending',
      priority: priority,
      points: points,
      progress: 0,
      proofRequired: proofRequired,
      taskRecurrence: taskRecurrence,
      taskRecurrenceTime: taskRecurrenceTime,
      templateId: templateId,
      assigneeIds: assigneeIds,
      assignees: assignees,
      isShared: isShared,
      assigneeLabel: assigneeLabel,
      subtaskNames: subtaskNames,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.task_id: taskId,
      ApiKey.parent_id: parentId,
      'source': source,
      ApiKey.task_name: taskName,
      ApiKey.employee_name: employeeName,
      ApiKey.start_time: startTime.toIso8601String(),
      ApiKey.end_time: endTime.toIso8601String(),
      ApiKey.is_canceled: isCanceled ? '1' : '0',
      ApiKey.employee_img: employeeImg ?? 'no employee image',
      ApiKey.admin_img: adminImg ?? 'no admin image',
      ApiKey.audio: audio ?? 'no audio',
    };
  }
}

List<TaskAssigneeInfo> _parseAssignees(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((m) => _parseAssignee(Map<String, dynamic>.from(m)))
      .toList();
}

TaskAssigneeInfo _parseAssignee(Map<String, dynamic> json) {
  final photoRaw = asNullableString(json['photo']) ?? '';
  final photo =
      photoRaw.isEmpty || photoRaw == 'no images' || photoRaw == 'no image'
          ? ''
          : resolveTaskMediaUri(photoRaw);

  return TaskAssigneeInfo(
    id: asInt(json['id']),
    name: asString(json['name']),
    photoUrl: photo,
  );
}
