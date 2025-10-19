import 'package:doctorbike/core/helpers/showtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/overtime_and_loan_model.dart';
import '../controllers/employee_section_controller.dart';

class RequestsDetails extends StatelessWidget {
  const RequestsDetails({
    Key? key,
    required this.employee,
    required this.controller,
    this.isOvertime = false,
  }) : super(key: key);

  final OvertimeAndLoanModel employee;
  final EmployeeSectionController controller;
  final bool? isOvertime;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15.r)),
        child: SingleChildScrollView(
          child: Form(
            key: controller.formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 10.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(),
                      const SizedBox(),
                      Text(
                        'requestDetails'.tr,
                        style: textStyle.copyWith(
                          color: ThemeService.isDark.value
                              ? AppColors.primaryColor
                              : AppColors.secondaryColor,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
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
                  label: 'employeeName',
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
                  validator: (value) {
                    return null;
                  },
                ),
                CustomTextField(
                  label: 'requestDetails',
                  labelTextstyle: textStyle.copyWith(
                    color: AppColors.primaryColor,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  hintText: isOvertime!
                      ? employee.overtimeValue!.isEmpty
                          ? '${'overtimeValue'.tr} : ${employee.extraWorkHoursValue ?? ''} '
                              '${(int.tryParse(employee.extraWorkHoursValue ?? '0') ?? 0) > 10 ? 'hour'.tr : 'hours'.tr}'
                          : '${'overtimeValue'.tr} : ${employee.overtimeValue ?? ''} '
                              '${(int.tryParse(employee.overtimeValue ?? '0') ?? 0) > 10 ? 'hour'.tr : 'hours'.tr}'
                      : '${'debtValue'.tr} : ${employee.loanValue} ${'currency'.tr}',
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
                  validator: (value) {
                    return null;
                  },
                ),
                CustomTextField(
                  label: 'orderDate',
                  hintStyle: textStyle.copyWith(
                    color: Colors.grey,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  hintText: showData(employee.orderDate),
                  labelTextstyle: textStyle.copyWith(
                    color: AppColors.primaryColor,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  enabled: false,
                  sizedBox: false,
                  fillColor: ThemeService.isDark.value
                      ? AppColors.darkColor
                      : AppColors.whiteColor,
                  validator: (value) {
                    return null;
                  },
                ),
                isOvertime!
                    ? Column(
                        children: [
                          CustomCheckBox(
                            title: 'AddRegularWorkingHours',
                            shape: const CircleBorder(),
                            style: textStyle.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                            ),
                            value: controller.extraWorkHours,
                            onChanged: (value) =>
                                controller.setOnlyOneTrue('extraWorkHours'),
                          ),
                          Obx(
                            () => controller.extraWorkHours.value
                                ? CustomTextField(
                                    label: '',
                                    labelTextstyle: textStyle.copyWith(
                                      color: AppColors.primaryColor,
                                      fontSize: 17.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    hintText: 'numberOfHours',
                                    controller:
                                        controller.extraWorkHoursController,
                                  )
                                : const SizedBox.shrink(),
                          ),
                          CustomCheckBox(
                            title: 'addOvertime',
                            shape: const CircleBorder(),
                            style: textStyle.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                            ),
                            value: controller.overtimeValue,
                            onChanged: (value) =>
                                controller.setOnlyOneTrue('overtimeValue'),
                          ),
                          Obx(
                            () => controller.overtimeValue.value
                                ? CustomTextField(
                                    label: '',
                                    labelTextstyle: textStyle.copyWith(
                                      color: AppColors.primaryColor,
                                      fontSize: 17.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    hintText: 'numberOfHours',
                                    controller:
                                        controller.overtimeValueController,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
                !isOvertime!
                    ? CustomCheckBox(
                        title: 'acceptOrder',
                        shape: const CircleBorder(),
                        style: textStyle.copyWith(
                          color: Colors.green,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        value: controller.loanValue,
                        onChanged: (value) =>
                            controller.setOnlyOneTrue('loanValue'),
                      )
                    : const SizedBox.shrink(),
                Obx(
                  () => controller.loanValue.value
                      ? CustomTextField(
                          label: '',
                          labelTextstyle: textStyle.copyWith(
                            color: AppColors.primaryColor,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                          ),
                          hintText: 'debtValue',
                          controller: controller.loanValueController,
                        )
                      : const SizedBox.shrink(),
                ),
                CustomCheckBox(
                  title: 'rejectOrder',
                  shape: const CircleBorder(),
                  style: textStyle.copyWith(
                    color: Colors.red,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  value: controller.rejectOrder,
                  onChanged: (value) =>
                      controller.setOnlyOneTrue('rejectOrder'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: AppButton(
                    isLoading: controller.isPaymentLoading,
                    text: 'apply',
                    onPressed: () {
                      if (controller.rejectOrder.value) {
                        return controller.rejectEmployeeOrder(
                          context,
                          employee.id.toString(),
                        );
                      } else if (controller.formKey.currentState!.validate()) {
                        return controller.approveEmployeeOrder(
                          context: context,
                          employeeOrderId: employee.id.toString(),
                        );
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
