import 'package:doctorbike/core/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/auth_logo.dart';
import '../../../../../core/helpers/loding_indicator.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/sign_up_controller.dart';
import '../widgets/already_have_account.dart';
import '../widgets/sign_up_text_field.dart';

class SignUpScreen extends GetView<SignUpController> {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: SingleChildScrollView(
            child: Form(
              key: controller.formKey,
              child: Column(
                children: [
                  SizedBox(height: 50.h),
                  // Logo
                  AppLogo(),
                  SizedBox(height: 25.h),
                  // Title
                  Text(
                    "welcome".tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: ThemeService.isDark.value
                              ? Colors.white
                              : AppColors.secondaryColor,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  SizedBox(height: 25.h),
                  SignUpTextField(controller: controller),
                  SizedBox(height: 24.h),
                  // Register Button
                  Obx(
                    () => controller.isLoading.value
                        ? lodingIndicator()
                        : AppButton(
                            text: 'register',
                            onPressed: () {
                              controller.register(context);
                            },
                            textStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: ThemeService.isDark.value
                                      ? AppColors.secondaryColor
                                      : AppColors.whiteColor,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                            height: 48.h,
                          ),
                  ),
                  SizedBox(height: 16.h),
                  // Bottom Text
                  AlreadyHaveAccount(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
