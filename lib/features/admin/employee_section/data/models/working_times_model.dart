import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../domain/entities/working_times_entity.dart';

class WorkingTimesModel extends WorkingTimesEntity {
  const WorkingTimesModel({
    required int id,
    required String employeeName,
    required String startWorkTime,
    required String endWorkTime,
    required String numberOfWorkHours,
    required String employeeImg,
    required bool hasAttendedToday,
    required bool isWorkingNow,
    required bool isCameOnTime,
  }) : super(
          id: id,
          employeeName: employeeName,
          startWorkTime: startWorkTime,
          endWorkTime: endWorkTime,
          numberOfWorkHours: numberOfWorkHours,
          employeeImg: employeeImg,
          hasAttendedToday: hasAttendedToday,
          isWorkingNow: isWorkingNow,
          isCameOnTime: isCameOnTime,
        );

  factory WorkingTimesModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return WorkingTimesModel(
      id: asInt(j[ApiKey.id]),
      employeeName: asString(j[ApiKey.user_name], 'unknown'),
      startWorkTime: asString(j[ApiKey.start_work_time], '00:00'),
      endWorkTime: asString(j[ApiKey.end_work_time], '0'),
      numberOfWorkHours: asString(j[ApiKey.number_of_work_hours], '0'),
      employeeImg: ShowNetImage.getPhoto(asNullableString(j[ApiKey.employee_img])),
      hasAttendedToday: asBool(j['has_attended_today']),
      isWorkingNow: asBool(j['is_working_now']),
      isCameOnTime: asBool(j['is_came_on_time']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.id: id,
      ApiKey.user_name: employeeName,
      ApiKey.start_work_time: startWorkTime,
      ApiKey.end_work_time: endWorkTime,
      ApiKey.number_of_work_hours: numberOfWorkHours,
      ApiKey.employee_img: employeeImg,
      'has_attended_today': hasAttendedToday,
      'is_working_now': isWorkingNow,
      'is_came_on_time': isCameOnTime,
    };
  }
}
