import 'package:doctorbike/core/services/app_startup.dart';
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
        Get.offAllNamed(AppRoutes.LOGINORSIGNUPSCREEN);
        return;
      }

      if (!connected) {
        Get.offAllNamed(AppRoutes.NOINTERNETSCREEN);
        return;
      }

      if (isFirstTime) {
        Get.offAllNamed(AppRoutes.ONBOARDINGSCREEN);
        return;
      }

      final token = await UserData.getUserToken();
      if (token.isEmpty) {
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
        Get.offAllNamed(AppRoutes.BOTTOMNAVBARSCREEN);
        return;
      }

      if (validation.isAuthFailure) {
        await SessionService.clearSessionAndGoToLogin(showMessage: false);
        return;
      }

      final cachedUser = await UserData.getSavedUser();
      if (cachedUser != null) {
        await SessionService.restoreGlobalsFromStorage();
        Get.offAllNamed(AppRoutes.BOTTOMNAVBARSCREEN);
      } else {
        Get.offAllNamed(AppRoutes.LOGINORSIGNUPSCREEN);
      }
    } catch (e, st) {
      debugPrint('[Splash] navigation failed: $e\n$st');
      Get.offAllNamed(AppRoutes.LOGINORSIGNUPSCREEN);
    }
  }
}
