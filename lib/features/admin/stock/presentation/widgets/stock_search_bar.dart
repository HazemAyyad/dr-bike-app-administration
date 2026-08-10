import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/stock_controller.dart';
import 'search_widget.dart';
import 'stock_filter_sheet.dart';

/// Search row with a clear filter action for the products inventory tab.
class StockSearchBar extends GetView<StockController> {
  const StockSearchBar({
    Key? key,
    this.compact = false,
  }) : super(key: key);

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 38.0 : 44.w;
    final iconSize = compact ? 20.0 : 22.sp;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: height,
              child: const SearchWidget(isCloseouts: false),
            ),
          ),
          SizedBox(width: compact ? 8 : 8.w),
          Obx(() {
            final filters = controller.productListFilters.value;
            final count = filters.activeFilterCount;
            final active = filters.hasActiveFilters;

            return Tooltip(
              message: 'stockFilter'.tr,
              child: Material(
                color: active
                    ? AppColors.primaryColor.withValues(alpha: 0.12)
                    : (ThemeService.isDark.value
                        ? AppColors.customGreyColor
                        : AppColors.whiteColor2),
                elevation: active ? 1 : 0,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    Get.bottomSheet(
                      const StockFilterSheet(),
                      isScrollControlled: true,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                    );
                  },
                  child: SizedBox(
                    width: height,
                    height: height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: iconSize,
                          color: active
                              ? AppColors.primaryColor
                              : (ThemeService.isDark.value
                                  ? AppColors.whiteColor
                                  : AppColors.secondaryColor),
                        ),
                        if (count > 0)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: count > 9 ? 4.w : 5.w,
                                vertical: 2.h,
                              ),
                              constraints: BoxConstraints(
                                minWidth: compact ? 16 : 16.w,
                                minHeight: compact ? 16 : 16.w,
                              ),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                count > 9 ? '9+' : '$count',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: compact ? 9 : 9.sp,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                ),
                              ),
                            ),
                          )
                        else if (active)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              width: compact ? 8 : 8.w,
                              height: compact ? 8 : 8.w,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
