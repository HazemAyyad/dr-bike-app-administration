import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/validator/validator.dart';
import '../controllers/sginup_verify_controller.dart';

class EmailFieldWithChangeButton extends StatelessWidget {
  const EmailFieldWithChangeButton({Key? key, required this.controller})
      : super(key: key);

  final SginupVerifyController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        return Stack(
          children: [
            CustomTextField(
              controller: controller.signUpController.emailController,
              label: 'email',
              hintText: 'email',
              labelColor: ThemeService.isDark.value
                  ? AppColors.graywhiteColor
                  : AppColors.customGreyColor,
              hintColor: AppColors.customGreyColor3,
              keyboardType: TextInputType.emailAddress,
              validator: (p0) => Validators.validateEmail(
                p0,
                Get.locale!.languageCode,
              ),
              enabled: controller.isEditing.value,
            ),
            Positioned(
              right: Get.locale!.languageCode == 'ar' ? 315.w : 15.w,
              bottom: controller.isFormValid.value ? 0.h : 20.h,
              child: TextButton(
                onPressed: controller.toggleEditing,
                child: Text(
                  controller.isEditing.value ? "done".tr : "change".tr,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: AppColors.primaryColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
