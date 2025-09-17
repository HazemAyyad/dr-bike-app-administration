import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/financial_details_model.dart';
import '../controllers/employee_section_controller.dart';

class EmployeeFinancialDetails extends StatelessWidget {
  const EmployeeFinancialDetails({Key? key, required this.controller})
      : super(key: key);

  final EmployeeSectionController controller;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;

    FinancialDetailsModel employee = controller.financialDetailsList.value!;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
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
              CustomTextField(
                label: 'employeeName'.tr,
                labelTextstyle: textStyle.copyWith(
                  color: AppColors.primaryColor,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                ),
                hintText: employee.employeeName,
                hintStyle: textStyle.copyWith(
                  color: Colors.grey,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
                enabled: false,
                sizedBox: false,
                fillColor: ThemeService.isDark.value
                    ? AppColors.darkColor
                    : AppColors.whiteColor,
              ),
              // Row(
              //   children: [
              //     Flexible(
              //       child:
              //     ),
              //     SizedBox(width: 10.w),
              // Flexible(
              //   child: CustomDropdownField(
              //     label: 'selectMonth',
              //     labelTextStyle: textStyle.copyWith(
              //       color: AppColors.primaryColor,
              //       fontSize: 17.sp,
              //       fontWeight: FontWeight.w700,
              //     ),
              //     hint: 'employee',
              //     items: controller.daysList,
              //     onChanged: (value) {},
              //   ),
              // )
              // ],
              // ),
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
                      hintText: '${employee.debts} ${'currency'.tr}',
                      hintStyle: textStyle.copyWith(
                        color: Colors.grey,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      enabled: false,
                      sizedBox: false,
                      fillColor: ThemeService.isDark.value
                          ? AppColors.darkColor
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
                      hintText: '${employee.salary} ${'currency'.tr}',
                      hintStyle: textStyle.copyWith(
                        color: Colors.grey,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      enabled: false,
                      sizedBox: false,
                      fillColor: ThemeService.isDark.value
                          ? AppColors.darkColor
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
                      hintText: '${employee.points} ${'point'.tr}',
                      hintStyle: textStyle.copyWith(
                        color: Colors.grey,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      enabled: false,
                      sizedBox: false,
                      fillColor: ThemeService.isDark.value
                          ? AppColors.darkColor
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
                      hintText: '${employee.hourWorkPrice} ${'currency'.tr}',
                      hintStyle: textStyle.copyWith(
                        color: Colors.grey,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      enabled: false,
                      sizedBox: false,
                      fillColor: ThemeService.isDark.value
                          ? AppColors.darkColor
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
                      hintText: '${employee.numberOfWorkHours} ${'hours'.tr}',
                      hintStyle: textStyle.copyWith(
                        color: Colors.grey,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      enabled: false,
                      sizedBox: false,
                      fillColor: ThemeService.isDark.value
                          ? AppColors.darkColor
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
                      hintText: '${employee.total} ${'currency'.tr}',
                      hintStyle: textStyle.copyWith(
                        color: Colors.grey,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      enabled: false,
                      sizedBox: false,
                      fillColor: ThemeService.isDark.value
                          ? AppColors.darkColor
                          : AppColors.whiteColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.h),
              Column(
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
            ],
          ),
        ),
      ),
    );
  }
}
