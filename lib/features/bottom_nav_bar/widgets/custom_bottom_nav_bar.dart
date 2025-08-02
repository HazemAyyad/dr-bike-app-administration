import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/services/theme_service.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/assets_manger.dart';
import '../controllers/bottom_nav_bar_controller.dart';
import 'build_nav_item.dart';

Widget customBottomNavigationBar({
  required BuildContext context,
  required BottomNavBarController controller,
}) {
  return SizedBox(
    height: 70.h, // ارتفاع شريط التنقل
    child: Obx(
      () => Container(
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.greyColor
              : AppColors.whiteColor2,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18.r),
            topRight: Radius.circular(18.r),
          ),
        ),
        child: Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildNavItem(
                assetImage: AssetsManger.homeIcon,
                filledIcon: Icons.home,
                label: 'home'.tr,
                index: 0,
                controller: controller,
              ),
              buildNavItem(
                assetImage: AssetsManger.taskIcon,
                filledIcon: Icons.assignment,
                label: 'newTask'.tr,
                index: 1,
                controller: controller,
              ),
              buildNavItem(
                assetImage: AssetsManger.profileIcon,
                filledIcon: Icons.person,
                label: 'profile'.tr,
                index: 2,
                controller: controller,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
