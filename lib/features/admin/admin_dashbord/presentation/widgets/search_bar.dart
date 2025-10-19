import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/admin_dashboard_controller.dart';

class CustomSearchBar extends GetView<AdminDashboardController> {
  const CustomSearchBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            // width: 200.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.whiteColor2,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'search'.tr,
                hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: AppColors.customGreyColor5,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w400,
                    ),
                border: InputBorder.none,
                prefixIcon: Image.asset(
                  AssetsManager.searchIcon,
                  height: 24.h,
                  width: 24.w,
                  color: AppColors.customGreyColor5,
                ),
                contentPadding: EdgeInsets.only(top: 6.h),
                isDense: true,
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        ClipOval(
          child: Container(
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : AppColors.whiteColor2,
            child: IconButton(
              highlightColor: Colors.transparent,
              focusColor: Colors.transparent,
              icon: Icon(
                Icons.history_rounded,
                color: AppColors.primaryColor,
                size: 25.sp,
              ),
              onPressed: () {
                controller.getLogs();
                Get.toNamed(AppRoutes.ADMINACTIVTILOGSCREEN);
              },
            ),
          ),
        ),
        SizedBox(width: 10.w),
        ClipOval(
          child: Container(
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : AppColors.whiteColor2,
            child: IconButton(
              highlightColor: Colors.transparent,
              focusColor: Colors.transparent,
              icon: Icon(
                Icons.notifications_none,
                color: AppColors.primaryColor,
                size: 25.sp,
              ),
              onPressed: () {},
            ),
          ),
        ),
      ],
    );
  }
}
