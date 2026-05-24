import 'package:get/get.dart';

import '../../../../../core/services/employee_notification_api_service.dart';
import '../../../../../core/services/initial_bindings.dart';
import 'employee_notification_badge_controller.dart';

class EmployeeNotificationCenterController extends GetxController {
  final EmployeeNotificationApiService _api = EmployeeNotificationApiService();

  final isLoading = false.obs;
  final isBusyAction = false.obs;
  final items = <Map<String, dynamic>>[].obs;
  final selectedFilter = 'all'.obs;

  static const List<Map<String, String>> filterDefs = [
    {'id': 'all', 'labelKey': 'notifFilterAll'},
    {'id': 'unread', 'labelKey': 'notifFilterUnread'},
    {'id': 'employee_daily_tasks', 'labelKey': 'notifFilterDailyTasks'},
    {'id': 'employee_hourly_reminder', 'labelKey': 'notifFilterHourlyReminder'},
    {'id': 'employee_daily_tasks_complete', 'labelKey': 'notifFilterTasksComplete'},
  ];

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (userType != 'employee') {
      return;
    }
    isLoading.value = true;
    try {
      final String f = selectedFilter.value;
      final bool unreadOnly = f == 'unread';
      final String? type = (f == 'all' || f == 'unread') ? null : f;

      final Map<String, dynamic> res = await _api.fetchNotifications(
        page: 1,
        perPage: 50,
        type: type,
        unreadOnly: unreadOnly ? true : null,
      );

      final dynamic block = res['notifications'];
      if (block is Map && block['data'] is List) {
        items.assignAll(
          (block['data'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
        );
      } else {
        items.clear();
      }
    } catch (_) {
      items.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _api.markAsRead(id);
      final idx = items.indexWhere((e) => e['id'] == id);
      if (idx >= 0) {
        items[idx] = {...items[idx], 'is_read': true};
        items.refresh();
      }
      if (Get.isRegistered<EmployeeNotificationBadgeController>()) {
        await Get.find<EmployeeNotificationBadgeController>().refresh();
      }
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    isBusyAction.value = true;
    try {
      await _api.markAllAsRead();
      await load();
      if (Get.isRegistered<EmployeeNotificationBadgeController>()) {
        await Get.find<EmployeeNotificationBadgeController>().refresh();
      }
    } finally {
      isBusyAction.value = false;
    }
  }

  Future<void> deleteOne(int id) async {
    isBusyAction.value = true;
    try {
      await _api.deleteNotification(id);
      items.removeWhere((e) => e['id'] == id);
      if (Get.isRegistered<EmployeeNotificationBadgeController>()) {
        await Get.find<EmployeeNotificationBadgeController>().refresh();
      }
    } finally {
      isBusyAction.value = false;
    }
  }

  void setFilter(String id) {
    selectedFilter.value = id;
    load();
  }
}
