import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/auth_logo.dart';
import '../../../../../core/services/theme_service.dart';
import '../controllers/login_controller.dart';
import '../widgets/login_text_field.dart';
import '../widgets/remember_me.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: controller.formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 64.h),
                const AppLogo(),
                SizedBox(height: 56.h),
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
                SizedBox(height: 50.h),
                LogInTextField(controller: controller),
                SizedBox(height: 15.h),
                RememberMe(controller: controller),
                SizedBox(height: 15.h),
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
                  height: 48.h,
                ),
                SizedBox(height: 15.h),
                // const DontHaveAccount(),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
