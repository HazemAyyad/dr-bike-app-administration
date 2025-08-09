import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../controllers/employee_section_controller.dart';

class AddNewEmployeeScreen extends GetView<EmployeeSectionController> {
  const AddNewEmployeeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context, title: 'addNewEmployee'.tr, action: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            CustomTextField(
              isRequired: true,
              label: 'employeeName'.tr,
              hintText: 'employeeNameExample'.tr,
              hintColor: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.customGreyColor6,
              controller: controller.employeeNameController,
            ),
            SizedBox(height: 10.h),
            CustomDropdownField(
              isRequired: true,
              label: 'employeeJobTitle'.tr,
              hint: 'employeeJobTitleExample'.tr,
              border: Border.all(
                color: AppColors.customGreyColor3,
              ),
              items: controller.jobTitles,
              onChanged: (value) {
                controller.employeeJobTitle = value!;
              },
            ),
            SizedBox(height: 10.h),
            CustomTextField(
              isRequired: true,
              label: 'hourlyRate'.tr,
              hintText: 'employeeSalaryExample'.tr,
              hintColor: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.customGreyColor6,
              controller: controller.hourlyRateController,
            ),
            SizedBox(height: 10.h),
            SizedBox(
              child: CustomTextField(
                isRequired: true,
                label: 'workHoursOfDayExample'.tr,
                hintText: 'workHoursExample'.tr,
                hintColor: ThemeService.isDark.value
                    ? AppColors.customGreyColor
                    : AppColors.customGreyColor6,
                controller: controller.overTimeRateController,
              ),
            ),
            SizedBox(height: 20.h),
            AppButton(
              text: 'addNewEmployee'.tr,
              textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
              height: 50.h,
              onPressed: controller.addNewEmployee,
            ),
          ],
        ),
      ),
    );
  }
}
