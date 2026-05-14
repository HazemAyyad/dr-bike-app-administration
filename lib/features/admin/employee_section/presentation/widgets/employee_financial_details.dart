import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/financial_details_model.dart';
import '../controllers/employee_section_controller.dart';

/// Lightweight financial summary for a selected calendar day (API day view).
class EmployeeFinancialDetails extends StatelessWidget {
  const EmployeeFinancialDetails({Key? key, required this.controller})
      : super(key: key);

  final EmployeeSectionController controller;

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
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15.r)),
        child: Obx(() {
          final employee = controller.financialDetailsList.value;
          if (employee == null || controller.isDialogLoading.value) {
            return const Padding(
              padding: EdgeInsets.all(36),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => controller.downloadReport(
                          type: 'financial',
                          context: context,
                          employeeId: employee.employeeId.toString(),
                          employeeName: employee.employeeName,
                        ),
                        icon: Icon(
                          Icons.print_outlined,
                          color: AppColors.primaryColor,
                          size: 28.sp,
                        ),
                      ),
                      Text(
                        'financialDetails'.tr,
                        style: textStyle.copyWith(
                          color: ThemeService.isDark.value
                              ? AppColors.primaryColor
                              : AppColors.secondaryColor,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: Icon(
                          Icons.close,
                          color: AppColors.primaryColor,
                          size: 28.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  employee.employeeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.sp,
                  ),
                ),
                SizedBox(height: 10.h),
                _DaySelectorBar(controller: controller, textStyle: textStyle),
                SizedBox(height: 12.h),
                Text(
                  employee.selectedMonth,
                  textAlign: TextAlign.center,
                  style: textStyle.copyWith(
                    fontSize: 13.sp,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),
                _SummarySection(employee: employee, textStyle: textStyle),
                SizedBox(height: 12.h),
                _PaymentForm(controller: controller, employee: employee),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _DaySelectorBar extends StatelessWidget {
  const _DaySelectorBar({
    required this.controller,
    required this.textStyle,
  });

  final EmployeeSectionController controller;
  final TextStyle textStyle;

  Future<void> _pickDate(BuildContext context) async {
    final current = controller.selectedFinancialDate.value;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      locale: Get.locale,
    );
    if (picked != null) {
      controller.setFinancialDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final d = controller.selectedFinancialDate.value;
      final label =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

      return Row(
        children: [
          IconButton(
            tooltip: 'previousDay'.tr,
            onPressed: () => controller.shiftFinancialDay(-1),
            icon: Icon(
              Icons.chevron_left_rounded,
              color: AppColors.primaryColor,
              size: 28.sp,
            ),
          ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _pickDate(context),
                borderRadius: BorderRadius.circular(8.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                  child: Column(
                    children: [
                      Text(
                        'selectDay'.tr,
                        style: textStyle.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 18.sp, color: AppColors.secondaryColor),
                          SizedBox(width: 6.w),
                          Text(
                            label,
                            style: textStyle.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'tapToPickDate'.tr,
                        style: textStyle.copyWith(
                          fontSize: 11.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'nextDay'.tr,
            onPressed: () => controller.shiftFinancialDay(1),
            icon: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primaryColor,
              size: 28.sp,
            ),
          ),
        ],
      );
    });
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.employee,
    required this.textStyle,
  });

  final FinancialDetailsModel employee;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final subtle = isDark ? Colors.white70 : Colors.grey.shade700;

    Widget line(String label, String value, {bool emphasize = false}) {
      return Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Text(
                label,
                style: textStyle.copyWith(
                  fontSize: 13.sp,
                  color: subtle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: textStyle.copyWith(
                  fontSize: emphasize ? 15.sp : 13.sp,
                  fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
                  color: emphasize
                      ? AppColors.primaryColor
                      : (isDark ? Colors.white : const Color(0xFF111827)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        line('attendanceDays'.tr, employee.attendanceDays),
        line('absentDays'.tr, employee.absentDays),
        line(
          'lateDays'.tr,
          '${employee.lateDays} · ${employee.delayHours} ${'hours'.tr}',
        ),
        line(
          'overtime'.tr,
          '${employee.overtimeHours} ${'hours'.tr} · ${employee.overtimeSalary} ${'currency'.tr}',
        ),
        line('bonuses'.tr, '${employee.bonuses} ${'currency'.tr}'),
        if (employee.view == 'month')
          line('deductions'.tr, '${employee.deductions} ${'currency'.tr}'),
        Divider(height: 16.h),
        line(
          'finalNetEntitlement'.tr,
          '${employee.finalNetEntitlement} ${'currency'.tr}',
          emphasize: true,
        ),
      ],
    );
  }
}

class _PaymentForm extends StatelessWidget {
  const _PaymentForm({required this.controller, required this.employee});

  final EmployeeSectionController controller;
  final FinancialDetailsModel employee;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    return Form(
      key: controller.formKey,
      child: Column(
        children: [
          CustomTextField(
            labelTextstyle: textStyle.copyWith(
              color: Colors.green,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
            label: 'paySalary',
            hintText: 'salary',
            hintStyle: textStyle.copyWith(
              color: Colors.grey,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
            controller: controller.paySalaryController,
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: AppButton(
              isLoading: controller.isLoading,
              text: 'apply',
              onPressed: () => controller.isLoading.value
                  ? null
                  : controller.paySalaryToEmployee(
                      context,
                      employee.employeeId.toString(),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
