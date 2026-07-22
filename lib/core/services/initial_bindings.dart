import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/admin/notifications/presentation/controllers/admin_notification_badge_controller.dart';
import '../../features/employee/notifications/presentation/controllers/employee_notification_badge_controller.dart';
import 'app_bootstrap.dart';
import 'app_dependency_registry.dart';
import 'app_home_widget_service.dart';
import 'app_shortcut_service.dart';
import 'app_startup.dart';
import 'app_version_tracking_service.dart';
import 'employee_attendance_persistent_notification_service.dart';
import 'notification_firebase_service.dart';
import 'session_service.dart';
import 'user_data.dart';

String userType = '';

/// Reactive role for bottom nav / home — [userType] alone does not rebuild GetX widgets.
final RxString sessionUserType = ''.obs;

/// Bumped on impersonation / role switch so bottom nav rebuilds.
final RxInt sessionEpoch = 0.obs;

RxBool startApp = true.obs;
bool supabase = true;
List<int> employeePermissions = [];

/// أسماء صلاحيات الموظف بالإنجليزي (name_en) — تُستخدم للفحص بالاسم بدل الـ ID.
List<String> employeePermissionNames = [];
String userName = '';

/// اسم صلاحية رؤية/تعديل سعر التكلفة (يطابق name_en في الباك إند).
const String costPricePermissionName = 'Cost Price';

/// هل يحق للمستخدم الحالي رؤية/تعديل سعر التكلفة؟
/// الأدمن دائماً، والموظف فقط إذا منحه الأدمن صلاحية "Cost Price".
bool get canViewCostPrice =>
    userType == 'admin' ||
    employeePermissionNames.contains(costPricePermissionName);

/// رقم صلاحية الوصول لمهام الموظفين (Employee Tasks).
const int employeeTasksPermissionId = 7;

/// هل يقدر المستخدم الحالي الوصول لشاشة إدارة مهام الموظفين (عرض/إنشاء)؟
/// الأدمن دائماً، والموظف فقط إذا منحه الأدمن صلاحية "Employee Tasks".
bool get canManageEmployeeTasks =>
    userType == 'admin' ||
    employeePermissions.contains(employeeTasksPermissionId);

/// اسم صلاحية تعديل مهمة موظف (يطابق name_en في الباك إند).
const String editEmployeeTaskPermissionName = 'Edit Employee Task';

/// هل يحق للمستخدم الحالي تعديل مهمة موظف؟
/// الأدمن دائماً، والموظف فقط إذا منحه الأدمن صلاحية "Edit Employee Task".
bool get canEditEmployeeTasks =>
    userType == 'admin' ||
    employeePermissionNames.contains(editEmployeeTaskPermissionName);

/// اسم صلاحية نسخ مهمة موظف (يطابق name_en في الباك إند).
const String cloneEmployeeTaskPermissionName = 'Clone Employee Task';

/// هل يحق للمستخدم الحالي نسخ مهمة موظف؟
/// الأدمن دائماً، والموظف فقط إذا منحه الأدمن صلاحية "Clone Employee Task".
bool get canCloneEmployeeTasks =>
    userType == 'admin' ||
    employeePermissionNames.contains(cloneEmployeeTaskPermissionName);

/// اسم صلاحية إعدادات المخزون (يطابق name_en في الباك إند).
const String stockInventorySettingsPermissionName = 'Stock Inventory Settings';

/// اسم صلاحية إدارة محادثات الدعم الفني.
const String technicalSupportPermissionName = 'Technical Support';

/// رقم صلاحية إعدادات المخزون في قائمة إنشاء/تعديل الموظف.
const int stockInventorySettingsPermissionId = 47;

/// رقم صلاحية إدارة محادثات الدعم الفني.
const int technicalSupportPermissionId = 49;

/// رقم صلاحية المخزون.
const int stockPermissionId = 16;

/// هل يحق للمستخدم الحالي فتح إعدادات المخزون؟
/// الأدمن دائماً، والموظف إذا معه صلاحية إعدادات المخزون أو صلاحية المخزون.
bool get canManageStockInventorySettings =>
    userType == 'admin' ||
    employeePermissions.contains(stockInventorySettingsPermissionId) ||
    employeePermissions.contains(stockPermissionId) ||
    employeePermissionNames.contains(stockInventorySettingsPermissionName);

