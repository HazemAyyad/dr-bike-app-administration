import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/services/admin_notification_api_service.dart';
import '../../../../../core/services/initial_bindings.dart';
import 'admin_notification_badge_controller.dart';

class AdminNotificationCenterController extends GetxController {
  final AdminNotificationApiService _api = AdminNotificationApiService();

  final isLoading = false.obs;
  final isBusyAction = false.obs;
  final items = <Map<String, dynamic>>[].obs;
  final selectedFilter = 'all'.obs;
  final search = ''.obs;
  final errorMessage = ''.obs;
  final hasMore = true.obs;
  final searchController = TextEditingController();
  int _page = 1;
  Worker? _searchWorker;

  static const List<Map<String, String>> filterDefs = [
    {'id': 'all', 'labelKey': 'notifFilterAll'},
    {'id': 'unread', 'labelKey': 'notifFilterUnread'},
    {'id': 'employee_login', 'labelKey': 'notifFilterLogin'},
    {'id': 'employee_task_completed', 'labelKey': 'notifFilterTaskDone'},
    {
      'id': 'employee_task_submitted',
      'labelKey': 'notifFilterTaskSubmitted',
    },
    {
      'id': 'employee_subtask_completed',
      'labelKey': 'notifFilterSubtaskDone',
    },
    {
      'id': 'employee_logout_pending_tasks',
      'labelKey': 'notifFilterLogoutPending',
    },
    {'id': 'check_due_reminder', 'labelKey': 'notifFilterChecks'},
    {'id': 'check_cashed', 'labelKey': 'notifFilterCheckCashed'},
    {'id': 'check_returned', 'labelKey': 'notifFilterCheckReturned'},
    {
      'id': 'sales_order_shiply_handover',
      'labelKey': 'notifFilterShiplyHandover',
    },
    {
      'id': 'sales_order_shiply_delivered',
      'labelKey': 'notifFilterShiplyDelivered',
    },
    {
      'id': 'sales_order_shiply_status',
      'labelKey': 'notifFilterShiplyStatus',
    },
  ];

  @override
  void onInit() {
    super.onInit();
    _searchWorker = debounce(
      search,
      (_) => load(),
      time: const Duration(milliseconds: 450),
    );
    load();
  }

  @override
  void onClose() {
    _searchWorker?.dispose();
    searchController.dispose();
    super.onClose();
  }

  Future<void> load({bool loadMore = false}) async {
    if (userType != 'admin') {
      return;
    }
    if (isLoading.value || (loadMore && !hasMore.value)) return;
    if (!loadMore) {
      _page = 1;
      hasMore.value = true;
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final String f = selectedFilter.value;
      final bool unreadOnly = f == 'unread';
      final String? type = (f == 'all' || f == 'unread') ? null : f;

      final Map<String, dynamic> res = await _api.fetchNotifications(
        page: _page,
        perPage: 25,
        type: type,
        unreadOnly: unreadOnly ? true : null,
        search: search.value,
      );

      final dynamic block = res['notifications'];
      if (block is Map && block['data'] is List) {
        final rows = (block['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        loadMore ? items.addAll(rows) : items.assignAll(rows);
        final current = int.tryParse('${block['current_page']}') ?? _page;
        final last = int.tryParse('${block['last_page']}') ?? current;
        hasMore.value = current < last;
        if (hasMore.value) _page = current + 1;
      } else if (!loadMore) {
        items.clear();
      }
    } catch (_) {
      errorMessage.value = 'تعذر تحميل الإشعارات. اسحب للتحديث وحاول مجدداً.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _api.markAsRead(id);
      final idx = items.indexWhere((e) => e['id'] == id);
      if (idx >= 0) {
        items[idx] = {
          ...items[idx],
          'is_read': true,
        };
        items.refresh();
      }
      if (Get.isRegistered<AdminNotificationBadgeController>()) {
        await Get.find<AdminNotificationBadgeController>().refresh();
      }
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    isBusyAction.value = true;
    try {
      await _api.markAllAsRead();
      await load();
      if (Get.isRegistered<AdminNotificationBadgeController>()) {
        await Get.find<AdminNotificationBadgeController>().refresh();
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
      if (Get.isRegistered<AdminNotificationBadgeController>()) {
        await Get.find<AdminNotificationBadgeController>().refresh();
      }
    } finally {
      isBusyAction.value = false;
    }
  }

  void setFilter(String id) {
    selectedFilter.value = id;
    load();
  }

  void setSearch(String value) => search.value = value.trim();

  int get unreadCount => items.where((row) {
        final read = row['is_read'];
        return read != true && read != 1;
      }).length;
}
