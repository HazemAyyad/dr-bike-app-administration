// بناء بطاقة إحصائية واحدة
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String? imageicon;
  final IconData? icon;
  final String value;
  final String subtitle;
  final bool show;
  final Function()? onTap;

  const StatCard({
    Key? key,
    required this.title,
    this.imageicon,
    this.icon,
    required this.value,
    required this.subtitle,
    this.onTap,
    this.show = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedValue = show
        ? value
        : NumberFormat('#,###').format(double.tryParse(value) ?? 0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.all(5.r),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor4
              : Colors.white,
          borderRadius: BorderRadius.circular(5.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 8.h),
        child: Row(
          children: [
            Container(
              width: 29.r,
              height: 29.r,
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: icon != null
                  ? Icon(icon, color: AppColors.primaryColor, size: 17.sp)
                  : Image.asset(
                      imageicon!,
                      color: AppColors.primaryColor,
                      fit: BoxFit.contain,
                    ),
            ),
            SizedBox(width: 7.w),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: ThemeService.isDark.value
                          ? Colors.white
                          : AppColors.secondaryColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    formattedValue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: AppColors.primaryColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
