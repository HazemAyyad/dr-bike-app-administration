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
const int employeesSectionPermissionId = 5;
const int employeesViewPermissionId = 50;
const int employeesCreatePermissionId = 51;
const int employeesEditBasicPermissionId = 52;
const int employeesDeletePermissionId = 53;
const int employeesPermissionsViewPermissionId = 54;
const int employeesPermissionsManagePermissionId = 55;
const int employeesFinancialViewPermissionId = 56;
const int employeesSalaryPayPermissionId = 57;
const int employeesPointsViewPermissionId = 58;
const int employeesPointsManagePermissionId = 59;
const int employeesAttendanceViewPermissionId = 60;
const int employeesAttendanceManagePermissionId = 61;
const int employeesLogsViewPermissionId = 62;
const int employeesOrdersManagePermissionId = 63;
const int employeesFingerprintManagePermissionId = 64;
const int employeesRewardsRulesManagePermissionId = 65;
const String employeesSectionPermissionName = 'Employees Section';
const String employeesViewPermissionName = 'Employees View';
const String employeesCreatePermissionName = 'Employees Create';
const String employeesEditBasicPermissionName = 'Employees Edit Basic';
const String employeesDeletePermissionName = 'Employees Delete';
const String employeesPermissionsViewPermissionName =
    'Employees Permissions View';
const String employeesPermissionsManagePermissionName =
    'Employees Permissions Manage';
const String employeesFinancialViewPermissionName = 'Employees Financial View';
const String employeesSalaryPayPermissionName = 'Employees Salary Pay';
const String employeesPointsViewPermissionName = 'Employees Points View';
const String employeesPointsManagePermissionName = 'Employees Points Manage';
const String employeesAttendanceViewPermissionName =
    'Employees Attendance View';
const String employeesAttendanceManagePermissionName =
    'Employees Attendance Manage';
const String employeesLogsViewPermissionName = 'Employees Logs View';
const String employeesOrdersManagePermissionName = 'Employees Orders Manage';
const String employeesFingerprintManagePermissionName =
    'Employees Fingerprint Manage';
const String employeesRewardsRulesManagePermissionName =
    'Employees Rewards Rules Manage';

const List<String> employeeSectionDetailedPermissionNames = [
  employeesViewPermissionName,
  employeesCreatePermissionName,
  employeesEditBasicPermissionName,
  employeesDeletePermissionName,
  employeesPermissionsViewPermissionName,
  employeesPermissionsManagePermissionName,
  employeesFinancialViewPermissionName,
  employeesSalaryPayPermissionName,
  employeesPointsViewPermissionName,
  employeesPointsManagePermissionName,
  employeesAttendanceViewPermissionName,
  employeesAttendanceManagePermissionName,
  employeesLogsViewPermissionName,
  employeesOrdersManagePermissionName,
  employeesFingerprintManagePermissionName,
  employeesRewardsRulesManagePermissionName,
];

const List<int> employeeSectionDetailedPermissionIds = [
  employeesViewPermissionId,
  employeesCreatePermissionId,
  employeesEditBasicPermissionId,
  employeesDeletePermissionId,
  employeesPermissionsViewPermissionId,
  employeesPermissionsManagePermissionId,
  employeesFinancialViewPermissionId,
  employeesSalaryPayPermissionId,
  employeesPointsViewPermissionId,
  employeesPointsManagePermissionId,
  employeesAttendanceViewPermissionId,
  employeesAttendanceManagePermissionId,
  employeesLogsViewPermissionId,
  employeesOrdersManagePermissionId,
  employeesFingerprintManagePermissionId,
  employeesRewardsRulesManagePermissionId,
];

bool hasEmployeePermissionName(String name) =>
    userType == 'admin' || employeePermissionNames.contains(name);

bool get hasAnyEmployeeSectionDetailedPermission =>
    employeePermissionNames
        .any(employeeSectionDetailedPermissionNames.contains) ||
    employeePermissions.any(employeeSectionDetailedPermissionIds.contains);

bool get canAccessEmployeesSection =>
    userType == 'admin' ||
    employeePermissions.contains(employeesSectionPermissionId) ||
    employeePermissionNames.contains(employeesSectionPermissionName) ||
    hasAnyEmployeeSectionDetailedPermission ||
    canManageEmployeeTasks;

