import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/admin/notifications/presentation/controllers/admin_notification_badge_controller.dart';
import '../../features/employee/notifications/presentation/controllers/employee_notification_badge_controller.dart';
import 'app_bootstrap.dart';
import 'app_dependency_registry.dart';
import 'app_startup.dart';
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
String userName = '';

void syncSessionIdentity({
  String? type,
  String? name,
  List<int>? permissionIds,
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
    } catch (e, st) {
      debugPrint('[Startup] deferred setup error: $e\n$st');
    }
  }
}
