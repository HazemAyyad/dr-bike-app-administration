import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/validator/validator.dart';
import '../controllers/login_controller.dart';

class LogInTextField extends StatelessWidget {
  const LogInTextField({Key? key, required this.controller}) : super(key: key);

  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextField(
          controller: controller.emailController,
          label: 'email',
          hintText: 'email',
          isRequired: true,
          keyboardType: TextInputType.emailAddress,
          validator: (p0) =>
              Validators.validateEmail(p0, Get.locale!.languageCode),
        ),
        SizedBox(height: 24.h),
        Obx(
          () => CustomTextField(
            controller: controller.passwordController,
            label: 'password',
            hintText: '************',
            isRequired: true,
            keyboardType: TextInputType.visiblePassword,
            suffixIcon: IconButton(
              onPressed: () => controller.togglePasswordVisibility(),
              icon: Icon(
                controller.isPasswordVisible.value
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: ThemeService.isDark.value
                    ? AppColors.graywhiteColor
                    : AppColors.customGreyColor2,
              ),
            ),
            obscureText: controller.isPasswordVisible.value,
            textInputAction: TextInputAction.done,
          ),
        ),
      ],
    );
  }
}