bool get canViewEmployees =>
    userType == 'admin' ||
    employeePermissionNames.contains(employeesViewPermissionName) ||
    employeePermissionNames.contains(employeesEditBasicPermissionName) ||
    employeePermissionNames.contains(employeesDeletePermissionName) ||
    employeePermissions.contains(employeesViewPermissionId) ||
    employeePermissions.contains(employeesEditBasicPermissionId) ||
    employeePermissions.contains(employeesDeletePermissionId) ||
    employeePermissions.contains(employeesSectionPermissionId);

bool get canCreateEmployees =>
    userType == 'admin' ||
    employeePermissionNames.contains(employeesCreatePermissionName) ||
    employeePermissions.contains(employeesCreatePermissionId);

bool get canEditEmployeesBasic =>
    userType == 'admin' ||
    employeePermissionNames.contains(employeesEditBasicPermissionName) ||
    employeePermissions.contains(employeesEditBasicPermissionId);

bool get canDeleteEmployees =>
    userType == 'admin' ||
    employeePermissionNames.contains(employeesDeletePermissionName) ||
    employeePermissions.contains(employeesDeletePermissionId);

bool get canViewEmployeesPermissions =>
    userType == 'admin' ||
    employeePermissionNames.contains(employeesPermissionsViewPermissionName) ||
    employeePermissionNames
        .contains(employeesPermissionsManagePermissionName) ||
    employeePermissions.contains(employeesPermissionsViewPermissionId) ||
    employeePermissions.contains(employeesPermissionsManagePermissionId);

bool get canManageEmployeesPermissions =>
    userType == 'admin' ||
    employeePermissionNames
        .contains(employeesPermissionsManagePermissionName) ||
    employeePermissions.contains(employeesPermissionsManagePermissionId);

bool get canViewEmployeesFinancial =>
    userType == 'admin' ||
    employeePermissionNames.contains(employeesFinancialViewPermissionName) ||
    employeePermissions.contains(employeesFinancialViewPermissionId);

bool get canPayEmployeesSalary =>
    userType == 'admin' ||
    employeePermissionNames.contains(employeesSalaryPayPermissionName) ||
    employeePermissions.contains(employeesSalaryPayPermissionId);

bool get canViewEmployeesPoints =>
    userType == 'admin' ||
    employeePermissionNames.contains(employeesPointsViewPermissionName) ||
    employeePermissionNames.contains(employeesPointsManagePermissionName) ||
    employeePermissions.contains(employeesPointsViewPermissionId) ||
    employeePermissions.contains(employeesPointsManagePermissionId);

bool get canManageEmployeesPoints =>
    userType == 'admin' ||
    employeePermissionNames.contains(employeesPointsManagePermissionName) ||
    employeePermissions.contains(employeesPointsManagePermissionId);

bool get canViewEmployeesAttendance =>
    userType == 'admin' ||
    employeePermissionNames.contains(employeesAttendanceViewPermissionName) ||
    employeePermissionNames.contains(employeesAttendanceManagePermissionName) ||
    employeePermissions.contains(employeesAttendanceViewPermissionId) ||
    employeePermissions.contains(employeesAttendanceManagePermissionId);

bool get canManageEmployeesAttendance =>
    userType == 'admin' ||
    employeePermissionNames.contains(employeesAttendanceManagePermissionName) ||
    employeePermissions.contains(employeesAttendanceManagePermissionId);

bool get canViewEmployeesLogs =>
    userType == 'admin' ||
    employeePermissionNames.contains(employeesLogsViewPermissionName) ||
    employeePermissions.contains(employeesLogsViewPermissionId);

bool get canManageEmployeesOrders =>
    userType == 'admin' ||
    employeePermissionNames.contains(employeesOrdersManagePermissionName) ||
    employeePermissions.contains(employeesOrdersManagePermissionId);

bool get canManageEmployeesFingerprint =>
    userType == 'admin' ||
    employeePermissionNames
        .contains(employeesFingerprintManagePermissionName) ||
    employeePermissions.contains(employeesFingerprintManagePermissionId);

bool get canManageEmployeesRewardsRules =>
    userType == 'admin' ||
    employeePermissionNames
        .contains(employeesRewardsRulesManagePermissionName) ||
    employeePermissions.contains(employeesRewardsRulesManagePermissionId);

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
        EmployeeAttendancePersistentNotificationService.instance
            .initializeForEmployee()
            .catchError((Object e, StackTrace st) {
          debugPrint('[Startup] attendance notification error: $e\n$st');
        });
      }
    } catch (e, st) {
      debugPrint('[Startup] deferred setup error: $e\n$st');
    }
  }
}
