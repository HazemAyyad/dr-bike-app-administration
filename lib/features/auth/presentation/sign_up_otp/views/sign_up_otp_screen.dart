import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/loding_indicator.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/sign_up_otp_controller.dart';

class SignUpOtpScreen extends GetView<SignUpOtpController> {
  const SignUpOtpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // SizedBox(height: 40.h),
            Text(
              'otpVerification'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: ThemeService.isDark.value
                        ? Colors.white
                        : AppColors.secondaryColor,
                    fontSize: 25.sp,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 25.h),
            Text(
              'enterOtp'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: ThemeService.isDark.value
                        ? Colors.white
                        : AppColors.secondaryColor,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w400,
                  ),
            ),
            SizedBox(height: 75.h),
            // Directionality(
            //   textDirection: TextDirection.ltr,
            // child:
            PinCodeTextField(
              appContext: context,
              length: 4,
              keyboardType: TextInputType.number,
              animationType: AnimationType.scale,
              cursorColor: AppColors.primaryColor, // لون السهم
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(20.r),
                fieldHeight: 75.h,
                fieldWidth: 75.w,
                inactiveColor: ThemeService.isDark.value
                    ? AppColors.whiteColor.withAlpha(102)
                    : AppColors.customGreyColor.withAlpha(102),
                activeColor: ThemeService.isDark.value
                    ? AppColors.whiteColor.withAlpha(102)
                    : AppColors.customGreyColor.withAlpha(102),
                selectedColor: AppColors.primaryColor,
              ),
              animationDuration: const Duration(milliseconds: 300),
              enableActiveFill: false,
              onChanged: (value) {
                controller.otpCode.value = value;
              },
            ),
            // ),
            SizedBox(height: 50.h),

            Obx(
              () => controller.isLoading.value
                  ? lodingIndicator()
                  : AppButton(
                      text: 'verify',
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
            SizedBox(height: 50.h),

            Text(
              'noCode'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                  ),
            ),
            SizedBox(height: 10.h),

            Obx(
              () => controller.secondsRemaining.value > 0
                  ? Text(
                      '${'resendCodeIn'.tr} 00:${controller.secondsRemaining.value.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: ThemeService.isDark.value
                                ? Colors.white
                                : AppColors.customGreyColor,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                    )
                  : TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        controller.resendCode();
                      },
                      child: Text(
                        'resendCode'.tr,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: AppColors.primaryColor,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
