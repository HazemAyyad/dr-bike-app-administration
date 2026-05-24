import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import 'initial_bindings.dart';

/// Maps FCM / notification payloads to employee screens.
class EmployeeNotificationRouter {
  static void handlePayload(Map<String, dynamic> raw) {
    if (userType != 'employee') {
      _openNotificationCenter();
      return;
    }

    final String type = raw['type']?.toString() ?? '';
    if (type == 'employee_daily_tasks' ||
        type == 'employee_hourly_reminder' ||
        type == 'employee_task_scheduled_reminder' ||
        type == 'employee_daily_tasks_complete' ||
        type == 'employee_task_assigned' ||
        type == 'employee_task_approved' ||
        type == 'employee_task_rejected' ||
        type == 'employee_task_co_subtask_done' ||
        type == 'employee_task_co_main_done' ||
        type == 'employee_task_co_main_completed') {
      if (_openDashboard()) {
        return;
      }
    }

    _openNotificationCenter();
  }

  static void _openNotificationCenter() {
    Get.toNamed(AppRoutes.EMPLOYEENOTIFICATIONCENTER);
  }

  static bool _openDashboard() {
    try {
      if (Get.currentRoute != AppRoutes.EMPLOYEEDASHBOARDSCREEN) {
        Get.until(
          (route) =>
              route.settings.name == AppRoutes.BOTTOMNAVBARSCREEN ||
              route.isFirst,
        );
      }
      return true;
    } catch (e) {
      debugPrint('[EmployeeNotificationRouter] dashboard: $e');
      return false;
    }
  }
}
