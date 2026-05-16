import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/stock_controller.dart';
import 'search_widget.dart';
import 'stock_filter_sheet.dart';

/// Search row with filter action for the products inventory tab.
class StockSearchBar extends GetView<StockController> {
  const StockSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: const SearchWidget(isCloseouts: false),
        ),
        SizedBox(width: 8.w),
        Obx(() {
          final active = controller.productListFilters.value.hasActiveFilters;
          return Material(
            color: active
                ? AppColors.primaryColor.withValues(alpha: 0.15)
                : (ThemeService.isDark.value
                    ? AppColors.customGreyColor
                    : AppColors.whiteColor2),
            borderRadius: BorderRadius.circular(25),
            child: IconButton(
              tooltip: 'timeFilter'.tr,
              icon: Icon(
                Icons.filter_list,
                color: active
                    ? AppColors.primaryColor
                    : (ThemeService.isDark.value
                        ? AppColors.whiteColor
                        : AppColors.secondaryColor),
              ),
              onPressed: () {
                Get.bottomSheet(
                  const StockFilterSheet(),
                  isScrollControlled: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                );
              },
            ),
          );
        }),
      ],
    );
  }
}
