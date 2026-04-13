import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

import '../../domain/entities/employee_details_entity.dart';

List<String> _imageUrlList(dynamic raw) {
  if (raw is! List) return [];
  return raw
      .map((img) => ShowNetImage.getPhoto(asNullableString(img)))
      .toList();
}

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
    required List<String> employeeImg,
    required List<String> documentImg,
    required List<PermissionEntity> permissions,
    required List<RewardPunishmentEntity> rewardPunishment,
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
          rewardPunishment: rewardPunishment,
        );

  factory EmployeeDetailsModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    final details = asMap(j[ApiKey.employee_details]);
    return EmployeeDetailsModel(
      id: asInt(details[ApiKey.id]),
      name: asString(details[ApiKey.name], 'Unknown'),
      email: asString(details[ApiKey.email], 'Unknown'),
      phone: asString(details[ApiKey.phone], 'Unknown'),
      subPhone: asString(details[ApiKey.sub_phone], 'Unknown'),
      hourWorkPrice: asString(details[ApiKey.hour_work_price], '0'),
      overtimeWorkPrice: asString(details[ApiKey.overtime_work_price], '0'),
      numberOfWorkHours: asString(details[ApiKey.number_of_work_hours], '0'),
      startWorkTime: asString(details[ApiKey.start_work_time]),
      endWorkTime: asString(details[ApiKey.end_work_time]),
      employeeImg: _imageUrlList(details[ApiKey.employee_img]),
      documentImg: _imageUrlList(details[ApiKey.document_img]),
      permissions: mapList(
        j[ApiKey.permissions],
        (Map<String, dynamic> m) => PermissionModel.fromJson(m),
      ),
      rewardPunishment: mapList(
        j['rewards_and_punishments'],
        (Map<String, dynamic> m) => RewardPunishmentModel.fromJson(m),
      ),
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
    final j = Map<String, dynamic>.from(json);
    return PermissionModel(
      permissionId: asInt(j[ApiKey.permission_id]),
      permissionName: asString(j[ApiKey.permission_name]),
      permissionNameEn: asString(j[ApiKey.permission_name_en]),
    );
  }
}

class RewardPunishmentModel extends RewardPunishmentEntity {
  const RewardPunishmentModel({
    required String points,
    required String notes,
    required String type,
  }) : super(
          points: points,
          notes: notes,
          type: type,
        );

  factory RewardPunishmentModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return RewardPunishmentModel(
      points: asString(j['points']),
      notes: asString(j['notes']),
      type: asString(j['type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points,
      'notes': notes,
      'type': type,
    };
  }
}
