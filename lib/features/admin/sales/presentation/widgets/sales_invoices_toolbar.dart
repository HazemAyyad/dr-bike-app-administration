import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/sales_controller.dart';

/// Search + sort controls for the instant sales invoices list.
class SalesInvoicesToolbar extends GetView<SalesController> {
  const SalesInvoicesToolbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 4.h),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.instantSalesSearchController,
              textInputAction: TextInputAction.search,
              onChanged: controller.onInstantSalesSearchChanged,
              onSubmitted: controller.onInstantSalesSearchSubmitted,
              decoration: InputDecoration(
                hintText: 'searchInvoicesHint'.tr,
                prefixIcon: Icon(
                  Icons.search,
                  color: ThemeService.isDark.value
                      ? AppColors.whiteColor
                      : AppColors.secondaryColor,
                ),
                suffixIcon: Obx(() {
                  if (controller.instantSalesSearchQuery.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: controller.clearInstantSalesSearch,
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
                  vertical: 0,
                  horizontal: 12.w,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Obx(
            () => Tooltip(
              message: controller.instantSalesSortDescending.value
                  ? 'sortNewestFirst'.tr
                  : 'sortOldestFirst'.tr,
              child: Material(
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor
                    : AppColors.whiteColor2,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: controller.toggleInstantSalesSort,
                  child: SizedBox(
                    width: 44.w,
                    height: 44.w,
                    child: Icon(
                      controller.instantSalesSortDescending.value
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
