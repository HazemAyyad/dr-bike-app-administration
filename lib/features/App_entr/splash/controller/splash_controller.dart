import 'package:doctorbike/core/services/initial_bindings.dart';
import 'package:doctorbike/core/services/session_service.dart';
import 'package:doctorbike/core/services/user_data.dart';
import 'package:get/get.dart';

import '../../../../core/connection/network_info.dart';
import '../../../../routes/app_routes.dart';

class SplashController extends GetxController {
  NetworkInfo networkInfo = NetworkInfo();
  @override
  void onInit() async {
    final connected = await networkInfo.isConnected;
    bool isFirstTime = await UserData.getIsFirstTime();

    Future.delayed(
      const Duration(seconds: 3),
      () async {
        if (!supabase) return;

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

        final validation = await SessionService.validateAndRefreshSession();
        if (validation.isValid) {
          Get.offAllNamed(AppRoutes.BOTTOMNAVBARSCREEN);
          return;
        }

        if (validation.isAuthFailure) {
          await SessionService.clearSessionAndGoToLogin(showMessage: false);
          return;
        }

        // توكن محفوظ لكن التحقق فشل (شبكة مثلاً) — ادخل بالبيانات المخزنة
        final cachedUser = await UserData.getSavedUser();
        if (cachedUser != null) {
          await SessionService.restoreGlobalsFromStorage();
          Get.offAllNamed(AppRoutes.BOTTOMNAVBARSCREEN);
        } else {
          Get.offAllNamed(AppRoutes.LOGINORSIGNUPSCREEN);
        }
      },
    );
    super.onInit();
  }
}
