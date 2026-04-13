import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

import '../../domain/entities/special_task_details_entities.dart';

class SpecialTaskDetailsModel extends SpecialTaskDetailsEntities {
  SpecialTaskDetailsModel({
    required int taskId,
    required String taskName,
    required String taskDescription,
    required List<String> adminImg,
    required String taskRecurrence,
    required String notes,
    required List<String> taskRecurrenceTime,
    required List<SubTaskModel> subTasks,
    required DateTime startTime,
    required DateTime endTime,
    required String audio,
  }) : super(
          taskId: taskId,
          taskName: taskName,
          taskDescription: taskDescription,
          adminImg: adminImg,
          notes: notes,
          taskRecurrence: taskRecurrence,
          taskRecurrenceTime: taskRecurrenceTime,
          subTasks: subTasks,
          startTime: startTime,
          endTime: endTime,
          audio: audio,
        );

  factory SpecialTaskDetailsModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    List<String> mapAdminImg(dynamic raw) {
      if (raw == null || raw == 'null') return [];
      if (raw is! List) return [];
      return raw
          .map((e) => ShowNetImage.getPhoto(asNullableString(e)))
          .toList();
    }

    List<String> mapRecurrenceTimes(dynamic raw) {
      if (raw is! List) return [];
      return raw.map((e) => asString(e)).toList();
    }

    return SpecialTaskDetailsModel(
      taskId: asInt(j['id']),
      taskName: asString(j['name']),
      taskDescription: asString(j['description']),
      notes: asString(j['notes']),
      adminImg: mapAdminImg(j['admin_img']),
      audio: ShowNetImage.getPhoto(asNullableString(j['audio'])),
      taskRecurrence: asString(j['task_recurrence']),
      taskRecurrenceTime: mapRecurrenceTimes(j['task_recurrence_time']),
      subTasks: mapList(
        j['sub_tasks'],
        (Map<String, dynamic> m) => SubTaskModel.fromJson(m),
      ),
      startTime: parseApiDateTime(j['start_time']),
      endTime: parseApiDateTime(j['end_time']),
    );
  }
}

class SubTaskModel extends SubTaskEntity {
  SubTaskModel({
    required int subTaskId,
    required String specialTaskId,
    required String subTaskName,
    required String subTaskDescription,
    required String status,
    required List<String> adminImg,
    required bool forceEmployeeToAddImg,
  }) : super(
          subTaskId: subTaskId,
          specialTaskId: specialTaskId,
          subTaskName: subTaskName,
          subTaskDescription: subTaskDescription,
          status: status,
          adminImg: adminImg,
          forceEmployeeToAddImg: forceEmployeeToAddImg,
        );

  factory SubTaskModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    List<String> mapAdminImg(dynamic raw) {
      if (raw == null || raw == 'null') return [];
      if (raw is! List) return [];
      return raw
          .map((e) => ShowNetImage.getPhoto(asNullableString(e)))
          .toList();
    }

    return SubTaskModel(
      subTaskId: asInt(j['id']),
      specialTaskId: asString(j['special_task_id']),
      subTaskName: asString(j['name']),
      subTaskDescription: asString(j['description']),
      status: asString(j['status']),
      adminImg: mapAdminImg(j['admin_img']),
      forceEmployeeToAddImg:
          asBool(j['force_employee_to_add_img_for_sub_task']),
    );
  }
}
