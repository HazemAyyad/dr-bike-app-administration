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
    if (type == 'employee_daily_tasks') {
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
