import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';

Widget buildContactButton(
  BuildContext context, {
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : AppColors.whiteColor2,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            icon,
            size: 30.sp,
            color: ThemeService.isDark.value
                ? Colors.white
                : AppColors.secondaryColor,
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: ThemeService.isDark.value
                    ? Colors.white
                    : AppColors.secondaryColor,
              ),
        ),
      ],
    ),
  );
}
