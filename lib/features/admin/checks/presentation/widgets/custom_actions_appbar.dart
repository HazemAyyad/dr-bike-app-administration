import 'package:doctorbike/core/helpers/custom_chechbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/checks_controller.dart';

class CustomActionsAppBar extends GetView<ChecksController> {
  const CustomActionsAppBar({Key? key, required this.isNewCheck})
      : super(key: key);

  final bool isNewCheck;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
            Get.dialog(
              Dialog(
                backgroundColor: ThemeService.isDark.value
                    ? AppColors.darkColor
                    : AppColors.whiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(25.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomCheckBox(
                        title: 'sortByDate',
                        subtitle: 'sortByDateDesc',
                        value: controller.dateFilter,
                        onChanged: (value) {
                          controller.dateFilter.value = value ?? false;
                        },
                      ),
                      CustomCheckBox(
                        title: 'sortByAmount',
                        subtitle: 'sortByAmountDesc',
                        value: controller.amountFilter,
                        onChanged: (value) {
                          controller.amountFilter.value = value ?? false;
                        },
                      ),
                      CustomDropdownField(
                        label: 'beneficiary',
                        labelTextStyle:
                            Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  color: AppColors.primaryColor,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                        hint: 'customerNameExample',
                        items: controller.beneficiary,
                        onChanged: (value) {
                          controller.selectedBeneficiary = value ?? '';
                        },
                      ),
                      SizedBox(height: 30.h),
                      AppButton(
                        text: 'apply',
                        textStyle:
                            Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.whiteColor,
                                ),
                        onPressed: () {
                          // Handle apply filter action
                          Get.back();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        IconButton(
          highlightColor: Colors.transparent,
          icon: Icon(
            Icons.add_circle,
            size: 32.sp,
            color: ThemeService.isDark.value
                ? AppColors.primaryColor
                : AppColors.secondaryColor,
          ),
          onPressed: () {
            // Handle add action
            Get.toNamed(
              AppRoutes.NEWCHECKSCREEN,
              arguments: {'isNewCheck': isNewCheck},
            );
          },
        ),
      ],
    );
  }
}
