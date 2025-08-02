import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../../core/services/theme_service.dart';
import '../../../../../../../core/utils/app_colors.dart';

Obx partnershipData(controller) {
  return Obx(
    () {
      return controller.projectPartners.value.isNotEmpty &&
              !controller.noPartnerValues
                  .contains(controller.projectPartners.value)
          ? Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  CustomTextField(
                    isRequired: true,
                    label: 'partnerShare',
                    labelColor: ThemeService.isDark.value
                        ? AppColors.customGreyColor6
                        : AppColors.customGreyColor,
                    hintText: 'partnerShareExample',
                    hintColor: ThemeService.isDark.value
                        ? AppColors.customGreyColor
                        : AppColors.customGreyColor6,
                    controller: controller.partnerShareController,
                  ),
                  SizedBox(height: 10.h),
                  CustomTextField(
                    isRequired: true,
                    label: 'partnerPercentage',
                    labelColor: ThemeService.isDark.value
                        ? AppColors.customGreyColor6
                        : AppColors.customGreyColor,
                    hintText: 'partnerPercentageExample',
                    hintColor: ThemeService.isDark.value
                        ? AppColors.customGreyColor
                        : AppColors.customGreyColor6,
                    controller: controller.partnerPercentageController,
                  ),
                ],
              ),
            )
          : SizedBox.shrink();
    },
  );
}
