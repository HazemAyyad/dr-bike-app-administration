class EmployeeDetailsEntity {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String subPhone;
  final String hourWorkPrice;
  final String overtimeWorkPrice;
  final String numberOfWorkHours;
  final String startWorkTime;
  final String endWorkTime;
  final String employeeImg;
  final String documentImg;
  final List<PermissionEntity> permissions;

  const EmployeeDetailsEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.subPhone,
    required this.hourWorkPrice,
    required this.overtimeWorkPrice,
    required this.numberOfWorkHours,
    required this.startWorkTime,
    required this.endWorkTime,
    required this.employeeImg,
    required this.documentImg,
    required this.permissions,
  });
}

class PermissionEntity {
  final int permissionId;
  final String permissionName;
  final String permissionNameEn;

  const PermissionEntity({
    required this.permissionId,
    required this.permissionName,
    required this.permissionNameEn,
  });
}
