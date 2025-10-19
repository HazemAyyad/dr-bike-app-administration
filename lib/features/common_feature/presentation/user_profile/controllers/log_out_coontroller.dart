import 'package:doctorbike/core/services/user_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
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
