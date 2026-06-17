import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/sales_controller.dart';

/// Search + sort + package filter for instant sales list.
class SalesInvoicesToolbar extends GetView<SalesController> {
  const SalesInvoicesToolbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.instantSalesSearchController,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: ThemeService.isDark.value
                        ? AppColors.whiteColor
                        : AppColors.darkColor,
                  ),
                  onChanged: controller.onInstantSalesSearchChanged,
                  onSubmitted: controller.onInstantSalesSearchSubmitted,
                  decoration: InputDecoration(
                    hintText: 'searchInvoicesHint'.tr,
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
                      vertical: 12.h,
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
          SizedBox(height: 8.h),
          Obx(
            () {
              final mode = controller.instantSalesPackageFilter.value;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'instantSaleFilterAll'.tr,
                      selected: mode == 0,
                      onTap: () => controller.setInstantSalesPackageFilter(0),
                    ),
                    SizedBox(width: 6.w),
                    _FilterChip(
                      label: 'instantSaleCompositionPackage'.tr,
                      selected: mode == 1,
                      accent: const Color(0xFFE65100),
                      onTap: () => controller.setInstantSalesPackageFilter(1),
                    ),
                    SizedBox(width: 6.w),
                    _FilterChip(
                      label: 'instantSaleCompositionMixed'.tr,
                      selected: mode == 2,
                      accent: const Color(0xFF6A1B9A),
                      onTap: () => controller.setInstantSalesPackageFilter(2),
                    ),
                    SizedBox(width: 6.w),
                    _FilterChip(
                      label: 'instantSaleCompositionProduct'.tr,
                      selected: mode == 3,
                      onTap: () => controller.setInstantSalesPackageFilter(3),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.accent,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.primaryColor;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? color : null,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color.withValues(alpha: 0.14),
      checkmarkColor: color,
      side: BorderSide(
        color: selected ? color : Colors.grey.shade400,
      ),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0),
    );
  }
}
