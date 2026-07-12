import 'package:doctorbike/core/services/app_shortcut_service.dart';
import 'package:doctorbike/core/services/app_startup.dart';

import 'package:doctorbike/core/services/employee_attendance_persistent_notification_service.dart';
import 'package:doctorbike/core/services/initial_bindings.dart';
import 'package:doctorbike/core/services/session_service.dart';
import 'package:doctorbike/core/services/user_data.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';

import '../../../../core/connection/network_info.dart';
import '../../../../routes/app_routes.dart';

class SplashController extends GetxController {
  final NetworkInfo networkInfo = NetworkInfo();
  bool _navigationStarted = false;

  @override
  void onReady() {
    super.onReady();
    debugPrint('[Splash] onReady — starting navigation');
    _startNavigation();
  }

  Future<void> _startNavigation() async {
    if (_navigationStarted) {
      return;
    }
    _navigationStarted = true;

    try {
      await AppStartup.waitRemoteConfig(
        timeout: const Duration(seconds: 6),
      );

      await Future<void>.delayed(const Duration(milliseconds: 800));

      final connected = await networkInfo.isConnected
          .timeout(const Duration(seconds: 4), onTimeout: () => true);
      final isFirstTime = await UserData.getIsFirstTime();

      debugPrint(
        '[Splash] connected=$connected firstTime=$isFirstTime supabase=$supabase',
      );

      if (!supabase) {
        debugPrint('[Splash] navigate -> LOGINORSIGNUPSCREEN supabase=false');
        Get.offAllNamed(AppRoutes.LOGINORSIGNUPSCREEN);
        return;
      }

      if (!connected) {
        debugPrint('[Splash] navigate -> NOINTERNETSCREEN connected=false');
        Get.offAllNamed(AppRoutes.NOINTERNETSCREEN);
        return;
      }

      if (isFirstTime) {
        debugPrint('[Splash] navigate -> ONBOARDINGSCREEN firstTime=true');
        Get.offAllNamed(AppRoutes.ONBOARDINGSCREEN);
        return;
      }

      final token = await UserData.getUserToken();
      if (token.isEmpty) {
        debugPrint('[Splash] navigate -> LOGINORSIGNUPSCREEN empty token');
        Get.offAllNamed(AppRoutes.LOGINORSIGNUPSCREEN);
        return;
      }

      SessionValidationResult validation;
      try {
        validation = await SessionService.validateAndRefreshSession().timeout(
          const Duration(seconds: 12),
          onTimeout: () => const SessionValidationResult(
            isValid: false,
            isAuthFailure: false,
          ),
        );
      } catch (e) {
        debugPrint('[Splash] session validation error: $e');
        validation = const SessionValidationResult(
          isValid: false,
          isAuthFailure: false,
        );
      }

      if (validation.isValid) {
        debugPrint('[Splash] navigate -> BOTTOMNAVBARSCREEN valid session');
        Get.offAllNamed(AppRoutes.BOTTOMNAVBARSCREEN);
        AppShortcutService.instance.scheduleConsumePending();
        if (userType == 'employee') {
          EmployeeAttendancePersistentNotificationService.instance
              .initializeForEmployee();
        }
        return;
      }

      if (validation.isAuthFailure) {
        debugPrint('[Splash] auth failure -> clear session and login');
        await SessionService.clearSessionAndGoToLogin(showMessage: false);
        return;
      }

      final cachedUser = await UserData.getSavedUser();
      if (cachedUser != null) {
        await SessionService.restoreGlobalsFromStorage();
        debugPrint('[Splash] navigate -> BOTTOMNAVBARSCREEN cached user');
        Get.offAllNamed(AppRoutes.BOTTOMNAVBARSCREEN);
        AppShortcutService.instance.scheduleConsumePending();
        if (userType == 'employee') {
          EmployeeAttendancePersistentNotificationService.instance
              .initializeForEmployee();
        }
      } else {
        debugPrint('[Splash] navigate -> LOGINORSIGNUPSCREEN no cached user');
        Get.offAllNamed(AppRoutes.LOGINORSIGNUPSCREEN);
      }
    } catch (e, st) {
      debugPrint('[Splash] navigation failed: $e\n$st');
      debugPrint('[Splash] navigate -> LOGINORSIGNUPSCREEN catch');
      Get.offAllNamed(AppRoutes.LOGINORSIGNUPSCREEN);
    }
  }
}
