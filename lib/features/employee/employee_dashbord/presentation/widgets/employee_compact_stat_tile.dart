import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';

/// Compact stat cell for the employee home dashboard grid.
class EmployeeCompactStatTile extends StatelessWidget {
  const EmployeeCompactStatTile({
    Key? key,
    required this.title,
    required this.iconAsset,
    required this.value,
    this.subtitle,
    this.formatNumber = true,
    this.onTap,
  }) : super(key: key);

  final String title;
  final String iconAsset;
  final String value;
  final String? subtitle;
  final bool formatNumber;
  final VoidCallback? onTap;

  String get _displayValue {
    if (!formatNumber) return value;
    final n = double.tryParse(value.replaceAll(',', ''));
    if (n == null) return value;
    return NumberFormat('#,###.##').format(n);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor4
            : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor7
              : AppColors.customGreyColor4.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Image.asset(
                iconAsset,
                height: 14.h,
                width: 14.w,
                scale: 0.5,
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  title.tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor6
                        : AppColors.secondaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            _displayValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryColor,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Text(
              subtitle!.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8.sp,
                color: AppColors.customGreyColor5,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: child,
      ),
    );
  }
}
