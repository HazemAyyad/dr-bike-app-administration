import 'package:doctorbike/core/helpers/loding_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/validator/validator.dart';
import '../controllers/change_password_controller.dart';

class ChangePasswordForm extends GetView<ChangePasswordController> {
  const ChangePasswordForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 10.h),
        Row(
          children: [
            Text(
              'pleaseEnterTheDetails'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: ThemeService.isDark.value
                        ? AppColors.whiteColor
                        : AppColors.primaryColor,
                  ),
            ),
          ],
        ),
        SizedBox(height: 25.h),
        Obx(
          () => CustomTextField(
            isRequired: true,
            label: 'oldPassword',
            labelTextstyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: ThemeService.isDark.value
                      ? AppColors.whiteColor
                      : AppColors.secondaryColor,
                ),
            hintText: '*********',
            controller: controller.oldPasswordController,
            suffixIcon: IconButton(
              onPressed: () => controller.toggleOldPasswordVisibility(),
              icon: Icon(
                controller.oldPasswordVisibility.value
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: ThemeService.isDark.value
                    ? AppColors.graywhiteColor
                    : AppColors.customGreyColor2,
              ),
            ),
            obscureText: controller.oldPasswordVisibility.value,
          ),
        ),
        SizedBox(height: 25.h),
        // كلمة المرور الجديدة
        Obx(
          () => CustomTextField(
            isRequired: true,
            label: 'newPassword',
            labelTextstyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: ThemeService.isDark.value
                      ? AppColors.whiteColor
                      : AppColors.secondaryColor,
                ),
            hintText: '*********',
            controller: controller.newPasswordController,
            suffixIcon: IconButton(
              onPressed: () => controller.toggleNewPasswordVisibility(),
              icon: Icon(
                controller.newPasswordVisibility.value
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: ThemeService.isDark.value
                    ? AppColors.graywhiteColor
                    : AppColors.customGreyColor2,
              ),
            ),
            obscureText: controller.newPasswordVisibility.value,
            validator: (p0) =>
                Validators.validatePassword(p0, Get.locale!.languageCode),
          ),
        ),
        SizedBox(height: 25.h),
        Obx(
          () => CustomTextField(
            isRequired: true,
            label: 'confirmNewPassword',
            labelTextstyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: ThemeService.isDark.value
                      ? AppColors.whiteColor
                      : AppColors.secondaryColor,
                ),
            hintText: '*********',
            controller: controller.confirmPasswordController,
            suffixIcon: IconButton(
              onPressed: () => controller.toggleConfirmNewPasswordVisibility(),
              icon: Icon(
                controller.confirmNewPasswordVisibility.value
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: ThemeService.isDark.value
                    ? AppColors.graywhiteColor
                    : AppColors.customGreyColor2,
              ),
            ),
            obscureText: controller.confirmNewPasswordVisibility.value,
            validator: (p0) =>
                Validators.validatePassword(p0, Get.locale!.languageCode),
          ),
        ),
        SizedBox(height: 20.h),

        // نص المساعدة
        Row(
          children: [
            Flexible(
              child: Text(
                'passwordValidation'.tr,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      color: ThemeService.isDark.value
                          ? AppColors.whiteColor
                          : AppColors.customGreyColor,
                    ),
              ),
            ),
          ],
        ),
        SizedBox(height: 40.h),
        // زر حفظ التغييرات
        Obx(
          () => controller.isLoading.value
              ? lodingIndicator()
              : AppButton(
                  text: 'saveChanges',
                  height: 48.h,
                  textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.whiteColor),
                  onPressed: () {
                    controller.savePasswordChanges(context);
                  },
                ),
        ),
      ],
    );
  }
}
