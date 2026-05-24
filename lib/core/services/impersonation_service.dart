import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../features/admin/admin_dashbord/presentation/controllers/admin_dashboard_controller.dart';
import '../../features/admin/notifications/presentation/controllers/admin_notification_badge_controller.dart';
import '../../features/auth/data/models/login_response_parser.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/bottom_nav_bar/binding/binding.dart';
import '../../features/bottom_nav_bar/controllers/bottom_nav_bar_controller.dart';
import '../../features/bottom_nav_bar/views/bottom_nav_bar_screen.dart';
import '../../features/employee/employee_dashbord/presentation/controllers/employee_dashbord_controller.dart';
import '../../features/employee/notifications/presentation/controllers/employee_notification_badge_controller.dart';
import '../../routes/app_routes.dart';
import 'final_classes.dart';
import 'initial_bindings.dart';
import 'notification_firebase_service.dart';
import 'session_service.dart';
import 'user_data.dart';

/// Admin enters an employee account without password; session can be restored.
class ImpersonationService {
  static const _adminTokenKey = 'impersonation_admin_token';
  static const _adminUserKey = 'impersonation_admin_user_json';
  static const _adminNameKey = 'impersonation_admin_name';

  static String adminDisplayName = '';

  static Future<bool> get isActive async {
    final t = FinalClasses.getStorage.read(_adminTokenKey);
    return t != null && t.toString().isNotEmpty;
  }

  static Future<void> startFromLoginResponse(Map<String, dynamic> raw) async {
    final data = Map<String, dynamic>.from(raw);
    if (!isLoginSuccessStatus(data['status'])) {
      throw Exception(data['message']?.toString() ?? 'impersonationFailed'.tr);
    }

    final token = data['token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('impersonationFailed'.tr);
    }

    final adminToken = UserData.userToken.isNotEmpty
        ? UserData.userToken
        : await UserData.getUserToken();
    final adminUser = await UserData.getSavedUser();
    if (adminToken.isEmpty || adminUser == null) {
      throw Exception('impersonationFailed'.tr);
    }

    await FinalClasses.getStorage.write(_adminTokenKey, adminToken);
    await FinalClasses.getStorage.write(
      _adminUserKey,
      jsonEncode(adminUser.toJson()),
    );

    final imp = data['impersonation'];
    if (imp is Map) {
      adminDisplayName = imp['admin_name']?.toString() ?? '';
      await FinalClasses.getStorage.write(_adminNameKey, adminDisplayName);
    }

    await UserData.saveToken(token);
    UserData.userToken = token;

    UserModel userModel;
    try {
      userModel = UserModel.fromJson(data);
    } catch (e) {
      await UserData.saveToken(adminToken);
      UserData.userToken = adminToken;
      await UserData.saveUser(adminUser);
      throw Exception('impersonationFailed: $e');
    }

    final role = userModel.user.type.toLowerCase();
    if (role != 'employee') {
      await UserData.saveToken(adminToken);
      UserData.userToken = adminToken;
      throw Exception('impersonationFailed'.tr);
    }

    await UserData.saveUser(userModel);

    syncSessionIdentity(
      type: 'employee',
      name: userModel.user.name,
      permissionIds:
          userModel.employeePermissions.map((p) => p.permissionId).toList(),
    );

    await SessionService.hydrateToken();
    await _navigateToShell(registerEmployeeShell: true);

  }

  static Future<void> _registerEmployeeShell() async {
    try {
      if (Get.isRegistered<AdminNotificationBadgeController>()) {
        await Get.delete<AdminNotificationBadgeController>(force: true);
      }
      if (!Get.isRegistered<EmployeeNotificationBadgeController>()) {
        Get.put(EmployeeNotificationBadgeController(), permanent: true);
      }
      await Get.find<EmployeeNotificationBadgeController>().refresh();
    } catch (_) {
      // Do not block impersonation if notifications fail.
    }
  }

  static Future<void> _resetShellControllers() async {
    if (Get.isRegistered<BottomNavBarController>()) {
      await Get.delete<BottomNavBarController>(force: true);
    }
    if (Get.isRegistered<AdminDashboardController>()) {
      await Get.delete<AdminDashboardController>(force: true);
    }
    if (Get.isRegistered<EmployeeDashbordController>()) {
      await Get.delete<EmployeeDashbordController>(force: true);
    }
  }

  static Future<void> exitToAdmin() async {
    final adminToken = FinalClasses.getStorage.read(_adminTokenKey)?.toString();
    final adminJson = FinalClasses.getStorage.read(_adminUserKey)?.toString();
    if (adminToken == null ||
        adminToken.isEmpty ||
        adminJson == null ||
        adminJson.isEmpty) {
      return;
    }

    await UserData.saveToken(adminToken);
    await UserData.saveUserJson(adminJson);

    final userdata = await UserData.getSavedUser();
    if (userdata != null) {
      syncSessionIdentity(
        type: userdata.user.type,
        name: userdata.user.name,
        permissionIds:
            userdata.employeePermissions.map((p) => p.permissionId).toList(),
      );
    }
    UserData.userToken = adminToken;

    await _clearBackup();
    adminDisplayName = '';

    await SessionService.hydrateToken();
    await _navigateToShell(registerEmployeeShell: false);
    await _registerAdminShell();

    try {
      await NotificationFirebaseService.instance
          .registerAdminDeviceTokenIfReady(source: 'exit_impersonation');
    } catch (_) {}

    if (Get.isSnackbarOpen) Get.closeAllSnackbars();
    Get.rawSnackbar(
      message: 'impersonationExitSuccess'.tr,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
      backgroundColor: const Color(0xFF374151),
      messageText: Text(
        'impersonationExitSuccess'.tr,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  /// Rebuilds bottom nav without racing [sessionEpoch] against a deleted controller.
  static Future<void> _navigateToShell({
    required bool registerEmployeeShell,
  }) async {
    await _resetShellControllers();
    BottomNavBarBinding().dependencies();

    await Get.offAll(
      () => const BottomNavBarScreen(),
      binding: BottomNavBarBinding(),
      routeName: AppRoutes.BOTTOMNAVBARSCREEN,
    );

    SchedulerBinding.instance.addPostFrameCallback((_) {
      sessionEpoch.value++;
    });

    if (registerEmployeeShell) {
      await _registerEmployeeShell();
    }
  }

  static Future<void> _registerAdminShell() async {
    try {
      if (Get.isRegistered<EmployeeNotificationBadgeController>()) {
        await Get.delete<EmployeeNotificationBadgeController>(force: true);
      }
      if (!Get.isRegistered<AdminNotificationBadgeController>()) {
        Get.put(AdminNotificationBadgeController(), permanent: true);
      }
      await Get.find<AdminNotificationBadgeController>().refresh();
    } catch (_) {}
  }

  static Future<void> loadAdminNameIfImpersonating() async {
    if (!await isActive) return;
    adminDisplayName =
        FinalClasses.getStorage.read(_adminNameKey)?.toString() ?? '';
  }

  static Future<void> _clearBackup() async {
    await FinalClasses.getStorage.remove(_adminTokenKey);
    await FinalClasses.getStorage.remove(_adminUserKey);
    await FinalClasses.getStorage.remove(_adminNameKey);
  }
}
