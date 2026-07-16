import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';

import '../../features/admin/checks/presentation/binding/checks_binding.dart';
import '../../features/admin/checks/presentation/controllers/checks_controller.dart';
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
    if (type.isEmpty) {
      _openNotificationCenter();
      return;
    }

    try {
      switch (type) {
        case 'employee_task_completed':
        case 'employee_task_submitted':
        case 'employee_subtask_completed':
          final tid = raw['task_id']?.toString() ??
              raw['occurrence_id']?.toString() ??
              '';
          if (tid.isNotEmpty && _openTaskDetails(tid)) {
            return;
          }
          break;
        case 'check_due_reminder':
        case 'check_cashed':
        case 'check_returned':
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
        case 'sales_order_shiply_handover':
        case 'sales_order_shiply_delivered':
        case 'sales_order_shiply_status':
        case 'sales_order_status':
          if (_openSalesOrder(raw)) {
            return;
          }
          break;
        case 'whatsapp_message_received':
          if (_openWhatsAppConversation(raw)) {
            return;
          }
          break;
        case 'support_message':
          if (_openSupportConversation(raw)) {
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
      if (!Get.isRegistered<ChecksController>()) {
        ChecksBinding().dependencies();
      }
      final c = Get.find<ChecksController>();
      final rt = raw['related_type']?.toString() ?? '';

      if (rt == 'incoming_check') {
        c.isInComing = true;
        c.pullToRefresh();
        Get.toNamed(AppRoutes.INCOMINGCHECKSSCREEN);
      } else if (rt == 'outgoing_check') {
        c.isInComing = false;
        c.pullToRefresh();
        Get.toNamed(AppRoutes.OUTGOINGCHECKSSCREEN);
      } else {
        Get.toNamed(AppRoutes.CHECKSSCREEN);
      }
      return true;
    } catch (e, st) {
      debugPrint('[NotificationRouter] checks unavailable: $e\n$st');
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

  static bool _openSalesOrder(Map<String, dynamic> raw) {
    try {
      AppDependencyRegistry.ensureSalesOrders();
      final orderId = int.tryParse(
        raw['sales_order_id']?.toString() ??
            raw['related_id']?.toString() ??
            '',
      );
      if (orderId == null || orderId <= 0) {
        return false;
      }
      Get.toNamed(AppRoutes.SALESORDERDETAILSCREEN, arguments: orderId);
      return true;
    } catch (e) {
      debugPrint('[NotificationRouter] sales order screen unavailable: $e');
      return false;
    }
  }

  static bool _openWhatsAppConversation(Map<String, dynamic> raw) {
    final id = int.tryParse(raw['conversation_id']?.toString() ?? '');
    if (id == null || id <= 0) return false;
    Get.toNamed('/WhatsAppConversation/$id');
    return true;
  }

  static bool _openSupportConversation(Map<String, dynamic> raw) {
    final id = int.tryParse(
      raw['conversation_id']?.toString() ??
          raw['support_conversation_id']?.toString() ??
          '',
    );
    if (id == null || id <= 0) return false;
    Get.toNamed('/TechnicalSupport/$id');
    return true;
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
