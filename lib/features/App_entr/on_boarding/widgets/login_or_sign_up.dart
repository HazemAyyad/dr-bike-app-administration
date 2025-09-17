import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/services/theme_service.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/assets_manger.dart';
import '../../../../routes/app_routes.dart';

class LoginOrSignUpScreen extends StatelessWidget {
  const LoginOrSignUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 50.h),
              Expanded(
                child: Image.asset(AssetsManager.onBoardingScreenFour),
              ),
              SizedBox(height: 30.h),
              SizedBox(
                width: 246.w,
                child: Text(
                  'welcomeToApp'.tr,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: ThemeService.isDark.value
                            ? Colors.white
                            : AppColors.secondaryColor,
                        fontSize: 27.sp,
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 50.h),
              AppButton(
                isSafeArea: false,
                height: 46.h,
                width: 382.w,
                color: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
                text: 'createAccount',
                onPressed: () {
                  Get.toNamed(AppRoutes.SIGNUPSCREEN);
                },
                textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: ThemeService.isDark.value
                          ? AppColors.secondaryColor
                          : AppColors.whiteColor,
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(height: 24.h),
              AppButton(
                isSafeArea: false,
                height: 46.h,
                width: 382.w,
                text: 'login',
                textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: ThemeService.isDark.value
                          ? AppColors.primaryColor
                          : AppColors.secondaryColor,
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w700,
                    ),
                onPressed: () {
                  Get.toNamed(AppRoutes.LOGINSCREEN);
                },
                color: ThemeService.isDark.value
                    ? AppColors.darkColor
                    : AppColors.whiteColor,
                borderColor: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
                borderWidth: 1.5,
              ),
              SizedBox(height: 50.h),
            ],
          ),
        ),
      ),
    );
  }
}
