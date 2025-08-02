import 'package:doctorbike/core/helpers/loding_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_phone_field.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/validator/validator.dart';
import '../controllers/personal_details_controller.dart';
import 'address_field.dart';
import 'drop_down_button.dart';

Widget buildPersonalDetails(
    PersonalDetailsController controller, BuildContext context) {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 20.h),
        Text(
          'personalDetails'.tr,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
              ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 30.h),
        // الاسم
        CustomTextField(
          label: 'name',
          hintText: controller.nameController.text,
          controller: controller.nameController,
          labelTextstyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: ThemeService.isDark.value
                    ? Colors.white
                    : AppColors.secondaryColor,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 30.h),
        // البريد الإلكتروني
        CustomTextField(
          label: 'email',
          enabled: false,
          hintText: controller.emailController.text,
          controller: controller.emailController,
          labelTextstyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: ThemeService.isDark.value
                    ? Colors.white
                    : AppColors.secondaryColor,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
              ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) =>
              Validators.validateEmail(value, Get.locale!.languageCode),
        ),
        SizedBox(height: 30.h),
        // رقم الجوال
        Row(
          children: [
            Text(
              'phoneNumber'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: ThemeService.isDark.value
                        ? Colors.white
                        : AppColors.secondaryColor,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        CustomPhoneField(
          controller: controller.phoneController,
        ),
        SizedBox(height: 20.h),
        // رقم الجوال البديل
        Row(
          children: [
            Text(
              'alternatePhone'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: ThemeService.isDark.value
                        ? Colors.white
                        : AppColors.secondaryColor,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        CustomPhoneField(
          controller: controller.alternativePhoneController,
        ),
        SizedBox(height: 20.h),
        // المدينة
        dropdownButton(controller),
        SizedBox(height: 20.h),
        // العنوان
        addressField(controller),
        SizedBox(height: 30.h),
        // // زر حفظ
        Obx(
          () => controller.isLoading.value
              ? lodingIndicator()
              : AppButton(
                  text: 'save',
                  textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                  onPressed: () {
                    controller.updateUserProfile(context);
                  },
                  height: 48.h,
                ),
        ),
      ],
    ),
  );
}
