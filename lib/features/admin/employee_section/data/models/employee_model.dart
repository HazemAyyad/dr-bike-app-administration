import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../domain/entities/employee_entity.dart';

class EmployeeModel extends EmployeeEntity {
  const EmployeeModel({
    required int id,
    required String name,
    required String hourWorkPrice,
    required String points,
    required String image,
  }) : super(
          id: id,
          employeeName: name,
          hourWorkPrice: hourWorkPrice,
          points: points,
          employeeImg: image,
        );

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return EmployeeModel(
      id: asInt(j[ApiKey.id]),
      name: asString(j[ApiKey.employee_name], 'unknown'),
      hourWorkPrice: asString(j[ApiKey.hour_work_price], '0'),
      points: asString(j[ApiKey.points], '0'),
      image: ShowNetImage.getPhoto(asNullableString(j[ApiKey.employee_img])),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.id: id,
      ApiKey.employee_name: employeeName,
      ApiKey.hour_work_price: hourWorkPrice,
      ApiKey.points: points,
      ApiKey.employee_img: employeeImg,
    };
  }
}
