import 'dart:convert';

import 'package:flutter/material.dart';
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
      if (type.startsWith('sales_order_status_') && _openSalesOrder(raw)) {
        return;
      }

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
          if (_openCheckSummary(raw)) {
            return;
          }
          if (_openChecks(raw)) {
            return;
          }
          break;
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
        case 'social_message_received':
          if (_openSocialConversation(raw)) {
            return;
          }
          break;
        case 'support_message':
          if (_openSupportConversation(raw)) {
            return;
          }
          break;
        case 'app_development_task':
          if (_openAppDevelopmentTask(raw)) {
            return;
          }
          break;
        case 'stock_images_export_ready':
          if (_openStockImagesExport(raw)) {
            return;
          }
          break;
        case 'employee_points_changed':
        case 'employee_reward_earned':
          if (_openEmployeePoints()) {
            return;
          }
          break;
        case 'maintenance_daily_closing_request':
        case 'maintenance_daily_previous_day_open':
          Get.toNamed(
            AppRoutes.SALESDAILYHISTORYSCREEN,
            arguments: {'sessionType': 'maintenance'},
          );
          return;
        case 'sales_daily_closing_request':
        case 'sales_daily_previous_day_open':
        case 'sales_daily_reopen_request':
          final sessionType = raw['session_type']?.toString();
          Get.toNamed(
            AppRoutes.SALESDAILYHISTORYSCREEN,
            arguments: {
              'sessionType': sessionType == 'sales_orders'
                  ? 'sales_orders'
                  : 'instant_sales',
            },
          );
          return;
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

  static bool _openCheckSummary(Map<String, dynamic> raw) {
    if (raw['is_summary']?.toString() != '1') return false;

    final checks = _decodeList(raw['checks']);
    if (checks.isEmpty) return false;

    Get.bottomSheet<void>(
      Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(Get.context!).size.height * .82,
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(Get.context!).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Text(
                  'تفاصيل الشيكات المستحقة (${checks.length})',
                  style: Theme.of(Get.context!).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    itemCount: checks.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final check = checks[index];
                      final incoming = check['direction'] == 'incoming';
                      final owner = check['owner']?.toString() ?? '';
                      final bank = check['bank']?.toString() ?? '';
                      final amount = check['amount']?.toString() ?? '0';
                      final currency = check['currency']?.toString() ?? '';

                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        leading: CircleAvatar(
                          backgroundColor: incoming
                              ? Colors.green.withValues(alpha: .12)
                              : Colors.orange.withValues(alpha: .12),
                          child: Icon(
                            incoming ? Icons.south_west : Icons.north_east,
                            color: incoming ? Colors.green : Colors.orange,
                          ),
                        ),
                        title: Text(
                          'شيك ${incoming ? 'وارد' : 'صادر'} رقم ${check['number'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          [
                            if (owner.isNotEmpty) owner,
                            if (bank.isNotEmpty) bank,
                            '${check['due_date'] ?? ''}',
                          ].where((value) => value.isNotEmpty).join(' · '),
                        ),
                        trailing: Text(
                          '$amount $currency',
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onTap: () {
                          Get.back<void>();
                          _openChecks({
                            'related_type':
                                incoming ? 'incoming_check' : 'outgoing_check',
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
    return true;
  }

  static List<Map<String, dynamic>> _decodeList(dynamic value) {
    dynamic decoded = value;
    if (value is String && value.isNotEmpty) {
      try {
        decoded = jsonDecode(value);
      } catch (_) {
        return <Map<String, dynamic>>[];
      }
    }
    if (decoded is! List) return <Map<String, dynamic>>[];
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
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

  static bool _openSocialConversation(Map<String, dynamic> raw) {
    final id = int.tryParse(raw['conversation_id']?.toString() ?? '');
    if (id == null || id <= 0) return false;
    Get.toNamed(
      '/WhatsAppConversation/$id',
      parameters: {'channel': raw['channel']?.toString() ?? 'whatsapp'},
    );
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

  static bool _openAppDevelopmentTask(Map<String, dynamic> raw) {
    final id = int.tryParse(
      raw['app_development_task_id']?.toString() ??
          raw['task_id']?.toString() ??
          raw['related_id']?.toString() ??
          '',
    );
    if (id == null || id <= 0) return false;
    Get.toNamed('/AppDevelopment/$id');
    return true;
  }

  static bool _openStockImagesExport(Map<String, dynamic> raw) {
    try {
      AppDependencyRegistry.ensureStock();
      final exportId =
          raw['export_id']?.toString() ?? raw['related_id']?.toString() ?? '';
      Get.toNamed(
        AppRoutes.STOCKIMAGESEXPORTSSCREEN,
        arguments: {
          if (exportId.isNotEmpty) 'stockImagesExportId': exportId,
        },
      );
      return true;
    } catch (e) {
      debugPrint('[NotificationRouter] stock export unavailable: $e');
      return false;
    }
  }

  static bool _openEmployeePoints() {
    try {
      AppDependencyRegistry.ensureEmployeeSection();
      Get.toNamed(AppRoutes.GLOBALEMPLOYEEPOINTSSCREEN);
      return true;
    } catch (e) {
      debugPrint('[NotificationRouter] employee points unavailable: $e');
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
