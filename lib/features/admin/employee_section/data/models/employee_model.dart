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
    return EmployeeModel(
      id: json[ApiKey.id] ?? 0,
      name: json[ApiKey.employee_name] ?? 'unknown',
      hourWorkPrice: json[ApiKey.hour_work_price] ?? '0',
      points: json[ApiKey.points] ?? '0',
      image: ShowNetImage.getPhoto(json[ApiKey.employee_img]),
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