bool get canManageTechnicalSupport =>
    userType == 'admin' ||
    employeePermissions.contains(technicalSupportPermissionId) ||
    employeePermissionNames.contains(technicalSupportPermissionName);

void syncSessionIdentity({
  String? type,
  String? name,
  List<int>? permissionIds,
  List<String>? permissionNamesEn,
}) {
  if (type != null) {
    userType = type;
    sessionUserType.value = type;
  }
  if (name != null) {
    userName = name;
  }
  if (permissionIds != null) {
    employeePermissions
      ..clear()
      ..addAll(permissionIds);
  }
  if (permissionNamesEn != null) {
    employeePermissionNames
      ..clear()
      ..addAll(permissionNamesEn);
  }
}

class InitialBindings implements Bindings {
  @override
  void dependencies() {
    AppDependencyRegistry.registerAll();
    _runAsyncSetup();
  }

  /// تهيئة سريعة فقط — لا تمنع الـ Splash (شارات وFCM تُؤجَّل).
  static Future<void> _runAsyncSetup() async {
    try {
      if (kIsWeb) {
        startApp.value = true;
      } else {
        await AppBootstrap.initializeMobile();
        await AppShortcutService.instance.initialize();
        await AppHomeWidgetService.instance.initialize();
        try {
          final doc = await FirebaseFirestore.instance
              .collection('Test')
              .doc('Test')
              .get()
              .timeout(const Duration(seconds: 5));
          final bool? value = doc.data()?['Test'] as bool?;
          startApp.value = value ?? true;
        } catch (e) {
          debugPrint('[Startup] Firestore Test doc failed: $e');
          startApp.value = true;
        }
      }

      await initializeDateFormatting();

      try {
        await Supabase.initialize(
          url: 'https://tigmezfjgepmzuefrogq.supabase.co',
          anonKey:
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRpZ21lemZqZ2VwbXp1ZWZyb2dxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk1MzMxNzMsImV4cCI6MjA3NTEwOTE3M30.xaocus3WHvIjcgJdocAdJYippiBFGwzr4zFymlsIDbE',
        );
      } catch (e) {
        debugPrint('[Startup] Supabase.initialize: $e');
      }

      try {
        final response = await Supabase.instance.client
            .from('doctor_bike')
            .select('status')
            .limit(1)
            .maybeSingle()
            .timeout(const Duration(seconds: 6));
        supabase = response?['status'] == true;
      } catch (e) {
        debugPrint('[Startup] Supabase status check failed: $e');
        supabase = true;
      }
    } catch (e, st) {
      debugPrint('[Startup] critical setup error: $e\n$st');
    } finally {
      AppStartup.markRemoteConfigReady();
      debugPrint('[Startup] remote config ready — splash may continue');
    }

    _runDeferredSetup();
  }

  static Future<void> _runDeferredSetup() async {
    try {
      await SessionService.hydrateToken();

      final userdata = await UserData.getSavedUser();
      if (userdata == null) {
        return;
      }

      employeePermissions
        ..clear()
        ..addAll(userdata.employeePermissions.map((p) => p.permissionId));
      syncSessionIdentity(
        type: userdata.user.type,
        name: userdata.user.name,
        permissionIds:
            userdata.employeePermissions.map((p) => p.permissionId).toList(),
        permissionNamesEn: userdata.employeePermissions
            .map((p) => p.permissionNameEn)
            .toList(),
      );

      if (userdata.user.type == 'admin') {
        if (!Get.isRegistered<AdminNotificationBadgeController>()) {
          Get.put(AdminNotificationBadgeController(), permanent: true);
        }
        Get.find<AdminNotificationBadgeController>().refresh();
      } else if (userdata.user.type == 'employee') {
        if (!Get.isRegistered<EmployeeNotificationBadgeController>()) {
          Get.put(EmployeeNotificationBadgeController(), permanent: true);
        }
        await Get.find<EmployeeNotificationBadgeController>().refresh();
      }
      await NotificationFirebaseService.instance
          .syncFcmTokenToServer(source: 'app_resume');
      AppVersionTrackingService.instance.start();
      await AppVersionTrackingService.instance.sync(source: 'app_resume');

      if (userdata.user.type == 'employee') {
        unawaited(
          EmployeeAttendancePersistentNotificationService.instance
              .initializeForEmployee(),
        );
      }
    } catch (e, st) {
      debugPrint('[Startup] deferred setup error: $e\n$st');
    }
  }
}
