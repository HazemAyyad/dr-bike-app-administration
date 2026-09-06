import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/sales_returns_controller.dart';

class SalesReturnsToolbar extends GetView<SalesReturnsController> {
  const SalesReturnsToolbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 4.h),
      child: Obx(
        () => Row(
          children: [
            _DateNavButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'اليوم السابق',
              onTap: () => controller.changeReturnsDateByDays(-1),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14.r),
                onTap: () => controller.pickReturnsDate(context),
                child: Container(
                  height: 42.h,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor
                        : AppColors.whiteColor2,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: .18),
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
                          controller.selectedReturnsDateLabel,
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
              enabled: controller.canGoNextReturnsDate,
              onTap: () => controller.changeReturnsDateByDays(1),
            ),
          ],
        ),
      ),
    );
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
                  : Colors.grey.withValues(alpha: .55),
              size: 24.sp,
            ),
          ),
        ),
      ),
    );
  }
}
