import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/helpers/select_time.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/counters_controller.dart';

class Filter extends GetView<CountersController> {
  const Filter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      highlightColor: Colors.transparent,
      icon: Icon(
        Icons.calendar_today_outlined,
        size: 22.sp,
        color: ThemeService.isDark.value
            ? AppColors.primaryColor
            : AppColors.secondaryColor,
      ),
      onPressed: () {
        Get.dialog(
          Dialog(
            backgroundColor: ThemeService.isDark.value
                ? AppColors.darkColor
                : AppColors.whiteColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Form(
                key: controller.formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomDropdownField(
                      label: 'reportType'.tr,
                      hint: 'reportType'.tr,
                      onChanged: (value) {
                        controller.reportType = value!;
                      },
                      items: controller.reportTypeList,
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => selectDate(
                              context,
                              controller.fromDateController,
                            ),
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
                              controller: controller.fromDateController,
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
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => selectDate(
                              context,
                              controller.toDateController,
                            ),
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
                              controller: controller.toDateController,
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
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            isLoading: controller.isLoading,
                            isSafeArea: false,
                            text: 'apply',
                            textStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.whiteColor,
                                ),
                            onPressed: () {
                              if (controller.formKey.currentState!.validate()) {
                                Get.back();
                                controller.downloadReport(
                                  type: controller.reportType,
                                  context: context,
                                );
                                controller.reportType = '';
                                controller.fromDateController.clear();
                                controller.toDateController.clear();
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: AppButton(
                            isLoading: controller.isLoading,
                            isSafeArea: false,
                            color: Colors.red,
                            text: 'clear',
                            textStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.whiteColor,
                                ),
                            onPressed: () {
                              Get.back();
                              controller.reportType = '';
                              controller.fromDateController.clear();
                              controller.toDateController.clear();
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
      },
    );
  }
}
