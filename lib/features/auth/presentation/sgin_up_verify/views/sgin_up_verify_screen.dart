import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/loding_indicator.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/sginup_verify_controller.dart';
import '../widgets/email_field_change_button.dart';
import '../widgets/terms_and_conditions.dart';

class SginupVerifyScreen extends GetView<SginupVerifyController> {
  const SginupVerifyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              SizedBox(height: 200.h),
              // Title
              Text(
                "startNow".tr,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: ThemeService.isDark.value
                          ? Colors.white
                          : AppColors.secondaryColor,
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(height: 30.h),
              // Subtitle
              Text(
                "otpSent".tr,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: ThemeService.isDark.value
                          ? AppColors.graywhiteColor
                          : AppColors.customGreyColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w400,
                    ),
              ),
              SizedBox(height: 40.h),

              // Email Field with change button
              EmailFieldWithChangeButton(controller: controller),
              SizedBox(height: 30.h),

              // Terms and conditions
              TermsAndConditions(),
              SizedBox(height: 20.h),

              // Next Button
              Obx(
                () => controller.isLoading.value
                    ? lodingIndicator()
                    : AppButton(
                        text: 'next',
                        onPressed: () {
                          controller.sendOtp(context);
                        },
                        textStyle:
                            Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  color: ThemeService.isDark.value
                                      ? AppColors.secondaryColor
                                      : AppColors.whiteColor,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                        height: 48.h,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
