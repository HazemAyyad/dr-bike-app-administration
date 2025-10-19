import 'package:doctorbike/core/databases/api/end_points.dart';

class UserModel {
  final UserDataModel user;
  final List<PermissionModel> employeePermissions;

  UserModel({
    required this.user,
    required this.employeePermissions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      user: UserDataModel.fromJson(json[ApiKey.user] ?? {}),
      employeePermissions: (json[ApiKey.employee_permissions] as List? ?? [])
          .map((p) => PermissionModel.fromJson(p))
          .toList(),
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
    return UserDataModel(
      id: json[ApiKey.id] ?? 0,
      name: json[ApiKey.name] ?? '',
      email: json[ApiKey.email] ?? '',
      emailVerifiedAt: json[ApiKey.email_verified_at],
      phone: json[ApiKey.phone] ?? '',
      subPhone: json[ApiKey.sub_phone],
      city: json[ApiKey.city],
      address: json[ApiKey.address],
      createdAt: json[ApiKey.created_at] ?? '',
      updatedAt: json[ApiKey.updated_at] ?? '',
      type: json[ApiKey.type] ?? '',
      fcmToken: json[ApiKey.fcm_token],
      employee: EmployeeModel.fromJson(json[ApiKey.employee] ?? {}),
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
      id: json[ApiKey.id] ?? 0,
      userId: json['user_id'] ?? '',
      points: json['points'] ?? '0',
      hourWorkPrice: json['hour_work_price'] ?? '',
      overtimeWorkPrice: json['overtime_work_price'] ?? '',
      numberOfWorkHours: json['number_of_work_hours'] ?? '',
      startWorkTime: json['start_work_time'] ?? '',
      endWorkTime: json['end_work_time'] ?? '',
      jobTitle: json['job_title'],
      salary: json['salary'] ?? '',
      debts: json['debts'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      workTime: json['work_time'],
      employeeImg: json['employee_img'] ?? '',
      documentImg: json['document_img'] ?? '',
      totalWorkHours: json['total_work_hours'] ?? '',
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
      permissionId: json[ApiKey.permission_id] ?? 0,
      permissionName: json[ApiKey.permission_name] ?? '',
      permissionNameEn: json[ApiKey.permission_name_en] ?? '',
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
