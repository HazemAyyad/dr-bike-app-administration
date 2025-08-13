import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../../../employee_tasks/presentation/views/task_details_screen.dart';
import '../controllers/employee_section_controller.dart';

class EmployeeDetailsScreen extends GetView<EmployeeSectionController> {
  const EmployeeDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> arguments = Get.arguments;
    final TextStyle theme = Theme.of(context).textTheme.bodyMedium!;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'employeeDetails',
        actions: [
          TextButton.icon(
            icon: Icon(
              Icons.edit_calendar_outlined,
              color: ThemeService.isDark.value
                  ? AppColors.primaryColor
                  : AppColors.secondaryColor,
              size: 25.sp,
            ),
            onPressed: () {
              Get.toNamed(
                AppRoutes.CREATETASKSCREEN,
                arguments: 'createNewEmployeeTask',
              );
            },
            label: Text(
              'edit'.tr,
              style: theme.copyWith(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 10.h,
              width: double.infinity,
            ),
            SupTextAndDis(
              title: 'employeeName',
              discription: arguments['employeeName'],
            ),
            SizedBox(height: 15.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'employeeImage'.tr,
                        style: theme.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: ThemeService.isDark.value
                              ? AppColors.customGreyColor6
                              : AppColors.customGreyColor4,
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Image.asset(
                        AssetsManger.rectangle,
                        height: 132.h,
                        width: 183.w,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'documentsImages'.tr,
                        style: theme.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: ThemeService.isDark.value
                              ? AppColors.customGreyColor6
                              : AppColors.customGreyColor4,
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Image.asset(
                        AssetsManger.rectangle,
                        height: 132.h,
                        width: 183.w,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            SupTextAndDis(
              title: 'email',
              discription: arguments['employeeName'],
            ),
            SizedBox(height: 10.h),
            SupTextAndDis(
              title: 'phoneNumber',
              discription: arguments['employeeName'],
            ),
            SizedBox(height: 10.h),
            SupTextAndDis(
              title: 'alternatePhone',
              discription: arguments['employeeName'],
            ),
            SizedBox(height: 10.h),
            SupTextAndDis(
              title: 'employeeJobTitle',
              discription: arguments['employeeName'],
            ),
            SizedBox(height: 10.h),
            SupTextAndDis(
              title: 'hourlyRate',
              discription: arguments['employeeName'],
            ),
            SizedBox(height: 10.h),
            SupTextAndDis(
              title: 'overTimeRate',
              discription: arguments['employeeName'],
            ),
            SizedBox(height: 10.h),
            SupTextAndDis(
              title: 'workHoursOfDay',
              discription: arguments['employeeName'],
            ),
            SizedBox(height: 10.h),
            SupTextAndDis(
              title: 'regularWorkingHours',
              discription: arguments['employeeName'],
            ),
            SizedBox(height: 10.h),
            SupTextAndDis(
              title: 'permissions',
              discription: arguments['employeeName'],
            ),
            SizedBox(height: 30.h),
            AppButton(text: 'saveChanges', onPressed: () => Get.back()),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }
}
