import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/helpers/app_button.dart';
import '../../../../core/services/initial_bindings.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../routes/app_routes.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final titleColor = isDark ? Colors.white : AppColors.primaryColor;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 64.sp,
                color: titleColor.withValues(alpha: 0.85),
              ),
              SizedBox(height: 20.h),
              Text(
                'noInternet'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'checkConnectionAndRetry'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: titleColor.withValues(alpha: 0.7),
                  fontSize: 14.sp,
                  height: 1.35,
                ),
              ),
              SizedBox(height: 40.h),
              AppButton(
                color: isDark ? Colors.white : AppColors.primaryColor,
                textColor: isDark ? AppColors.primaryColor : Colors.white,
                onPressed: () {
                  InitialBindings().dependencies();
                  Get.offAllNamed(AppRoutes.SPLASHSCREEN);
                },
                text: 'tryAgain',
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
