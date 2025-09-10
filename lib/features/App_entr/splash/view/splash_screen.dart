import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/utils/assets_manger.dart';
import '../controller/splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    controller.onInit();

    return Scaffold(
      body: Center(
        child: Image.asset(
          ThemeService.isDark.value
              ? AssetsManager.darkLogo
              : AssetsManager.whiteLogo,
          height: double.infinity,
          width: double.infinity,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
