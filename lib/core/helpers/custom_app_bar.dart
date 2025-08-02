import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../services/theme_service.dart';
import '../utils/app_colors.dart';
import 'costom_dialog_filter.dart';

AppBar customAppBar(
  BuildContext context, {
  required String title,
  String? label,
  TextEditingController? fromDateController,
  TextEditingController? toDateController,
  TextEditingController? employeeNameController,
  VoidCallback? onPressedAdd,
  bool? action = true,
  List<Widget>? actions,
}) {
  return AppBar(
    title: Text(
      title.tr,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: ThemeService.isDark.value
                ? AppColors.primaryColor
                : AppColors.secondaryColor,
          ),
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
    actions: actions ??
        [
          if (fromDateController != null &&
              toDateController != null &&
              employeeNameController != null)
            IconButton(
              highlightColor: Colors.transparent,
              icon: Icon(
                Icons.calendar_today_outlined,
                size: 22.sp,
                color: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
              ),
              onPressed: () {
                showCustomDialog(
                  context,
                  fromDateController: fromDateController,
                  toDateController: toDateController,
                  employeeNameController: employeeNameController,
                  label: label ?? 'employeeName',
                  onPressed: () {},
                );
              },
            ),
          action!
              ? IconButton(
                  highlightColor: Colors.transparent,
                  icon: Icon(
                    Icons.add_circle,
                    size: 32.sp,
                    color: ThemeService.isDark.value
                        ? AppColors.primaryColor
                        : AppColors.secondaryColor,
                  ),
                  onPressed: onPressedAdd,
                )
              : SizedBox(),
          SizedBox(width: 10.w)
        ],
  );
}
