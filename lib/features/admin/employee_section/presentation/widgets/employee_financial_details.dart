import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/helpers/month_year_picker.dart';
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
                  padding: EdgeInsets.only(top: 10.w),
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
                _MonthBar(controller: controller, textStyle: textStyle),
                SizedBox(height: 5.h),
                _InfoRows(employee: employee, textStyle: textStyle),
                SizedBox(height: 8.h),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => _showAdvancesSheet(context),
                    icon: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.primaryColor,
                    ),
                    label: Text('advances'.tr),
                  ),
                ),
                _PaymentForm(controller: controller, employee: employee),
              ],
            ),
          );
        }),
      ),
    );
  }

  void _showAdvancesSheet(BuildContext context) {
    controller.loadEmployeeAdvances();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Obx(() {
        final isDark = ThemeService.isDark.value;
        final result = controller.employeeAdvances.value;
        final advances = result?.advances ?? const [];

        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.72,
            ),
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.customGreyColor : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${'advances'.tr} - ${controller.formatMonthLabel(controller.selectedFinancialMonth.value)}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                if (controller.isAdvancesLoading.value)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (controller.advancesError.value.isNotEmpty)
                  Expanded(
                    child: Center(child: Text(controller.advancesError.value)),
                  )
                else if (advances.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 42.sp,
                            color: AppColors.primaryColor,
                          ),
                          SizedBox(height: 8.h),
                          Text('noAdvancesForMonth'.tr),
                        ],
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      itemCount: advances.length,
                      separatorBuilder: (_, __) => Divider(height: 1.h),
                      itemBuilder: (_, index) {
                        final advance = advances[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primaryColor.withValues(alpha: 0.12),
                            child: Icon(
                              Icons.payments_outlined,
                              color: AppColors.primaryColor,
                              size: 20.sp,
                            ),
                          ),
                          title: Text(
                            '${advance.amount} ${'currency'.tr}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            '${advance.day} - ${advance.date} - ${advance.time}',
                          ),
                          trailing: Text(
                            advance.status,
                            style: const TextStyle(
                              color: AppColors.secondaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                Divider(height: 18.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'totalAdvances'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      '${result?.total ?? '0'} ${'currency'.tr}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({required this.controller, required this.textStyle});

  final EmployeeSectionController controller;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final month = controller.selectedFinancialMonth.value;
      return Row(
        children: [
          IconButton(
            tooltip: 'previousMonth'.tr,
            onPressed: () => controller.changeFinancialMonth(-1),
            icon: Icon(
              Icons.chevron_left_rounded,
              color: AppColors.primaryColor,
              size: 28.sp,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final pickedMonth = await MonthYearPicker.pickMonth(
                  context,
                  selected: month.month,
                );
                if (pickedMonth == null) return;
                final pickerContext = Get.context;
                if (pickerContext == null) return;
                final pickedYear = await MonthYearPicker.pickYear(
                  // ignore: use_build_context_synchronously
                  pickerContext,
                  selected: month.year,
                );
                controller.setFinancialMonth(
                  DateTime(pickedYear ?? month.year, pickedMonth, 1),
                );
              },
              child: CustomTextField(
                label: 'selectMonth'.tr,
                labelTextstyle: textStyle.copyWith(
                  color: AppColors.primaryColor,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                ),
                hintText:
                    '${MonthYearPicker.monthLabel(month.month)} ${month.year}',
                hintStyle: textStyle.copyWith(
                  color: Colors.grey,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
                enabled: false,
                sizedBox: false,
                fillColor: ThemeService.isDark.value
                    ? AppColors.darkColor
                    : AppColors.whiteColor,
              ),
            ),
          ),
          IconButton(
            tooltip: 'nextMonth'.tr,
            onPressed: () => controller.changeFinancialMonth(1),
            icon: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primaryColor,
              size: 28.sp,
            ),
          ),
          TextButton(
            onPressed: controller.setCurrentFinancialMonth,
            child: Text('currentMonth'.tr),
          ),
        ],
      );
    });
  }
}

class _InfoRows extends StatelessWidget {
  const _InfoRows({required this.employee, required this.textStyle});

  final FinancialDetailsModel employee;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _fieldRow(
          _field('employeeName'.tr, employee.employeeName),
          _field('selectedMonth'.tr, employee.selectedMonth),
        ),
        _fieldRow(
          _field('baseSalary'.tr, '${employee.baseSalary} ${'currency'.tr}'),
          _field('salary'.tr, '${employee.salary} ${'currency'.tr}'),
        ),
        _fieldRow(
          _field('attendanceDays'.tr, employee.attendanceDays),
          _field('absentDays'.tr, employee.absentDays),
        ),
        _fieldRow(
          _field('lateDays'.tr,
              '${employee.lateDays} / ${employee.delayHours} ${'hours'.tr}'),
          _field('overtime'.tr, '${employee.overtimeHours} ${'hours'.tr}'),
        ),
        _fieldRow(
          _field('deductions'.tr, '${employee.deductions} ${'currency'.tr}'),
          _field('bonuses'.tr, '${employee.bonuses} ${'currency'.tr}'),
        ),
        _fieldRow(
          _field('advances'.tr, '${employee.advances} ${'currency'.tr}'),
          _field('debtValue'.tr, '${employee.debts} ${'currency'.tr}'),
        ),
        _fieldRow(
          _field('hourlyRate'.tr, '${employee.hourWorkPrice} ${'currency'.tr}'),
          _field('workHoursOfDay'.tr,
              '${employee.numberOfWorkHours} ${'hours'.tr}'),
        ),
        _fieldRow(
          _field('points'.tr, '${employee.points} ${'point'.tr}'),
          _field('finalNetEntitlement'.tr,
              '${employee.finalNetEntitlement} ${'currency'.tr}'),
        ),
      ],
    );
  }

  Widget _fieldRow(Widget first, Widget second) {
    return Padding(
      padding: EdgeInsets.only(bottom: 5.h),
      child: Row(
        children: [
          Flexible(child: first),
          SizedBox(width: 10.w),
          Flexible(child: second),
        ],
      ),
    );
  }

  Widget _field(String label, String value) {
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
                  : controller.paySalaryToEmployee(
                      context,
                      employee.employeeId.toString(),
                    ),
            ),
          )
        ],
      ),
    );
  }
}
