import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';

Widget buildSidebarItem(String title, IconData icon, Function()? route) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 15.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: route,
          child: Row(
            children: [
              Icon(
                icon,
                color: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
                size: 25.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                title,
                style: Theme.of(Get.context!).textTheme.bodyMedium!.copyWith(
                      color: ThemeService.isDark.value
                          ? Colors.white
                          : AppColors.customGreyColor,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
