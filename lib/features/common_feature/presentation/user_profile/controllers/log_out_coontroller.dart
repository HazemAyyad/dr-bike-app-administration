import 'package:doctorbike/core/services/user_data.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/services/admin_notification_api_service.dart';
import '../../../../../core/services/biometric_auth_service.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/notification_firebase_service.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class LogOutController extends GetxController {
  Logout logout;
  LogOutController({required this.logout});

  RxBool isLoading = false.obs;
  /// When biometric login is enabled, logout is local-only so the saved token
  /// stays valid on the server and fingerprint login works again.
  Future<bool> _isBiometricLocalLogout() async {
    if (kIsWeb) return false;
    final enabled =
        await BiometricAuthService.instance.isBiometricLoginEnabled();
    if (!enabled) return false;
    return BiometricAuthService.instance.hasSavedLoginData();
  }

  Future<void> _finishLogout(
    BuildContext context, {
    required bool biometricLocalLogout,
  }) async {
    final loginRoute = biometricLocalLogout
        ? AppRoutes.LOGINSCREEN
        : AppRoutes.LOGINORSIGNUPSCREEN;

    Get.offAllNamed(loginRoute);
    await DefaultCacheManager().emptyCache();
    await UserData.clearAllUserData();

    Helpers.showCustomDialogSuccess(
      // ignore: use_build_context_synchronously
      context: context,
      title: 'success'.tr,
      message: 'logoutSuccess'.tr,
    );
    Future.delayed(
      const Duration(milliseconds: 1500),
      () {
        Get.back();
      },
    );
  }

  // دالة لتسجيل الخروج
  void logOut(BuildContext context) async {
    isLoading(true);

    try {
      final userToken = await UserData.getUserToken();
      final biometricLocalLogout = await _isBiometricLocalLogout();

      if (!kIsWeb && userType == 'admin') {
        final String t = NotificationFirebaseService.instance.finalToken;
        if (t.isNotEmpty) {
          try {
            await AdminNotificationApiService().deleteDeviceToken(t);
          } catch (_) {}
        }
      }

      if (biometricLocalLogout) {
        await _finishLogout(
          context,
          biometricLocalLogout: true,
        );
        return;
      }

      final result = await logout.call(token: userToken);
      await result.fold<Future<void>>(
        (failure) async {
          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: 'logoutError'.tr,
          );
        },
        (success) async {
          await _finishLogout(
            context,
            biometricLocalLogout: false,
          );
        },
      );
    } finally {
      isLoading(false);
    }
  }
}
