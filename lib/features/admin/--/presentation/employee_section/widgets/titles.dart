import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../my_orders/widgets/row_text.dart';

Container titles(BuildContext context, controller) {
  return Container(
    height: 35.h,
    decoration: BoxDecoration(
      color: ThemeService.isDark.value
          ? AppColors.secondaryColor
          : AppColors.primaryColor,
      borderRadius: BorderRadius.circular(6.r),
    ),
    child: Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (Get.locale!.languageCode == 'ar') SizedBox(),
          rowText(context, 'employeeName'),
          // SizedBox(),
          controller.currentTab.value == 0
              ? rowText(context, 'hourlyRate')
              : controller.currentTab.value == 1
                  ? rowText(context, 'workStartTime')
                  : SizedBox(
                      width: 80.w, child: rowText(context, 'salaryHours')),
          controller.currentTab.value == 0
              ? rowText(context, 'points')
              : controller.currentTab.value == 1
                  ? rowText(context, 'workEndTime')
                  : rowText(context, 'debts'),
          if (controller.currentTab.value == 1)
            SizedBox(
              width: 80.w,
              child: rowText(context, 'workHoursOfDay'),
            ),
          if (controller.currentTab.value == 2)
            Row(
              children: [
                Obx(
                  () => controller.currentTab.value == 2
                      ? SizedBox(width: 70.w)
                      : SizedBox(),
                ),
              ],
            )
        ],
      ),
    ),
  );
}
