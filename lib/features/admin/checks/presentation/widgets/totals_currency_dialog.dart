import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/checks_controller.dart';

class TotalsCurrencyDialog extends GetView<ChecksController> {
  const TotalsCurrencyDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24.w,
          vertical: 10.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'total'.tr,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: ThemeService.isDark.value
                            ? AppColors.primaryColor
                            : AppColors.secondaryColor,
                      ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            ...controller.totalsByCurrency.entries.map((entry) {
              return Column(
                children: [
                  Row(
                    children: [
                      Text(
                        '${entry.key.tr} : ',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        NumberFormat('#,###').format(entry.value),
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor,
                            ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                ],
              );
            })
          ],
        ),
      ),
    );
  }
}
