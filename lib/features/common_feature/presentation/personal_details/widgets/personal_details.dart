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
    return GetBuilder<PersonalDetailsController>(
      builder: (controller) {
        if (controller.isLoading.value && !controller.isProfileLoaded.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 10.h),
              CustomTextField(
                label: 'name',
                hintText: 'name'.tr,
                controller: controller.nameController,
              ),
              SizedBox(height: 16.h),
              CustomTextField(
                label: 'email',
                hintText: 'email'.tr,
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    Validators.validateEmail(value, Get.locale!.languageCode),
              ),
              SizedBox(height: 16.h),
              CustomPhoneField(
                label: 'phoneNumber',
                controller: controller.phoneController,
                hintText: 'phoneNumber'.tr,
                isRequired: !controller.isAdmin,
              ),
              SizedBox(height: 16.h),
              if (!controller.isAdmin) ...[
                CustomPhoneField(
                  label: 'alternatePhone',
                  controller: controller.subPhoneController,
                  hintText: 'alternatePhone'.tr,
                ),
                SizedBox(height: 10.h),
              ],
              dropdownButton(controller),
              SizedBox(height: 10.h),
              addressField(controller),
              SizedBox(height: 10.h),
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
      },
    );
  }
}
