import 'package:doctorbike/core/helpers/select_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../services/theme_service.dart';
import '../utils/app_colors.dart';
import 'app_button.dart';
import 'custom_text_field.dart';

void showCustomDialog(
  BuildContext context, {
  TextEditingController? fromDateController,
  TextEditingController? toDateController,
  TextEditingController? employeeNameController,
  required String label,
  required VoidCallback onPressed,
  VoidCallback? onClear,
}) {
  Get.dialog(
    // ignore: deprecated_member_use
    WillPopScope(
      onWillPop: () async {
        onPressed();
        return true;
      },
      child: Dialog(
        backgroundColor: ThemeService.isDark.value
            ? AppColors.darkColor
            : AppColors.whiteColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'search'.tr,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: ThemeService.isDark.value
                          ? AppColors.primaryColor
                          : AppColors.secondaryColor,
                    ),
              ),
              toDateController != null || fromDateController != null
                  ? SizedBox(height: 10.h)
                  : const SizedBox(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  fromDateController != null
                      ? Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                selectDate(context, fromDateController),
                            child: CustomTextField(
                              enabled: false,
                              decoration: BoxDecoration(
                                color: ThemeService.isDark.value
                                    ? AppColors.customGreyColor
                                    : AppColors.whiteColor2,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              label: '',
                              hintText: 'from',
                              hintStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    color: AppColors.customGreyColor5,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                              controller: fromDateController,
                              suffixIcon: Icon(
                                Icons.calendar_today_outlined,
                                size: 19.sp,
                                color: AppColors.primaryColor,
                              ),
                              suffixIconColor: ThemeService.isDark.value
                                  ? AppColors.whiteColor
                                  : AppColors.primaryColor,
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  SizedBox(width: 8.w),
                  toDateController != null
                      ? Expanded(
                          child: GestureDetector(
                            onTap: () => selectDate(context, toDateController),
                            child: CustomTextField(
                              enabled: false,
                              decoration: BoxDecoration(
                                color: ThemeService.isDark.value
                                    ? AppColors.customGreyColor
                                    : AppColors.whiteColor2,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              label: '',
                              hintText: 'to',
                              hintStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    color: AppColors.customGreyColor5,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                              controller: toDateController,
                              suffixIcon: Icon(
                                Icons.calendar_today_outlined,
                                size: 19.sp,
                                color: AppColors.primaryColor,
                              ),
                              suffixIconColor: ThemeService.isDark.value
                                  ? AppColors.whiteColor
                                  : AppColors.primaryColor,
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
              toDateController != null || fromDateController != null
                  ? SizedBox(height: 15.h)
                  : const SizedBox.shrink(),
              employeeNameController != null
                  ? CustomTextField(
                      label: label.tr,
                      labelTextstyle:
                          Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: AppColors.primaryColor,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                              ),
                      fillColor: ThemeService.isDark.value
                          ? AppColors.customGreyColor
                          : AppColors.whiteColor2,
                      hintText: 'employeeNameExample',
                      controller: employeeNameController,
                    )
                  : const SizedBox.shrink(),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      isSafeArea: false,
                      text: 'apply',
                      textStyle:
                          Theme.of(context).textTheme.bodyMedium!.copyWith(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.whiteColor,
                              ),
                      onPressed: onPressed,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: AppButton(
                      isSafeArea: false,
                      color: Colors.red,
                      text: 'clear',
                      textStyle:
                          Theme.of(context).textTheme.bodyMedium!.copyWith(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.whiteColor,
                              ),
                      onPressed: onClear ??
                          () {
                            fromDateController?.clear();
                            toDateController?.clear();
                            employeeNameController?.clear();
                            onPressed();
                          },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
