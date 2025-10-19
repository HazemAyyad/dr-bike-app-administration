import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/validator/validator.dart';
import '../controllers/sign_up_controller.dart';

class SignUpTextField extends StatelessWidget {
  const SignUpTextField({Key? key, required this.controller}) : super(key: key);

  final SignUpController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // name Field
        CustomTextField(
          controller: controller.nameController,
          label: 'name',
          hintText: 'name',
          labelColor: ThemeService.isDark.value
              ? AppColors.graywhiteColor
              : AppColors.customGreyColor,
          hintColor: AppColors.customGreyColor3,
          keyboardType: TextInputType.emailAddress,
          isRequired: true,
        ),
        SizedBox(height: 24.h),

        // Email Field
        CustomTextField(
          controller: controller.emailController,
          label: 'email',
          hintText: 'email',
          labelColor: ThemeService.isDark.value
              ? AppColors.graywhiteColor
              : AppColors.customGreyColor,
          hintColor: AppColors.customGreyColor3,
          keyboardType: TextInputType.emailAddress,
          isRequired: true,
          validator: (p0) => Validators.validateEmail(
            p0,
            Get.locale!.languageCode,
          ),
        ),

        SizedBox(height: 24.h),

        // Password Field
        ValueListenableBuilder(
          valueListenable: controller.obscurePassword,
          builder: (context, value, child) => CustomTextField(
            controller: controller.passwordController,
            label: 'password',
            hintText: '************',
            labelColor: ThemeService.isDark.value
                ? AppColors.graywhiteColor
                : AppColors.customGreyColor,
            hintColor: AppColors.customGreyColor3,
            keyboardType: TextInputType.visiblePassword,
            suffixIcon: IconButton(
              onPressed: () => controller.togglePasswordVisibility(),
              icon: Icon(
                controller.obscurePassword.value
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: ThemeService.isDark.value
                    ? AppColors.graywhiteColor
                    : AppColors.customGreyColor2,
              ),
            ),
            isRequired: true,
            obscureText: controller.obscurePassword.value,
            validator: (p0) => Validators.validatePassword(
              p0,
              Get.locale!.languageCode,
            ),
          ),
        ),

        SizedBox(height: 24.h),

        // Confirm Password Field
        ValueListenableBuilder(
          valueListenable: controller.obscurePassword,
          builder: (context, value, child) => CustomTextField(
            controller: controller.confirmPasswordController,
            label: 'confirmPassword',
            hintText: '************',
            labelColor: ThemeService.isDark.value
                ? AppColors.graywhiteColor
                : AppColors.customGreyColor,
            hintColor: AppColors.customGreyColor3,
            keyboardType: TextInputType.visiblePassword,
            isRequired: true,
            suffixIcon: IconButton(
              onPressed: () => controller.togglePasswordVisibility(),
              icon: Icon(
                controller.obscurePassword.value
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: ThemeService.isDark.value
                    ? AppColors.graywhiteColor
                    : AppColors.customGreyColor2,
              ),
            ),
            obscureText: controller.obscurePassword.value,
            textInputAction: TextInputAction.done,
            validator: (p0) => Validators.validatePassword(
              p0,
              Get.locale!.languageCode,
            ),
          ),
        ),
      ],
    );
  }
}
