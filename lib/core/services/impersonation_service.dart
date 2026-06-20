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

/// Admin or privileged employee enters another employee account; session can be restored.
class ImpersonationService {
  static const _originalTokenKey = 'impersonation_admin_token';
  static const _originalUserKey = 'impersonation_admin_user_json';
  static const _originalNameKey = 'impersonation_admin_name';
  static const _originalTypeKey = 'impersonation_impersonator_type';

  static const impersonationPermissionId = 43;

  static String impersonatorDisplayName = '';
  static String impersonatorType = '';

  static bool get canImpersonateEmployees =>
      userType == 'admin' || employeePermissions.contains(impersonationPermissionId);

  static Future<bool> get isActive async {
    final t = FinalClasses.getStorage.read(_originalTokenKey);
    return t != null && t.toString().isNotEmpty;
  }

  static Future<void> startFromLoginResponse(Map<String, dynamic> raw) async {
    if (await isActive) {
      throw Exception('impersonationAlreadyActive'.tr);
    }

    final data = Map<String, dynamic>.from(raw);
    if (!isLoginSuccessStatus(data['status'])) {
      throw Exception(data['message']?.toString() ?? 'impersonationFailed'.tr);
    }

    final token = data['token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('impersonationFailed'.tr);
    }

    final originalToken = UserData.userToken.isNotEmpty
        ? UserData.userToken
        : await UserData.getUserToken();
    final originalUser = await UserData.getSavedUser();
    if (originalToken.isEmpty || originalUser == null) {
      throw Exception('impersonationFailed'.tr);
    }

    await FinalClasses.getStorage.write(_originalTokenKey, originalToken);
    await FinalClasses.getStorage.write(
      _originalUserKey,
      jsonEncode(originalUser.toJson()),
    );

    final imp = data['impersonation'];
    if (imp is Map) {
      impersonatorDisplayName =
          imp['impersonator_name']?.toString() ??
              imp['admin_name']?.toString() ??
              '';
      impersonatorType = imp['impersonator_type']?.toString() ??
          (imp['admin_name'] != null ? 'admin' : userType);
      await FinalClasses.getStorage.write(_originalNameKey, impersonatorDisplayName);
      await FinalClasses.getStorage.write(_originalTypeKey, impersonatorType);
    } else {
      impersonatorType = userType;
      await FinalClasses.getStorage.write(_originalTypeKey, impersonatorType);
    }

    await UserData.saveToken(token);
    UserData.userToken = token;

    UserModel userModel;
    try {
      userModel = UserModel.fromJson(data);
    } catch (e) {
      await UserData.saveToken(originalToken);
      UserData.userToken = originalToken;
      await UserData.saveUser(originalUser);
      throw Exception('impersonationFailed: $e');
    }

    final role = userModel.user.type.toLowerCase();
    if (role != 'employee') {
      await UserData.saveToken(originalToken);
      UserData.userToken = originalToken;
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

  static Future<void> exitToOriginal() async {
    final originalToken =
        FinalClasses.getStorage.read(_originalTokenKey)?.toString();
    final originalJson =
        FinalClasses.getStorage.read(_originalUserKey)?.toString();
    final savedType =
        FinalClasses.getStorage.read(_originalTypeKey)?.toString() ?? 'admin';
    if (originalToken == null ||
        originalToken.isEmpty ||
        originalJson == null ||
        originalJson.isEmpty) {
      return;
    }

    await UserData.saveToken(originalToken);
    await UserData.saveUserJson(originalJson);

    final userdata = await UserData.getSavedUser();
    if (userdata != null) {
      syncSessionIdentity(
        type: userdata.user.type,
        name: userdata.user.name,
        permissionIds:
            userdata.employeePermissions.map((p) => p.permissionId).toList(),
      );
    }
    UserData.userToken = originalToken;

    final returningToAdmin = savedType == 'admin';
    await _clearBackup();
    impersonatorDisplayName = '';
    impersonatorType = '';

    await SessionService.hydrateToken();
    await _navigateToShell(registerEmployeeShell: !returningToAdmin);
    if (returningToAdmin) {
      await _registerAdminShell();
    } else {
      await _registerEmployeeShell();
    }

    if (returningToAdmin) {
      try {
        await NotificationFirebaseService.instance
            .registerAdminDeviceTokenIfReady(source: 'exit_impersonation');
      } catch (_) {}
    }

    if (Get.isSnackbarOpen) Get.closeAllSnackbars();
    Get.rawSnackbar(
      message: returningToAdmin
          ? 'impersonationExitSuccess'.tr
          : 'impersonationExitSuccessEmployee'.tr,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
      backgroundColor: const Color(0xFF374151),
      messageText: Text(
        returningToAdmin
            ? 'impersonationExitSuccess'.tr
            : 'impersonationExitSuccessEmployee'.tr,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  /// Backward-compatible alias.
  static Future<void> exitToAdmin() => exitToOriginal();

  static String get exitButtonLabel =>
      impersonatorType == 'employee'
          ? 'exitImpersonationEmployee'.tr
          : 'exitImpersonation'.tr;

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

  static Future<void> loadImpersonatorInfoIfActive() async {
    if (!await isActive) return;
    impersonatorDisplayName =
        FinalClasses.getStorage.read(_originalNameKey)?.toString() ?? '';
    impersonatorType =
        FinalClasses.getStorage.read(_originalTypeKey)?.toString() ?? 'admin';
  }

  static Future<void> loadAdminNameIfImpersonating() =>
      loadImpersonatorInfoIfActive();

  static Future<void> _clearBackup() async {
    await FinalClasses.getStorage.remove(_originalTokenKey);
    await FinalClasses.getStorage.remove(_originalUserKey);
    await FinalClasses.getStorage.remove(_originalNameKey);
    await FinalClasses.getStorage.remove(_originalTypeKey);
  }
}
