// بناء بطاقة إحصائية واحدة
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String imageicon;
  final String value;
  final String subtitle;
  final bool show;
  final Function()? onTap;

  const StatCard({
    Key? key,
    required this.title,
    required this.imageicon,
    required this.value,
    required this.subtitle,
    this.onTap,
    this.show = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor4
              : Colors.white,
          borderRadius: BorderRadius.circular(5.r),
        ),
        padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  imageicon,
                  height: 20.h,
                  width: 20.w,
                  scale: 0.5,
                ),
                SizedBox(width: 5.w),
                Flexible(
                  child: Text(
                    title.tr,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: ThemeService.isDark.value
                          ? Colors.white
                          : AppColors.secondaryColor,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 5.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    show
                        ? value.toString()
                        : NumberFormat('#,###')
                            .format(double.parse(value.toString())),
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: AppColors.primaryColor,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    subtitle.tr,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: AppColors.primaryColor,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
