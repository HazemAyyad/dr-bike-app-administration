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
  }) : super(
          id: id,
          employeeName: employeeName,
          startWorkTime: startWorkTime,
          endWorkTime: endWorkTime,
          numberOfWorkHours: numberOfWorkHours,
          employeeImg: employeeImg,
        );

  factory WorkingTimesModel.fromJson(Map<String, dynamic> json) {
    return WorkingTimesModel(
      id: json[ApiKey.id] ?? 0,
      employeeName: json[ApiKey.user_name] ?? 'unknown',
      startWorkTime: json[ApiKey.start_work_time] ?? '00:00',
      endWorkTime: json[ApiKey.end_work_time] ?? '0',
      numberOfWorkHours: json[ApiKey.number_of_work_hours] ?? '0',
      employeeImg: ShowNetImage.getPhoto(json[ApiKey.employee_img]),
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
    };
  }
}
