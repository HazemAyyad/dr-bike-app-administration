import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/sales_controller.dart';

/// Date navigation for sales lists and composition filters for instant sales.
class SalesInvoicesToolbar extends GetView<SalesController> {
  const SalesInvoicesToolbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isProfitSales = controller.currentTab.value == 1;
      final dateLabel = isProfitSales
          ? controller.selectedProfitSalesDateLabel
          : controller.selectedInstantSalesDateLabel;

      return Padding(
        padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 4.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _DateNavButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'اليوم السابق',
                  onTap: () => isProfitSales
                      ? controller.changeProfitSalesDateByDays(-1)
                      : controller.changeInstantSalesDateByDays(-1),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14.r),
                    onTap: () => isProfitSales
                        ? controller.pickProfitSalesDate(context)
                        : controller.pickInstantSalesDate(context),
                    child: Container(
                      height: 42.h,
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: ThemeService.isDark.value
                            ? AppColors.customGreyColor
                            : AppColors.whiteColor2,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: AppColors.primaryColor.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            color: AppColors.primaryColor,
                            size: 19.sp,
                          ),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: Text(
                              dateLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                                color: ThemeService.isDark.value
                                    ? AppColors.whiteColor
                                    : AppColors.darkColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                _DateNavButton(
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'اليوم التالي',
                  enabled: isProfitSales
                      ? controller.canGoNextProfitSalesDate
                      : controller.canGoNextInstantSalesDate,
                  onTap: () => isProfitSales
                      ? controller.changeProfitSalesDateByDays(1)
                      : controller.changeInstantSalesDateByDays(1),
                ),
              ],
            ),
            if (!isProfitSales) ...[
              SizedBox(height: 8.h),
              Builder(builder: (context) {
                final mode = controller.instantSalesPackageFilter.value;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _CompositionFilter(
                        label: 'instantSaleFilterAll'.tr,
                        icon: Icons.grid_view_rounded,
                        count: controller.instantSalesCompositionCount(0),
                        selected: mode == 0,
                        onTap: () => controller.setInstantSalesPackageFilter(0),
                      ),
                      SizedBox(width: 6.w),
                      _CompositionFilter(
                        label: 'instantSaleCompositionPackage'.tr,
                        icon: Icons.inventory_2_outlined,
                        count: controller.instantSalesCompositionCount(1),
                        selected: mode == 1,
                        accent: const Color(0xFFE65100),
                        onTap: () => controller.setInstantSalesPackageFilter(1),
                      ),
                      SizedBox(width: 6.w),
                      _CompositionFilter(
                        label: 'instantSaleCompositionMixed'.tr,
                        icon: Icons.layers_outlined,
                        count: controller.instantSalesCompositionCount(2),
                        selected: mode == 2,
                        accent: const Color(0xFF6A1B9A),
                        onTap: () => controller.setInstantSalesPackageFilter(2),
                      ),
                      SizedBox(width: 6.w),
                      _CompositionFilter(
                        label: 'instantSaleCompositionProduct'.tr,
                        icon: Icons.two_wheeler_outlined,
                        count: controller.instantSalesCompositionCount(3),
                        selected: mode == 3,
                        onTap: () => controller.setInstantSalesPackageFilter(3),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      );
    });
  }
}

class _DateNavButton extends StatelessWidget {
  const _DateNavButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: 42.w,
            height: 42.w,
            child: Icon(
              icon,
              color: enabled
                  ? AppColors.primaryColor
                  : Colors.grey.withValues(alpha: 0.55),
              size: 24.sp,
            ),
          ),
        ),
      ),
    );
  }
}

class _CompositionFilter extends StatelessWidget {
  const _CompositionFilter({
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
    this.accent,
  });

  final String label;
  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.primaryColor;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.10),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, color: selected ? Colors.white : color, size: 21.sp),
              if (count > 0)
                PositionedDirectional(
                  top: -5.h,
                  end: -6.w,
                  child: Container(
                    constraints: BoxConstraints(minWidth: 18.w),
                    padding:
                        EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(99.r),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
