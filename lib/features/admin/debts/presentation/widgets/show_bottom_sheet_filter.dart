import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/debts_controller.dart';

void showSortBottomSheet(BuildContext context, DebtsController controller) {
  Get.bottomSheet(
    Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 20.h,
                  height: 20.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(
                      color: AppColors.primaryColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.close,
                      color: AppColors.primaryColor,
                      size: 16.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Center(
            child: Text(
              'sort_by'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: ThemeService.isDark.value
                        ? Colors.white
                        : AppColors.secondaryColor,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          SizedBox(height: 25.h),
          Obx(() => Column(
                children: [
                  buildSortOption('all'.tr, 'all', context, controller),
                  buildSortOption('ended'.tr, 'ended', context, controller),
                  buildSortOption(
                      'not_ended'.tr, 'not_ended', context, controller),
                  buildSortOption('new_transactions'.tr, 'new_transactions',
                      context, controller),
                  buildSortOption('old_transactions'.tr, 'old_transactions',
                      context, controller),
                  buildSortOption('largest_amount'.tr, 'largest_amount',
                      context, controller),
                  buildSortOption('smallest_amount'.tr, 'smallest_amount',
                      context, controller),
                  buildSortOption(
                      'alphabetical'.tr, 'alphabetical', context, controller),
                ],
              )),
          SizedBox(height: 20.h),
        ],
      ),
    ),
    isScrollControlled: true,
    backgroundColor:
        ThemeService.isDark.value ? AppColors.darckColor : Colors.white,
  );
}

Widget buildSortOption(
    String title, String value, BuildContext context, controller) {
  final isSelected = controller.sortBy.value == value;

  return InkWell(
    onTap: () {
      controller.setSortBy(value);
      Get.back();
    },
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? Color(0xFF1E3A8A).withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: isSelected
                        ? AppColors.primaryColor
                        : AppColors.customGreyColor5,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check,
              color: Color(0xFF1E3A8A),
              size: 20,
            ),
        ],
      ),
    ),
  );
}
