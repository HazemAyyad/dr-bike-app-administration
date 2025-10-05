import 'package:doctorbike/core/services/initial_bindings.dart';
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
    bool isRemembered = await UserData.getIsRememberUser();

    Future.delayed(
      const Duration(seconds: 3),
      () async {
        if (supabase) {
          connected
              ? !isFirstTime
                  ? isRemembered
                      ? Get.offAllNamed(AppRoutes.BOTTOMNAVBARSCREEN)
                      : Get.offAllNamed(AppRoutes.LOGINORSIGNUPSCREEN)
                  : Get.offAllNamed(AppRoutes.ONBOARDINGSCREEN)
              : Get.offAllNamed(AppRoutes.NOINTERNETSCREEN);
        }
      },
    );
    super.onInit();
  }
}
