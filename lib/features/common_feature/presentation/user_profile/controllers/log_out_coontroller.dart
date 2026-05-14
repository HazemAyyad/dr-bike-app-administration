import 'package:doctorbike/core/services/user_data.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/services/admin_notification_api_service.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/notification_firebase_service.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class LogOutController extends GetxController {
  Logout logout;
  LogOutController({required this.logout});

  RxBool isLoading = false.obs;
  // دالة لتسجيل الخروج
  void logOut(BuildContext context) async {
    isLoading(true);

    String userToken = await UserData.getUserToken();

    if (!kIsWeb && userType == 'admin') {
      final String t = NotificationFirebaseService.instance.finalToken;
      if (t.isNotEmpty) {
        try {
          await AdminNotificationApiService().deleteDeviceToken(t);
        } catch (_) {}
      }
    }

    final result = await logout.call(
      token: userToken,
    );
    result.fold(
      (failure) {
        Helpers.showCustomDialogError(
          context: context,
          title: failure.errMessage,
          message: 'logoutError'.tr,
        );
      },
      (success) async {
        Get.offAllNamed(AppRoutes.LOGINORSIGNUPSCREEN);
        await DefaultCacheManager().emptyCache();

        UserData.clearAllUserData();

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
      },
    );
    isLoading(false);
  }
}
