import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/maintenance_controller.dart';

class NextBackButton extends StatelessWidget {
  const NextBackButton({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final MaintenanceController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme.bodyMedium!;

    return Obx(
      () => Row(
        children: [
          if (controller.selectedStep.value > 1)
            Expanded(
              child: AppButton(
                text: 'back',
                onPressed: () {
                  controller.prevStep();
                },
                isRtl: true,
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor4
                    : AppColors.whiteColor,
                borderColor: ThemeService.isDark.value
                    ? AppColors.customGreyColor2
                    : AppColors.secondaryColor,
                borderWidth: 1.w,
                textStyle: textTheme.copyWith(
                  color: ThemeService.isDark.value
                      ? AppColors.whiteColor
                      : AppColors.customGreyColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                ),
                widget: Icon(
                  Icons.arrow_back_rounded,
                  color: ThemeService.isDark.value
                      ? AppColors.whiteColor
                      : AppColors.secondaryColor,
                ),
              ),
            ),
          if (controller.selectedStep.value > 1) SizedBox(width: 15.w),
          controller.selectedStep.value == 3
              ? Expanded(
                  child: AppButton(
                    text: 'delivered',
                    borderWidth: 1.w,
                    color: Colors.green,
                    textStyle: textTheme.copyWith(
                      color: AppColors.whiteColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                    ),
                    onPressed: () {
                      controller.nextStep();
                    },
                  ),
                )
              : Expanded(
                  child: AppButton(
                    text: 'next',
                    borderWidth: 1.w,
                    textStyle: textTheme.copyWith(
                      color: AppColors.whiteColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                    ),
                    onPressed: () {
                      controller.nextStep();
                    },
                    widget: const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.whiteColor,
                    ),
                  ),
                )
        ],
      ),
    );
  }
}
