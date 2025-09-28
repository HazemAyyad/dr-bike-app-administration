import 'package:doctorbike/core/helpers/custom_chechbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
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
              WillPopScope(
                onWillPop: () async {
                  controller.applyFilters();
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
                    padding: EdgeInsets.all(25.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomCheckBox(
                          title: "${'sortByDate'.tr} ",
                          subtitle: 'sortByDateDesc',
                          value: controller.dateFilter,
                          onChanged: (value) {
                            controller.dateFilter.value = value ?? false;
                          },
                        ),
                        CustomCheckBox(
                          title: "${'sortByAmount'.tr} ",
                          subtitle: 'sortByAmountDesc',
                          value: controller.amountFilter,
                          onChanged: (value) {
                            controller.amountFilter.value = value ?? false;
                          },
                        ),
                        CustomTextField(
                          label: 'beneficiary'.tr,
                          labelTextstyle:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: AppColors.primaryColor,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                          hintText: 'customerNameExample',
                          controller: controller.employeeNameController,
                        ),
                        SizedBox(height: 30.h),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
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
                                  controller.applyFilters();
                                },
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: AppButton(
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
                                  controller.amountFilter.value = false;
                                  controller.dateFilter.value = false;
                                  controller.employeeNameController.clear();
                                  controller.applyFilters();
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
        ),
        // IconButton(
        //   highlightColor: Colors.transparent,
        //   icon: Icon(
        //     Icons.add_circle,
        //     size: 32.sp,
        //     color: ThemeService.isDark.value
        //         ? AppColors.primaryColor
        //         : AppColors.secondaryColor,
        //   ),
        //   onPressed: () {
        //     // Handle add action
        //     Get.toNamed(
        //       AppRoutes.NEWCHECKSCREEN,
        //       arguments: {'isNewCheck': isNewCheck},
        //     );
        //   },
        // ),
        SizedBox(width: 10.w),
      ],
    );
  }
}
