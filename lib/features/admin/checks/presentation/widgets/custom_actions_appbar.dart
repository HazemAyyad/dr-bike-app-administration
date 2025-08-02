import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/checks_controller.dart';

class CustomActionsAppBar extends StatelessWidget {
  const CustomActionsAppBar({Key? key, required this.controller})
      : super(key: key);

  final ChecksController controller;

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
                    ? AppColors.darckColor
                    : AppColors.whiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(25.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(
                        () => ListTileTheme(
                          horizontalTitleGap: 0.0,
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppColors.primaryColor,
                            controlAffinity: ListTileControlAffinity.leading,
                            enableFeedback: true,
                            value: controller.dateFilter.value,
                            onChanged: (value) {
                              controller.dateFilter.value = value ?? false;
                            },
                            title: Row(
                              children: [
                                Text(
                                  'sortByDate'.tr,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                Text(
                                  'sortByDateDesc'.tr,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w400,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Obx(
                        () => ListTileTheme(
                          horizontalTitleGap: 0.0,
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppColors.primaryColor,
                            controlAffinity: ListTileControlAffinity.leading,
                            enableFeedback: true,
                            value: controller.amountFilter.value,
                            onChanged: (value) {
                              controller.amountFilter.value = value ?? false;
                            },
                            title: Row(
                              children: [
                                Text(
                                  'sortByAmount'.tr,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                Text(
                                  'sortByAmountDesc'.tr,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w400,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      CustomDropdownField(
                        label: 'beneficiary',
                        labelStyle:
                            Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  color: AppColors.primaryColor,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                        hint: 'customerNameExample',
                        items: controller.beneficiary,
                        onChanged: (value) {
                          controller.selectedBeneficiary = value ?? '';
                          print('المستفيد: ${controller.selectedBeneficiary}');
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
            controller.toggleAddMenu();
          },
        ),
      ],
    );
  }
}
