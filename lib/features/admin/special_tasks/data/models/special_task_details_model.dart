import 'package:doctorbike/core/helpers/show_net_image.dart';

import '../../domain/entities/special_task_details_entities.dart';

class SpecialTaskDetailsModel extends SpecialTaskDetailsEntities {
  SpecialTaskDetailsModel({
    required int taskId,
    required String taskName,
    required String taskDescription,
    required String adminImg,
    required String taskRecurrence,
    required List<String> taskRecurrenceTime,
    required List<SubTaskModel> subTasks,
  }) : super(
          taskId: taskId,
          taskName: taskName,
          taskDescription: taskDescription,
          adminImg: adminImg,
          taskRecurrence: taskRecurrence,
          taskRecurrenceTime: taskRecurrenceTime,
          subTasks: subTasks,
        );

  factory SpecialTaskDetailsModel.fromJson(
    Map<String, dynamic> json,
    Map<String, dynamic> imagePaths,
  ) {
    final taskPath = imagePaths['task_admin_img_path'] ?? '';
    final subtaskPath = imagePaths['subtask_admin_img_path'] ?? '';

    return SpecialTaskDetailsModel(
      taskId: json['id'] ?? 0,
      taskName: json['name'] ?? '',
      taskDescription: json['description'] ?? '',
      adminImg: ShowNetImage.getPhoto("$taskPath/${json['admin_img'] ?? ''}"),
      taskRecurrence: json['task_recurrence'] ?? '',
      taskRecurrenceTime: List<String>.from(json['task_recurrence_time'] ?? []),
      subTasks: (json['sub_tasks'] as List<dynamic>? ?? [])
          .map((e) => SubTaskModel.fromJson(e, subtaskPath))
          .toList(),
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
    required String adminImg,
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

  factory SubTaskModel.fromJson(Map<String, dynamic> json, String subtaskPath) {
    return SubTaskModel(
      subTaskId: json['id'] ?? 0,
      specialTaskId: json['special_task_id'] ?? '',
      subTaskName: json['name'] ?? '',
      subTaskDescription: json['description'] ?? '',
      status: json['status'] ?? '',
      adminImg:
          ShowNetImage.getPhoto("$subtaskPath/${json['admin_img'] ?? ''}"),
      forceEmployeeToAddImg:
          (json['force_employee_to_add_img_for_sub_task'] ?? "0") == "1",
    );
  }
}
