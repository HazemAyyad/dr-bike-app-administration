import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

import '../../domain/entities/employee_details_entity.dart';

class EmployeeDetailsModel extends EmployeeDetailsEntity {
  const EmployeeDetailsModel({
    required int id,
    required String name,
    required String email,
    required String phone,
    required String subPhone,
    required String hourWorkPrice,
    required String overtimeWorkPrice,
    required String numberOfWorkHours,
    required String startWorkTime,
    required String endWorkTime,
    required String employeeImg,
    required String documentImg,
    required List<PermissionEntity> permissions,
  }) : super(
          id: id,
          name: name,
          email: email,
          phone: phone,
          subPhone: subPhone,
          hourWorkPrice: hourWorkPrice,
          overtimeWorkPrice: overtimeWorkPrice,
          numberOfWorkHours: numberOfWorkHours,
          startWorkTime: startWorkTime,
          endWorkTime: endWorkTime,
          employeeImg: employeeImg,
          documentImg: documentImg,
          permissions: permissions,
        );

  factory EmployeeDetailsModel.fromJson(Map<String, dynamic> json) {
    return EmployeeDetailsModel(
      id: json[ApiKey.employee_details][ApiKey.id],
      name: json[ApiKey.employee_details][ApiKey.name],
      email: json[ApiKey.employee_details][ApiKey.email],
      phone: json[ApiKey.employee_details][ApiKey.phone],
      subPhone: json[ApiKey.employee_details][ApiKey.sub_phone],
      hourWorkPrice: json[ApiKey.employee_details][ApiKey.hour_work_price],
      overtimeWorkPrice: json[ApiKey.employee_details]
          [ApiKey.overtime_work_price],
      numberOfWorkHours: json[ApiKey.employee_details]
          [ApiKey.number_of_work_hours],
      startWorkTime: json[ApiKey.employee_details][ApiKey.start_work_time],
      endWorkTime: json[ApiKey.employee_details][ApiKey.end_work_time],
      employeeImg: ShowNetImage.getPhoto(
          json[ApiKey.employee_details][ApiKey.employee_img]),
      documentImg: ShowNetImage.getPhoto(
          json[ApiKey.employee_details][ApiKey.document_img]),
      permissions: (json[ApiKey.permissions] as List)
          .map((p) => PermissionModel.fromJson(p))
          .toList(),
    );
  }
}

class PermissionModel extends PermissionEntity {
  const PermissionModel({
    required int permissionId,
    required String permissionName,
    required String permissionNameEn,
  }) : super(
          permissionId: permissionId,
          permissionName: permissionName,
          permissionNameEn: permissionNameEn,
        );

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      permissionId: json[ApiKey.permission_id],
      permissionName: json[ApiKey.permission_name],
      permissionNameEn: json[ApiKey.permission_name_en],
    );
  }
}
