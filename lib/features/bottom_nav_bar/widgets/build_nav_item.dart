import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/services/theme_service.dart';
import '../../../core/utils/app_colors.dart';
import '../controllers/bottom_nav_bar_controller.dart';

Widget buildNavItem({
  required String assetImage,
  required IconData filledIcon,
  required String label,
  required int index,
  required BottomNavBarController controller,
}) {
  final isSelected = controller.currentIndex.value == index;

  return InkWell(
    onTap: () => controller.changePage(index),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedScale(
          scale: isSelected ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Image.asset(
            assetImage,
            color: isSelected
                ? AppColors.secondaryColor
                : ThemeService.isDark.value
                    ? AppColors.whiteColor2
                    : AppColors.customGreyColor5,
            height: 29.h,
          ),
        ),
        Text(
          label,
          style: Theme.of(Get.context!).textTheme.bodyMedium!.copyWith(
                color: isSelected
                    ? AppColors.secondaryColor
                    : ThemeService.isDark.value
                        ? AppColors.whiteColor2
                        : AppColors.customGreyColor5,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    ),
  );
}
