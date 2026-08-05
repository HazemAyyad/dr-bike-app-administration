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

  String get _statusLabel {
    switch (employee.orderStatus) {
      case 'approved':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      case 'pending':
        return 'قيد الانتظار';
      default:
        return employee.orderStatus;
    }
  }

  String get _requestDetailsText {
    if (isOvertime == true) {
      final overtime = employee.overtimeValue ?? '';
      final extraHours = employee.extraWorkHoursValue ?? '';
      final hours = overtime.isNotEmpty ? overtime : extraHours;
      final title =
          overtime.isNotEmpty ? 'overtimeValue'.tr : 'numberOfHours'.tr;
      final unit = (int.tryParse(hours) ?? 0) > 10 ? 'hour'.tr : 'hours'.tr;
      return '$title : $hours $unit';
    }

    return '${'debtValue'.tr} : ${employee.loanValue ?? ''} ${'currency'.tr}';
  }

  CustomTextField _readOnlyField({
    required TextStyle textStyle,
    required String label,
    required String value,
  }) {
    return CustomTextField(
      label: label,
      labelTextstyle: textStyle.copyWith(
        color: AppColors.primaryColor,
        fontSize: 17.sp,
        fontWeight: FontWeight.w700,
      ),
      hintText: value,
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
      validator: (value) => null,
    );
  }

  Widget _reviewSummary(TextStyle textStyle) {
    final approvedAmount = employee.approvedLoanValue ?? employee.loanValue;
    return Column(
      children: [
        _readOnlyField(
          textStyle: textStyle,
          label: 'حالة الطلب',
          value: _statusLabel,
        ),
        if (!isOvertime! && employee.orderStatus == 'approved')
          _readOnlyField(
            textStyle: textStyle,
            label: 'قيمة السلفة المعتمدة',
            value: '${approvedAmount ?? ''} ${'currency'.tr}',
          ),
        if (employee.orderStatus == 'rejected')
          _readOnlyField(
            textStyle: textStyle,
            label: 'سبب الرفض',
            value: employee.rejectionReason ?? 'لم يتم توضيح السبب',
          ),
        if (employee.reviewedAt != null)
          _readOnlyField(
            textStyle: textStyle,
            label: 'تاريخ المراجعة',
            value: employee.reviewedAt!,
          ),
      ],
    );
  }

  Widget _reviewControls(TextStyle textStyle, BuildContext context) {
    String boxName(Map<String, dynamic> box) =>
        (box['box_name'] ?? box['name'] ?? '').toString();
    String boxBalance(Map<String, dynamic> box) =>
        (box['total_balance'] ?? box['total'] ?? '0').toString();

    return Column(
      children: [
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
                            controller: controller.extraWorkHoursController,
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
                            controller: controller.overtimeValueController,
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
                onChanged: (value) {
                  controller.setOnlyOneTrue('loanValue');
                  controller.loadLoanApprovalBoxes();
                },
              )
            : const SizedBox.shrink(),
        Obx(
          () => controller.loanValue.value
              ? Column(
                  children: [
                    CustomTextField(
                      label: '',
                      labelTextstyle: textStyle.copyWith(
                        color: AppColors.primaryColor,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      hintText: 'debtValue',
                      controller: controller.loanValueController,
                    ),
                    SizedBox(height: 10.h),
                    Obx(() {
                      if (controller.isLoanApprovalBoxesLoading.value) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: const CircularProgressIndicator(),
                        );
                      }
                      return DropdownButtonFormField<Map<String, dynamic>>(
                        initialValue: controller.selectedLoanApprovalBox.value,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'صندوق الصرف',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        items: controller.loanApprovalBoxes
                            .map(
                              (box) => DropdownMenuItem(
                                value: box,
                                child: Text(
                                  '${boxName(box)} - ${boxBalance(box)}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            controller.selectedLoanApprovalBox.value = value,
                        validator: (_) =>
                            controller.selectedLoanApprovalBoxId == null
                                ? 'يرجى اختيار صندوق صرف السلفة'
                                : null,
                      );
                    }),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        Obx(
          () => controller.rejectOrder.value
              ? CustomTextField(
                  label: '',
                  labelTextstyle: textStyle.copyWith(
                    color: AppColors.primaryColor,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  hintText: 'سبب الرفض',
                  controller: controller.rejectionReasonController,
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
          onChanged: (value) => controller.setOnlyOneTrue('rejectOrder'),
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
        ),
      ],
    );
  }

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
                _readOnlyField(
                  textStyle: textStyle,
                  label: 'employeeName',
                  value: employee.employeeName,
                ),
                _readOnlyField(
                  textStyle: textStyle,
                  label: 'requestDetails',
                  value: _requestDetailsText,
                ),
                _readOnlyField(
                  textStyle: textStyle,
                  label: 'orderDate',
                  value: showData(employee.orderDate),
                ),
                employee.canReview
                    ? _reviewControls(textStyle, context)
                    : _reviewSummary(textStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
