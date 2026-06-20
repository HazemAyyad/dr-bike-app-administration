class AdminUserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final bool isBlocked;
  final bool isOnline;
  final int activeSessionsCount;
  final int adminFcmDevicesCount;
  final String? fcmLabel;
  final DateTime? createdAt;

  const AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.isBlocked,
    required this.isOnline,
    required this.activeSessionsCount,
    required this.adminFcmDevicesCount,
    this.fcmLabel,
    this.createdAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      isBlocked: json['is_blocked'] == true || json['is_blocked'] == 1,
      isOnline: json['is_online'] == true || json['is_online'] == 1,
      activeSessionsCount:
          int.tryParse('${json['active_sessions_count']}') ?? 0,
      adminFcmDevicesCount:
          int.tryParse('${json['admin_fcm_devices_count']}') ?? 0,
      fcmLabel: json['fcm_label']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
