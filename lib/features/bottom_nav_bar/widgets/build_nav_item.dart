import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/services/theme_service.dart';
import '../../../core/utils/app_colors.dart';

class BuildNavItem extends StatelessWidget {
  const BuildNavItem({
    Key? key,
    required this.isSelected,
    required this.onTap,
    required this.assetImage,
    required this.label,
  }) : super(key: key);

  final bool isSelected;
  final void Function() onTap;
  final String assetImage;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
}
