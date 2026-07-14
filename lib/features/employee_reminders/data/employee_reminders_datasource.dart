import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';

import 'employee_reminder_models.dart';

class EmployeeRemindersDatasource {
  final DioConsumer api;

  const EmployeeRemindersDatasource({required this.api});

  Future<List<EmployeeReminderItem>> getAdminReminders({String? status}) async {
    final response = await api.get(
      EndPoints.employeeReminders,
      queryParameters: {if (status != null) 'status': status},
    );
    return _items(
      response.data,
      (json) => EmployeeReminderItem.fromAdminJson(json),
    );
  }

  Future<List<EmployeeReminderItem>> getMyReminders({
    String? status,
    bool dueOnly = false,
  }) async {
    final response = await api.get(
      EndPoints.employeeMyReminders,
      queryParameters: {
        if (status != null) 'status': status,
        if (dueOnly) 'due_only': '1',
      },
    );
    return _items(
      response.data,
      (json) => EmployeeReminderItem.fromEmployeeJson(json),
    );
  }

  Future<List<ReminderEmployeeOption>> getEmployees() async {
    final response = await api.get(EndPoints.employees);
    final raw = response.data;
    final list = _extractList(raw, const ['employees', 'data']);
    return list
        .whereType<Map>()
        .map((e) =>
            ReminderEmployeeOption.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id > 0)
        .toList();
  }

  Future<void> createReminder({
    required List<int> employeeIds,
    required String title,
    required String description,
    required DateTime scheduledAt,
    required String repeatType,
    List<String> repeatDays = const [],
  }) async {
    await api.post(
      EndPoints.employeeReminders,
      data: {
        'employee_ids': employeeIds,
        'title': title,
        'description': description,
        'scheduled_at': scheduledAt.toIso8601String(),
        'repeat_type': repeatType,
        if (repeatDays.isNotEmpty) 'repeat_days': repeatDays,
      },
    );
  }

  Future<List<EmployeeReminderHistoryItem>> getHistory(int reminderId) async {
    final response =
        await api.get(EndPoints.employeeReminderHistory(reminderId));
    final raw = response.data;
    final list = _extractList(raw, const ['history']);
    return list
        .whereType<Map>()
        .map((e) =>
            EmployeeReminderHistoryItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> deleteReminder(int id) async {
    await api.delete(EndPoints.employeeReminder(id));
  }

  Future<void> markDone(int id) async {
    await api.post(EndPoints.employeeReminderDone(id));
  }

  Future<void> snooze(int id, {int minutes = 30}) async {
    await api.post(
      EndPoints.employeeReminderSnooze(id),
      data: {'minutes': minutes},
    );
  }

  List<EmployeeReminderItem> _items(
    dynamic raw,
    EmployeeReminderItem Function(Map<String, dynamic>) mapper,
  ) {
    final list = _extractList(raw, const ['reminders', 'data']);
    return list
        .whereType<Map>()
        .map((e) => mapper(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<dynamic> _extractList(dynamic raw, List<String> keys) {
    dynamic current = raw;
    for (final key in keys) {
      if (current is Map && current[key] != null) {
        current = current[key];
      }
    }
    if (current is List) return current;
    if (raw is Map && raw['data'] is List) return raw['data'] as List;
    return const [];
  }
}
