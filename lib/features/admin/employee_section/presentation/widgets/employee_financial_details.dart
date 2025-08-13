import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/employee_section_controller.dart';

class EmployeeFinancialDetails extends StatelessWidget {
  const EmployeeFinancialDetails({
    Key? key,
    required this.employee,
    required this.controller,
  }) : super(key: key);

  final Map<String, dynamic> employee;
  final EmployeeSectionController controller;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    double hoursFromPoints = (int.parse(employee['points']) / 50) *
        int.parse(employee['hourlyRate']);
    double total = (int.parse(employee['workHoursOfDay']) *
            int.parse(employee['hourlyRate'])) +
        hoursFromPoints -
        int.parse(employee['debts']);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darckColor
          : AppColors.whiteColor,
      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
      // insetPadding: EdgeInsets.symmetric(vertical: 120.h, horizontal: 30.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15.r)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 10.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        Icons.print_outlined,
                        color: AppColors.primaryColor,
                        size: 30.sp,
                      ),
                    ),
                    Text(
                      'financialDetails'.tr,
                      style: textStyle.copyWith(
                        color: ThemeService.isDark.value
                            ? AppColors.primaryColor
                            : AppColors.secondaryColor,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        Icons.close,
                        color: AppColors.primaryColor,
                        size: 30.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Flexible(
                    child: CustomTextField(
                      label: 'employeeName'.tr,
                      labelTextstyle: textStyle.copyWith(
                        color: AppColors.primaryColor,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      hintText: employee['employeeName'],
                      hintStyle: textStyle.copyWith(
                        color: Colors.grey,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      enabled: false,
                      sizedBox: false,
                      fillColor: ThemeService.isDark.value
                          ? AppColors.darckColor
                          : AppColors.whiteColor,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Flexible(
                    child: CustomDropdownField(
                      label: 'selectMonth',
                      labelTextStyle: textStyle.copyWith(
                        color: AppColors.primaryColor,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      hint: employee['warkDay'],
                      items: controller.daysList,
                      onChanged: (value) {},
                    ),
                  )
                ],
              ),
              SizedBox(height: 5.h),
              Row(
                children: [
                  Flexible(
                    child: CustomTextField(
                      label: 'debtValue'.tr,
                      labelTextstyle: textStyle.copyWith(
                        color: AppColors.primaryColor,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      hintText: '${employee['debts']} ${'currency'.tr}',
                      hintStyle: textStyle.copyWith(
                        color: Colors.grey,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      enabled: false,
                      sizedBox: false,
                      fillColor: ThemeService.isDark.value
                          ? AppColors.darckColor
                          : AppColors.whiteColor,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Flexible(
                    child: CustomTextField(
                      labelTextstyle: textStyle.copyWith(
                        color: AppColors.primaryColor,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      label: 'salary'.tr,
                      hintText: '${employee['salary']} ${'currency'.tr}',
                      hintStyle: textStyle.copyWith(
                        color: Colors.grey,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      enabled: false,
                      sizedBox: false,
                      fillColor: ThemeService.isDark.value
                          ? AppColors.darckColor
                          : AppColors.whiteColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.h),
              Row(
                children: [
                  Flexible(
                    child: CustomTextField(
                      labelTextstyle: textStyle.copyWith(
                        color: AppColors.primaryColor,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      label: 'points'.tr,
                      hintText: '${employee['points']} ${'point'.tr}',
                      hintStyle: textStyle.copyWith(
                        color: Colors.grey,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      enabled: false,
                      sizedBox: false,
                      fillColor: ThemeService.isDark.value
                          ? AppColors.darckColor
                          : AppColors.whiteColor,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Flexible(
                    child: CustomTextField(
                      labelTextstyle: textStyle.copyWith(
                        color: AppColors.primaryColor,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      label: 'hourlyRate'.tr,
                      hintText: '${employee['hourlyRate']} ${'currency'.tr}',
                      hintStyle: textStyle.copyWith(
                        color: Colors.grey,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      enabled: false,
                      sizedBox: false,
                      fillColor: ThemeService.isDark.value
                          ? AppColors.darckColor
                          : AppColors.whiteColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.h),
              Row(
                children: [
                  Flexible(
                    child: CustomTextField(
                      labelTextstyle: textStyle.copyWith(
                        color: AppColors.primaryColor,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      label: 'workHoursOfDay'.tr,
                      hintText: '${employee['workHoursOfDay']} ${'hours'.tr}',
                      hintStyle: textStyle.copyWith(
                        color: Colors.grey,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      enabled: false,
                      sizedBox: false,
                      fillColor: ThemeService.isDark.value
                          ? AppColors.darckColor
                          : AppColors.whiteColor,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Flexible(
                    child: CustomTextField(
                      labelTextstyle: textStyle.copyWith(
                        color: AppColors.primaryColor,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      label: 'total'.tr,
                      hintText: '$total ${'currency'.tr}',
                      hintStyle: textStyle.copyWith(
                        color: Colors.grey,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      enabled: false,
                      sizedBox: false,
                      fillColor: ThemeService.isDark.value
                          ? AppColors.darckColor
                          : AppColors.whiteColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.h),
              Form(
                key: controller.formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      labelTextstyle: textStyle.copyWith(
                        color: Colors.green,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      label: 'paySalary',
                      hintText: 'salary',
                      hintStyle: textStyle.copyWith(
                        color: Colors.grey,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      controller: controller.paySalaryController,
                    ),
                    SizedBox(height: 10.h),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      child: AppButton(
                        isLoading: controller.isLoading,
                        text: 'apply',
                        onPressed: () => controller.isLoading.value
                            ? null
                            : controller.paySalaryToEmployee(context, '9'),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
