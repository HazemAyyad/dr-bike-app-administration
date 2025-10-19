import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_phone_field.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/validator/validator.dart';
import '../controllers/personal_details_controller.dart';
import 'address_field.dart';
import 'drop_down_button.dart';

class BuildPersonalDetails extends GetView<PersonalDetailsController> {
  const BuildPersonalDetails({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 10.h),
          // الاسم
          CustomTextField(
            label: 'name',
            hintText: controller.nameController.text,
            controller: controller.nameController,
            // labelTextstyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
            //       color: ThemeService.isDark.value
            //           ? Colors.white
            //           : AppColors.secondaryColor,
            //       fontSize: 15.sp,
            //       fontWeight: FontWeight.w700,
            //     ),
          ),
          SizedBox(height: 20.h),
          // البريد الإلكتروني
          CustomTextField(
            label: 'email',
            enabled: false,
            hintText: controller.emailController.text,
            controller: controller.emailController,
            // labelTextstyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
            //       color: ThemeService.isDark.value
            //           ? Colors.white
            //           : AppColors.secondaryColor,
            //       fontSize: 15.sp,
            //       fontWeight: FontWeight.w700,
            //     ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) =>
                Validators.validateEmail(value, Get.locale!.languageCode),
          ),
          SizedBox(height: 20.h),
          // رقم الجوال
          GetBuilder<PersonalDetailsController>(
            builder: (controller) {
              return Column(
                children: [
                  CustomPhoneField(
                    label: 'phoneNumber',
                    controller: controller.phoneController,
                    hintText: controller.phoneController.text,
                  ),
                  SizedBox(height: 20.h),
                  // رقم الجوال البديل
                  CustomPhoneField(
                    label: 'alternatePhone',
                    controller: controller.subPhoneController,
                    hintText: controller.subPhoneController.text,
                  ),
                ],
              );
            },
          ),

          SizedBox(height: 10.h),
          // المدينة
          dropdownButton(controller),
          SizedBox(height: 10.h),
          // العنوان
          addressField(controller),
          SizedBox(height: 10.h),
          // زر حفظ
          AppButton(
            isLoading: controller.isLoading,
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
        ],
      ),
    );
  }
}
