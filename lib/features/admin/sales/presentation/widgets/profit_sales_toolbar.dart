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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.profitSalesSearchController,
              textInputAction: TextInputAction.search,
              style: TextStyle(
                fontSize: 14.sp,
                color: ThemeService.isDark.value
                    ? AppColors.whiteColor
                    : AppColors.darkColor,
              ),
              onChanged: controller.onProfitSalesSearchChanged,
              onSubmitted: controller.onProfitSalesSearchSubmitted,
              decoration: InputDecoration(
                hintText: 'بحث في الربح النقدي',
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor5
                      : AppColors.customGreyColor4,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: ThemeService.isDark.value
                      ? AppColors.whiteColor
                      : AppColors.secondaryColor,
                ),
                suffixIcon: Obx(() {
                  if (controller.profitSalesSearchQuery.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: controller.clearProfitSalesSearch,
                  );
                }),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.r),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: ThemeService.isDark.value
                    ? AppColors.customGreyColor
                    : AppColors.whiteColor2,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12.h,
                  horizontal: 12.w,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Obx(
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
        ],
      ),
    );
  }
}
