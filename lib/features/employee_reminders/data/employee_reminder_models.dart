class EmployeeReminderItem {
  final int id;
  final int? employeeId;
  final String title;
  final String description;
  final DateTime scheduledAt;
  final DateTime? snoozedUntil;
  final String repeatType;
  final bool isActive;
  final String employeeName;
  final String status;
  final List<String> repeatDays;

  const EmployeeReminderItem({
    required this.id,
    required this.employeeId,
    required this.title,
    required this.description,
    required this.scheduledAt,
    required this.snoozedUntil,
    required this.repeatType,
    required this.isActive,
    required this.employeeName,
    required this.status,
    required this.repeatDays,
  });

  factory EmployeeReminderItem.fromAdminJson(Map<String, dynamic> json) {
    final employee = json['employee'];
    final user = employee is Map ? employee['user'] : null;
    final occurrences = json['occurrences'];
    String status = 'pending';
    if (occurrences is List &&
        occurrences.isNotEmpty &&
        occurrences.first is Map) {
      status = (occurrences.first['status'] ?? 'pending').toString();
    }

    return EmployeeReminderItem(
      id: _asInt(json['id']),
      employeeId: _nullableInt(json['employee_id']),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      scheduledAt: _asDate(json['scheduled_at']),
      snoozedUntil: null,
      repeatType: (json['repeat_type'] ?? 'once').toString(),
      repeatDays: _asStringList(json['repeat_days']),
      isActive: _asBool(json['is_active']),
      employeeName: user is Map
          ? (user['name'] ?? '').toString()
          : (employee is Map ? (employee['name'] ?? '').toString() : ''),
      status: status,
    );
  }

  factory EmployeeReminderItem.fromEmployeeJson(Map<String, dynamic> json) {
    final reminder = json['reminder'];
    final reminderMap = reminder is Map
        ? Map<String, dynamic>.from(reminder)
        : <String, dynamic>{};

    return EmployeeReminderItem(
      id: _asInt(json['id']),
      employeeId: _nullableInt(json['employee_id']),
      title: (reminderMap['title'] ?? '').toString(),
      description: (reminderMap['description'] ?? '').toString(),
      scheduledAt: _asDate(json['scheduled_at']),
      snoozedUntil: _nullableDate(json['snoozed_until']),
      repeatType: (reminderMap['repeat_type'] ?? 'once').toString(),
      repeatDays: _asStringList(reminderMap['repeat_days']),
      isActive: _asBool(reminderMap['is_active'], fallback: true),
      employeeName: '',
      status: (json['status'] ?? 'pending').toString(),
    );
  }
}

class ReminderEmployeeOption {
  final int id;
  final String name;
  final String image;

  const ReminderEmployeeOption({
    required this.id,
    required this.name,
    required this.image,
  });

  factory ReminderEmployeeOption.fromJson(Map<String, dynamic> json) {
    return ReminderEmployeeOption(
      id: _asInt(json['id']),
      name: (json['employee_name'] ?? json['name'] ?? 'موظف').toString(),
      image: (json['employee_img'] ?? '').toString(),
    );
  }
}

class EmployeeReminderHistoryItem {
  final int id;
  final String event;
  final String title;
  final String employeeName;
  final String actorName;
  final DateTime createdAt;
  final Map<String, dynamic> meta;

  const EmployeeReminderHistoryItem({
    required this.id,
    required this.event,
    required this.title,
    required this.employeeName,
    required this.actorName,
    required this.createdAt,
    required this.meta,
  });

  factory EmployeeReminderHistoryItem.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'];
    final employeeUser = employee is Map ? employee['user'] : null;
    final actor = json['actor'];

    return EmployeeReminderHistoryItem(
      id: _asInt(json['id']),
      event: (json['event'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      employeeName: employeeUser is Map
          ? (employeeUser['name'] ?? '').toString()
          : (employee is Map ? (employee['name'] ?? '').toString() : ''),
      actorName: actor is Map ? (actor['name'] ?? '').toString() : '',
      createdAt: _asDate(json['created_at']),
      meta: json['meta'] is Map
          ? Map<String, dynamic>.from(json['meta'] as Map)
          : const {},
    );
  }
}

int _asInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

int? _nullableInt(dynamic value) {
  final parsed = int.tryParse(value?.toString() ?? '');
  return parsed == 0 ? null : parsed;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return fallback;
}

DateTime _asDate(dynamic value) {
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}

DateTime? _nullableDate(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text);
}

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return const [];
}
