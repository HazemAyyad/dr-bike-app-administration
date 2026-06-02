import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/audio_helper.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

import '../../domain/entities/employee_task_entity.dart';

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
        );

  factory EmployeeTaskModel.fromJson(Map<String, dynamic> json) {
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
