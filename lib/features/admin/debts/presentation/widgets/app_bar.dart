import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/debts_controller.dart';
import 'show_bottom_sheet_filter.dart';

AppBar appBar(
  String tital,
  bool actions,
  BuildContext context,
  DebtsController controller,
  String? supTitle,
  Color? color,
) {
  return AppBar(
    title: Row(
      children: [
        Text(
          tital.tr,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
              ),
        ),
        Text(
          " ${supTitle!.tr}",
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
        ),
      ],
    ),
    leading: IconButton(
      icon: Icon(
        Icons.arrow_back_ios_new_rounded,
        color: ThemeService.isDark.value
            ? AppColors.primaryColor
            : AppColors.secondaryColor,
      ),
      onPressed: () => Get.back(),
    ),
    actions: actions
        ? [
            IconButton(
              highlightColor: Colors.transparent,
              icon: Icon(
                Icons.tune,
                size: 22.sp,
                color: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
              ),
              onPressed: () {
                showSortBottomSheet(context, controller);
              },
            ),
            SizedBox(width: 10.w)
          ]
        : null,
  );
}
