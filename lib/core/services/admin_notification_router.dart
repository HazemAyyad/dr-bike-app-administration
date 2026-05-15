import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import 'app_dependency_registry.dart';
import 'initial_bindings.dart';

/// Maps FCM / local notification payloads to screens (admin only).
class AdminNotificationRouter {
  static void handlePayload(Map<String, dynamic> raw) {
    if (userType != 'admin') {
      _openNotificationCenter();
      return;
    }

    final String type = raw['type']?.toString() ?? '';

    try {
      switch (type) {
        case 'employee_task_completed':
          final tid = raw['task_id']?.toString() ?? '';
          if (tid.isNotEmpty && _openTaskDetails(tid)) {
            return;
          }
          break;
        case 'check_due_reminder':
          if (_openChecks(raw)) {
            return;
          }
          break;
        case 'employee_login':
        case 'employee_logout_pending_tasks':
          if (_openEmployeeAttendance(raw)) {
            return;
          }
          break;
        default:
          break;
      }
    } catch (e, st) {
      debugPrint('[NotificationRouter] navigation failed: $e\n$st');
    }

    _openNotificationCenter();
  }

  static void _openNotificationCenter() {
    Get.toNamed(AppRoutes.NOTIFICATIONCENTER);
  }

  static bool _openTaskDetails(String taskId) {
    try {
      AppDependencyRegistry.ensureEmployeeTasks();
      Get.toNamed(
        AppRoutes.TASKDETAILS,
        arguments: {'taskId': taskId},
      );
      return true;
    } catch (e) {
      debugPrint('[NotificationRouter] task details unavailable: $e');
      return false;
    }
  }

  static bool _openChecks(Map<String, dynamic> raw) {
    try {
      AppDependencyRegistry.ensureChecks();
      final rt = raw['related_type']?.toString() ?? '';
      if (rt == 'incoming_check') {
        Get.toNamed(AppRoutes.INCOMINGCHECKSSCREEN);
      } else if (rt == 'outgoing_check') {
        Get.toNamed(AppRoutes.OUTGOINGCHECKSSCREEN);
      } else {
        Get.toNamed(AppRoutes.CHECKSSCREEN);
      }
      return true;
    } catch (e) {
      debugPrint('[NotificationRouter] checks unavailable: $e');
      return false;
    }
  }

  static bool _openEmployeeAttendance(Map<String, dynamic> raw) {
    try {
      AppDependencyRegistry.ensureEmployeeSection();
      final eid = raw['employee_id']?.toString() ?? '';
      final ename = raw['employee_name']?.toString() ?? ' ';
      if (eid.isEmpty) {
        return false;
      }
      Get.toNamed(
        AppRoutes.EMPLOYEEATTENDANCEHISTORY,
        arguments: {
          'employeeId': eid,
          'employeeName': ename,
        },
      );
      return true;
    } catch (e) {
      debugPrint('[NotificationRouter] employee screen unavailable: $e');
      return false;
    }
  }

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
