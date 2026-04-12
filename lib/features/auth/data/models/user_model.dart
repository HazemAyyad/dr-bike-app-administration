import 'package:doctorbike/core/databases/api/end_points.dart';

import 'login_response_parser.dart';

/// تحويل آمن لقيم الـ API (int/double/String/null) إلى [String].
String asString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

/// حقول اختيارية قد تكون null أو فارغة بعد التحويل.
String? asNullableString(dynamic value) {
  if (value == null) return null;
  final s = value.toString();
  return s.isEmpty ? null : s;
}

/// [id] وغيره من الأعداد الصحيحة في JSON قد يصل كـ int أو double أو String.
int asInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

class UserModel {
  final UserDataModel user;
  final List<PermissionModel> employeePermissions;

  UserModel({
    required this.user,
    required this.employeePermissions,
  });

  /// يدعم الاستجابة المباشرة أو الملفوفة داخل [data] بعد [unwrapLoginEnvelope].
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final root = unwrapLoginEnvelope(Map<String, dynamic>.from(json));
    final epRaw = root[ApiKey.employee_permissions];
    final List<PermissionModel> permissions = [];
    if (epRaw is List) {
      for (final p in epRaw) {
        if (p is Map) {
          permissions.add(
            PermissionModel.fromJson(Map<String, dynamic>.from(p)),
          );
        }
      }
    }
    final userRaw = root[ApiKey.user];
    return UserModel(
      user: UserDataModel.fromJson(
        userRaw is Map
            ? Map<String, dynamic>.from(userRaw)
            : <String, dynamic>{},
      ),
      employeePermissions: permissions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.user: user.toJson(),
      ApiKey.employee_permissions:
          employeePermissions.map((p) => p.toJson()).toList(),
    };
  }
}

class UserDataModel {
  final int id;
  final String name;
  final String email;
  final String? emailVerifiedAt;
  final String phone;
  final String? subPhone;
  final String? city;
  final String? address;
  final String createdAt;
  final String updatedAt;
  final String type;
  final String? fcmToken;
  final EmployeeModel employee;

  UserDataModel({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    required this.phone,
    this.subPhone,
    this.city,
    this.address,
    required this.createdAt,
    required this.updatedAt,
    required this.type,
    this.fcmToken,
    required this.employee,
  });

  factory UserDataModel.fromJson(Map<String, dynamic> json) {
    final emp = json[ApiKey.employee];
    return UserDataModel(
      id: asInt(json[ApiKey.id]),
      name: asString(json[ApiKey.name]),
      email: asString(json[ApiKey.email]),
      emailVerifiedAt: asNullableString(json[ApiKey.email_verified_at]),
      phone: asString(json[ApiKey.phone]),
      subPhone: asNullableString(json[ApiKey.sub_phone]),
      city: asNullableString(json[ApiKey.city]),
      address: asNullableString(json[ApiKey.address]),
      createdAt: asString(json[ApiKey.created_at]),
      updatedAt: asString(json[ApiKey.updated_at]),
      type: asString(json[ApiKey.type]),
      fcmToken: asNullableString(json[ApiKey.fcm_token]),
      employee: EmployeeModel.fromJson(
        emp is Map ? Map<String, dynamic>.from(emp) : <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.id: id,
      ApiKey.name: name,
      ApiKey.email: email,
      ApiKey.email_verified_at: emailVerifiedAt,
      ApiKey.phone: phone,
      ApiKey.sub_phone: subPhone,
      ApiKey.city: city,
      ApiKey.address: address,
      ApiKey.created_at: createdAt,
      ApiKey.updated_at: updatedAt,
      ApiKey.type: type,
      ApiKey.fcm_token: fcmToken,
      ApiKey.employee: employee.toJson(),
    };
  }
}

class EmployeeModel {
  final int id;
  final String userId;
  final String points;
  final String hourWorkPrice;
  final String overtimeWorkPrice;
  final String numberOfWorkHours;
  final String startWorkTime;
  final String endWorkTime;
  final String? jobTitle;
  final String salary;
  final String debts;
  final String createdAt;
  final String updatedAt;
  final String? workTime;
  final String employeeImg;
  final String documentImg;
  final String totalWorkHours;

  EmployeeModel({
    required this.id,
    required this.userId,
    required this.points,
    required this.hourWorkPrice,
    required this.overtimeWorkPrice,
    required this.numberOfWorkHours,
    required this.startWorkTime,
    required this.endWorkTime,
    this.jobTitle,
    required this.salary,
    required this.debts,
    required this.createdAt,
    required this.updatedAt,
    this.workTime,
    required this.employeeImg,
    required this.documentImg,
    required this.totalWorkHours,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: asInt(json[ApiKey.id]),
      userId: asString(json['user_id']),
      points: asString(json['points'], '0'),
      hourWorkPrice: asString(json['hour_work_price']),
      overtimeWorkPrice: asString(json['overtime_work_price']),
      numberOfWorkHours: asString(json['number_of_work_hours']),
      startWorkTime: asString(json['start_work_time']),
      endWorkTime: asString(json['end_work_time']),
      jobTitle: asNullableString(json['job_title']),
      salary: asString(json['salary']),
      debts: asString(json['debts']),
      createdAt: asString(json['created_at']),
      updatedAt: asString(json['updated_at']),
      workTime: asNullableString(json['work_time']),
      employeeImg: asString(json['employee_img']),
      documentImg: asString(json['document_img']),
      totalWorkHours: asString(json['total_work_hours']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'points': points,
      'hour_work_price': hourWorkPrice,
      'overtime_work_price': overtimeWorkPrice,
      'number_of_work_hours': numberOfWorkHours,
      'start_work_time': startWorkTime,
      'end_work_time': endWorkTime,
      'job_title': jobTitle,
      'salary': salary,
      'debts': debts,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'work_time': workTime,
      'employee_img': employeeImg,
      'document_img': documentImg,
      'total_work_hours': totalWorkHours,
    };
  }
}

class PermissionModel {
  final int permissionId;
  final String permissionName;
  final String permissionNameEn;

  PermissionModel({
    required this.permissionId,
    required this.permissionName,
    required this.permissionNameEn,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      permissionId: asInt(json[ApiKey.permission_id]),
      permissionName: asString(json[ApiKey.permission_name]),
      permissionNameEn: asString(json[ApiKey.permission_name_en]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.permission_id: permissionId,
      ApiKey.permission_name: permissionName,
      ApiKey.permission_name_en: permissionNameEn,
    };
  }
}
