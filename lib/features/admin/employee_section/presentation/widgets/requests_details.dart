import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/employee_section_controller.dart';

class RequestsDetails extends StatelessWidget {
  const RequestsDetails({
    Key? key,
    required this.employee,
    required this.controller,
    this.isOvertime = false,
  }) : super(key: key);

  final Map<String, dynamic> employee;
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
          ? AppColors.darckColor
          : AppColors.whiteColor,
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
                    SizedBox(),
                    SizedBox(),
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
              CustomTextField(
                label: 'requestDetails',
                labelTextstyle: textStyle.copyWith(
                  color: AppColors.primaryColor,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                ),
                hintText:
                    '${'debtValue'.tr} : ${employee['debts']} ${'currency'.tr}',
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
              CustomTextField(
                label: 'orderDate',
                labelTextstyle: textStyle.copyWith(
                  color: AppColors.primaryColor,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                ),
                hintText: employee['date'],
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
              isOvertime!
                  ? Column(
                      children: [
                        CustomCheckBox(
                          title: 'AddRegularWorkingHours',
                          shape: CircleBorder(),
                          style: textStyle.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                          value: controller.addRegularWorkingHours,
                          onChanged: (value) => controller
                              .setOnlyOneTrue('addRegularWorkingHours'),
                        ),
                        Obx(
                          () => controller.addRegularWorkingHours.value
                              ? CustomTextField(
                                  label: '',
                                  labelTextstyle: textStyle.copyWith(
                                    color: AppColors.primaryColor,
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  hintText: 'numberOfHours',
                                )
                              : SizedBox.shrink(),
                        ),
                        CustomCheckBox(
                          title: 'addOvertime',
                          shape: CircleBorder(),
                          style: textStyle.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                          value: controller.addWorkHours,
                          onChanged: (value) =>
                              controller.setOnlyOneTrue('addWorkHours'),
                        ),
                        Obx(
                          () => controller.addWorkHours.value
                              ? CustomTextField(
                                  label: '',
                                  labelTextstyle: textStyle.copyWith(
                                    color: AppColors.primaryColor,
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  hintText: 'numberOfHours',
                                )
                              : SizedBox.shrink(),
                        ),
                      ],
                    )
                  : SizedBox.shrink(),
              !isOvertime!
                  ? CustomCheckBox(
                      title: 'acceptOrder',
                      shape: CircleBorder(),
                      style: textStyle.copyWith(
                        color: Colors.green,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      value: controller.acceptOrder,
                      onChanged: (value) =>
                          controller.setOnlyOneTrue('acceptOrder'),
                    )
                  : SizedBox.shrink(),
              Obx(
                () => controller.acceptOrder.value
                    ? CustomTextField(
                        label: '',
                        labelTextstyle: textStyle.copyWith(
                          color: AppColors.primaryColor,
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        hintText: 'debtValue',
                      )
                    : SizedBox.shrink(),
              ),
              CustomCheckBox(
                title: 'rejectOrder',
                shape: CircleBorder(),
                style: textStyle.copyWith(
                  color: Colors.red,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
                value: controller.rejectOrder,
                onChanged: (value) => controller.setOnlyOneTrue('rejectOrder'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: AppButton(
                  text: 'apply',
                  onPressed: () {
                    Get.back();
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
