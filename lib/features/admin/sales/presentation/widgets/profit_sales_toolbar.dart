import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/sales_controller.dart';

class ProfitSalesToolbar extends GetView<SalesController> {
  const ProfitSalesToolbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 4.h),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Obx(
          () => Tooltip(
            message: controller.profitSalesSortDescending.value
                ? 'sortNewestFirst'.tr
                : 'sortOldestFirst'.tr,
            child: Material(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.whiteColor2,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: controller.toggleProfitSalesSort,
                child: SizedBox(
                  width: 44.w,
                  height: 44.w,
                  child: Icon(
                    controller.profitSalesSortDescending.value
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: AppColors.primaryColor,
                    size: 22.sp,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
