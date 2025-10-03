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
  final List<String> employeeImg;
  final List<String> documentImg;
  final List<PermissionEntity> permissions;
  final List<RewardPunishmentEntity> rewardPunishment;

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
    required this.rewardPunishment,
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

class RewardPunishmentEntity {
  final String points;
  final String notes;
  final String type; // "add" or "minus"

  const RewardPunishmentEntity({
    required this.points,
    required this.notes,
    required this.type,
  });
}
