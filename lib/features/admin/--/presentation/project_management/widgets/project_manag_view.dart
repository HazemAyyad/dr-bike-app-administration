import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/utils/assets_manger.dart';
import '../../../../../../routes/app_routes.dart';
import 'projects_details.dart';

Expanded projectManagementView(controller) {
  return Expanded(
    child: Obx(
      () => AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: ListView.builder(
          key: ValueKey<int>(controller.currentTab.value),
          itemCount: controller.projectList.length,
          itemBuilder: (context, index) {
            final order = controller.projectList[index];
            return InkWell(
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              onTap: () =>
                  Get.toNamed(AppRoutes.PROJECTDETAILSSCREEN, arguments: order),
              child: Container(
                padding: EdgeInsets.all(15),
                margin: EdgeInsets.symmetric(vertical: 5.h),
                // height: 32.h,
                decoration: BoxDecoration(
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor
                      : AppColors.whiteColor2,
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // projects Details
                    projectsDetails(
                      context,
                      order,
                      icon: AssetsManger.frameIcon,
                      tital: 'projectName',
                    ),
                    projectsDetails(
                      context,
                      order,
                      icon: AssetsManger.percentageIcon,
                      tital: 'completionPercentage',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
