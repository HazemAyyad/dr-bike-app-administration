import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/admin/sales/presentation/controllers/sales_controller.dart';
import '../../routes/app_routes.dart';
import 'app_dependency_registry.dart';
import 'initial_bindings.dart';

/// Maps FCM / notification payloads to employee screens.
class EmployeeNotificationRouter {
  static const String typeReopenApproved = 'sales_daily_reopen_approved';
  static const String typeReopenRejected = 'sales_daily_reopen_rejected';
  static const String typeClosingApproved = 'sales_daily_closing_approved';
  static const String typeClosingRejected = 'sales_daily_closing_rejected';

  static void handlePayload(Map<String, dynamic> raw) {
    if (userType != 'employee') {
      _openNotificationCenter();
      return;
    }

    final type = raw['type']?.toString() ?? '';
    switch (type) {
      case typeReopenApproved:
        openSalesAndRefreshDailySession(
          successMessage: 'salesDailyReopenApproved'.tr,
        );
        return;
      case typeReopenRejected:
        openSalesAndRefreshDailySession(
          infoMessage: 'salesDailyReopenRejected'.tr,
        );
        return;
      case typeClosingApproved:
        openSalesAndRefreshDailySession(
          infoMessage: 'salesDailyDayClosed'.tr,
        );
        return;
      case typeClosingRejected:
        openSalesAndRefreshDailySession(
          infoMessage: 'salesDailyClosingRejected'.tr,
        );
        return;
    }

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

  static Future<void> openSalesAndRefreshDailySession({
    String? successMessage,
    String? infoMessage,
  }) async {
    try {
      AppDependencyRegistry.ensureSales();

      await _refreshSalesDailySession();

      final current = Get.currentRoute;
      if (current != AppRoutes.SALESSCREEN) {
        if (_isSalesDailySubRoute(current)) {
          Get.until(
            (route) =>
                route.settings.name == AppRoutes.SALESSCREEN || route.isFirst,
          );
        } else {
          await Get.toNamed(AppRoutes.SALESSCREEN);
        }
        await _refreshSalesDailySession();
      }

      if (successMessage != null && successMessage.isNotEmpty) {
        Get.snackbar(
          'success'.tr,
          successMessage,
          backgroundColor: Colors.green.shade700,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
        );
      } else if (infoMessage != null && infoMessage.isNotEmpty) {
        Get.snackbar(
          'notificationCenterTitle'.tr,
          infoMessage,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e, st) {
      debugPrint('[EmployeeNotificationRouter] sales screen: $e\n$st');
      _openNotificationCenter();
    }
  }

  static bool _isSalesDailySubRoute(String? route) {
    if (route == null) return false;
    return route == AppRoutes.SALESDAILYCLOSESCREEN ||
        route == AppRoutes.SALESDAILYHISTORYSCREEN ||
        route == AppRoutes.SALESDAILYSESSIONDETAILSCREEN ||
        route == AppRoutes.SALESDAILYADMINSCREEN;
  }

  static Future<void> _refreshSalesDailySession() async {
    for (var i = 0; i < 8; i++) {
      if (Get.isRegistered<SalesController>()) {
        await Get.find<SalesController>().loadDailySession();
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
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
