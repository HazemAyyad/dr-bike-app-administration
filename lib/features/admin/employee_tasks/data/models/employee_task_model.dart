import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

import '../../domain/entities/employee_task_entity.dart';

class EmployeeTaskModel extends EmployeeTaskEntity {
  EmployeeTaskModel({
    required int taskId,
    required String taskName,
    required String employeeId,
    required String employeeName,
    required DateTime startTime,
    required DateTime endTime,
    required bool isCanceled,
    String? employeeImg,
    String? adminImg,
    String? audio,
  }) : super(
          taskId: taskId,
          taskName: taskName,
          employeeId: employeeId,
          employeeName: employeeName,
          startTime: startTime,
          endTime: endTime,
          isCanceled: isCanceled,
          employeeImg: employeeImg,
          adminImg: adminImg,
          audio: audio,
        );

  factory EmployeeTaskModel.fromJson(Map<String, dynamic> json) {
    return EmployeeTaskModel(
      taskId: json[ApiKey.task_id] ?? 0,
      taskName: json[ApiKey.task_name] ?? 'Unknown',
      employeeId: json[ApiKey.employee_id] ?? 'Unknown',
      employeeName: json[ApiKey.employee_name] ?? 'Unknown',
      startTime: DateTime.parse(json[ApiKey.start_time] ?? DateTime.now()),
      endTime: DateTime.parse(json[ApiKey.end_time] ?? DateTime.now()),
      isCanceled: (json[ApiKey.is_canceled] ?? '0') == '1',
      employeeImg: ShowNetImage.getPhoto(json[ApiKey.employee_img]),
      adminImg: ShowNetImage.getPhoto(json[ApiKey.admin_img]),
      audio: ShowNetImage.getPhoto(json[ApiKey.audio]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.task_id: taskId,
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

  // static String? _emptyToNull(String? value) {
  //   if (value == null) return null;
  //   return (value.startsWith('public/') ||
  //           value != 'no employee image' &&
  //               value != 'no admin image' &&
  //               value != 'no audio')
  //       ? value
  //       : null;
  // }
}
