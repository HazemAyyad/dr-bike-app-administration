import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/auth_logo.dart';
import '../../../../../core/helpers/desktop_auth_layout.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/desktop_layout.dart';
import '../controllers/login_controller.dart';
import '../widgets/login_text_field.dart';
import '../widgets/remember_me.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final desktop = DesktopLayout.isDesktopPlatform;
    final form = Form(
      key: controller.formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!desktop) SizedBox(height: 64.h),
          if (desktop)
            const SizedBox(width: 136, height: 96, child: AppLogo())
          else
            const AppLogo(),
          SizedBox(height: desktop ? 20 : 56.h),
          Text(
            'welcomeBack'.tr,
            style: TextTheme.of(context).bodyMedium!.copyWith(
                  color: ThemeService.isDark.value
                      ? Colors.white
                      : AppColors.secondaryColor,
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: desktop ? 24 : 50.h),
          LogInTextField(controller: controller),
          SizedBox(height: desktop ? 12 : 15.h),
          RememberMe(controller: controller),
          SizedBox(height: desktop ? 12 : 15.h),
          AppButton(
            isLoading: controller.isLoading,
            isSafeArea: false,
            text: 'login',
            onPressed: () {
              controller.sendOtp(context);
            },
            textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: ThemeService.isDark.value
                      ? AppColors.secondaryColor
                      : AppColors.whiteColor,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                ),
            height: desktop ? null : 48.h,
            padding: desktop
                ? const EdgeInsets.symmetric(vertical: 13, horizontal: 12)
                : null,
          ),
          Obx(
            () {
              if (!controller.canShowBiometricLogin.value) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: EdgeInsets.only(top: 16.h),
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: controller.isBiometricLoading.value
                          ? null
                          : () => controller.biometricLogin(context),
                      child: Container(
                        width: 58.w,
                        height: 58.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ThemeService.isDark.value
                              ? AppColors.customGreyColor
                              : AppColors.secondaryColor
                                  .withValues(alpha: 0.08),
                          border: Border.all(
                            color: AppColors.secondaryColor
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        child: controller.isBiometricLoading.value
                            ? Padding(
                                padding: EdgeInsets.all(16.w),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.fingerprint,
                                color: ThemeService.isDark.value
                                    ? Colors.white
                                    : AppColors.secondaryColor,
                                size: 32.sp,
                              ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'الدخول بالبصمة',
                      style: TextStyle(
                        color: ThemeService.isDark.value
                            ? Colors.white
                            : AppColors.secondaryColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (!desktop) SizedBox(height: 45.h),
        ],
      ),
    );
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: desktop
          ? DesktopAuthLayout(child: form)
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: form,
              ),
            ),
    );
  }
}
