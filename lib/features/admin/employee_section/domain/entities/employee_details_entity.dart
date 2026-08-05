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
  final bool fingerprintEnabled;
  final String? deviceUserId;
  final String? lastFingerprintScanAt;
  final String? lastFingerprintAttendanceAt;
  final bool currentlyInToday;
  final List<String> employeeImg;
  final List<String> documentImg;
  final List<String> weeklyDaysOff;
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
    this.fingerprintEnabled = false,
    this.deviceUserId,
    this.lastFingerprintScanAt,
    this.lastFingerprintAttendanceAt,
    this.currentlyInToday = false,
    required this.employeeImg,
    required this.documentImg,
    required this.weeklyDaysOff,
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
