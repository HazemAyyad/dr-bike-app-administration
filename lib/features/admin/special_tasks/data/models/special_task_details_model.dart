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
    return SpecialTaskDetailsModel(
      taskId: json['id'] ?? 0,
      taskName: json['name'] ?? '',
      taskDescription: json['description'] ?? '',
      notes: json['notes'] ?? '',
      adminImg: json['admin_img'] != null && json['admin_img'] != 'null'
          ? List<String>.from(
              json['admin_img'].map((e) => ShowNetImage.getPhoto(e)))
          : [],
      audio: ShowNetImage.getPhoto(json['audio']),
      taskRecurrence: json['task_recurrence'] ?? '',
      taskRecurrenceTime: List<String>.from(json['task_recurrence_time'] ?? []),
      subTasks: (json['sub_tasks'] as List<dynamic>? ?? [])
          .map((e) => SubTaskModel.fromJson(e))
          .toList(),
      startTime: DateTime.parse(json['start_time'] ?? DateTime.now()),
      endTime: DateTime.parse(json['end_time'] ?? DateTime.now()),
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
    return SubTaskModel(
      subTaskId: json['id'] ?? 0,
      specialTaskId: json['special_task_id'] ?? '',
      subTaskName: json['name'] ?? '',
      subTaskDescription: json['description'] ?? '',
      status: json['status'] ?? '',
      adminImg: json['admin_img'] != null && json['admin_img'] != 'null'
          ? List<String>.from(
              json['admin_img'].map((e) => ShowNetImage.getPhoto(e)))
          : [],
      forceEmployeeToAddImg:
          (json['force_employee_to_add_img_for_sub_task'] ?? "0") == "1",
    );
  }
}
