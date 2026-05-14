import 'dart:convert';

import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../services/initial_bindings.dart';

/// Maps FCM / local notification payloads to screens (admin only).
class AdminNotificationRouter {
  static void handlePayload(Map<String, dynamic> raw) {
    if (userType != 'admin') {
      Get.toNamed(AppRoutes.NOTIFICATIONCENTER);
      return;
    }

    final String type = raw['type']?.toString() ?? '';

    try {
      switch (type) {
        case 'employee_task_completed':
          final tid = raw['task_id']?.toString() ?? '';
          if (tid.isNotEmpty) {
            Get.toNamed(
              AppRoutes.TASKDETAILS,
              arguments: {'taskId': tid},
            );
            return;
          }
          break;
        case 'check_due_reminder':
          final rt = raw['related_type']?.toString() ?? '';
          if (rt == 'incoming_check') {
            Get.toNamed(AppRoutes.INCOMINGCHECKSSCREEN);
            return;
          }
          if (rt == 'outgoing_check') {
            Get.toNamed(AppRoutes.OUTGOINGCHECKSSCREEN);
            return;
          }
          Get.toNamed(AppRoutes.CHECKSSCREEN);
          return;
        case 'employee_login':
        case 'employee_logout_pending_tasks':
          final eid = raw['employee_id']?.toString() ?? '';
          final ename = raw['employee_name']?.toString() ?? ' ';
          if (eid.isNotEmpty) {
            Get.toNamed(
              AppRoutes.EMPLOYEEATTENDANCEHISTORY,
              arguments: {
                'employeeId': eid,
                'employeeName': ename,
              },
            );
            return;
          }
          break;
        default:
          break;
      }
    } catch (_) {
      // fall through
    }

    Get.toNamed(AppRoutes.NOTIFICATIONCENTER);
  }

  /// Parse payload from local notification plugin (JSON string) or raw map.
  static Map<String, dynamic> parsePayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return {};
  }
}
