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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 620.w,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Obx(() {
          final employee = controller.financialDetailsList.value;
          if (employee == null || controller.isDialogLoading.value) {
            return const Padding(
              padding: EdgeInsets.all(36),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Header(
                  controller: controller,
                  employee: employee,
                  textStyle: textStyle,
                ),
                SizedBox(height: 10.h),
                _MonthControls(controller: controller, textStyle: textStyle),
                SizedBox(height: 12.h),
                _SummaryGrid(employee: employee, textStyle: textStyle),
                SizedBox(height: 12.h),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => _showAdvancesSheet(context),
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: Text('advances'.tr),
                  ),
                ),
                SizedBox(height: 4.h),
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

class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.employee,
    required this.textStyle,
  });

  final EmployeeSectionController controller;
  final FinancialDetailsModel employee;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'print'.tr,
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
        Expanded(
          child: Text(
            'financialDetails'.tr,
            textAlign: TextAlign.center,
            style: textStyle.copyWith(
              color: ThemeService.isDark.value
                  ? AppColors.primaryColor
                  : AppColors.secondaryColor,
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
            ),
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
    );
  }
}

class _MonthControls extends StatelessWidget {
  const _MonthControls({required this.controller, required this.textStyle});

  final EmployeeSectionController controller;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final month = controller.selectedFinancialMonth.value;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'previousMonth'.tr,
              onPressed: () => controller.changeFinancialMonth(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8.r),
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
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Text(
                    '${MonthYearPicker.monthLabel(month.month)} ${month.year}',
                    textAlign: TextAlign.center,
                    style: textStyle.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'nextMonth'.tr,
              onPressed: () => controller.changeFinancialMonth(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
            TextButton(
              onPressed: controller.setCurrentFinancialMonth,
              child: Text('currentMonth'.tr),
            ),
          ],
        ),
      );
    });
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.employee, required this.textStyle});

  final FinancialDetailsModel employee;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _SummaryItem(
          'employeeName'.tr, employee.employeeName, Icons.person_outline),
      _SummaryItem(
          'selectedMonth'.tr, employee.selectedMonth, Icons.calendar_month),
      _SummaryItem('baseSalary'.tr, '${employee.baseSalary} ${'currency'.tr}',
          Icons.badge_outlined),
      _SummaryItem('attendanceDays'.tr, employee.attendanceDays,
          Icons.event_available_outlined),
      _SummaryItem(
          'absentDays'.tr, employee.absentDays, Icons.event_busy_outlined),
      _SummaryItem(
        'lateDays'.tr,
        '${employee.lateDays} / ${employee.delayHours} ${'hours'.tr}',
        Icons.schedule_outlined,
      ),
      _SummaryItem('overtime'.tr, '${employee.overtimeHours} ${'hours'.tr}',
          Icons.more_time_outlined),
      _SummaryItem('deductions'.tr, '${employee.deductions} ${'currency'.tr}',
          Icons.remove_circle_outline),
      _SummaryItem('bonuses'.tr, '${employee.bonuses} ${'currency'.tr}',
          Icons.add_circle_outline),
      _SummaryItem(
        'advances'.tr,
        '${employee.advances} ${'currency'.tr}',
        Icons.account_balance_wallet_outlined,
      ),
      _SummaryItem(
        'finalNetEntitlement'.tr,
        '${employee.finalNetEntitlement} ${'currency'.tr}',
        Icons.payments_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 520 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rows.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 72.h,
            crossAxisSpacing: 8.w,
            mainAxisSpacing: 8.h,
          ),
          itemBuilder: (_, index) {
            final row = rows[index];
            final isFinal = row.title == 'finalNetEntitlement'.tr;
            return Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: isFinal
                      ? AppColors.primaryColor.withValues(alpha: 0.45)
                      : Colors.grey.withValues(alpha: 0.18),
                ),
                color: isFinal
                    ? AppColors.primaryColor.withValues(alpha: 0.08)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  Icon(row.icon, color: AppColors.primaryColor, size: 22.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          row.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyle.copyWith(
                            fontSize: 12.sp,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          row.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyle.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SummaryItem {
  const _SummaryItem(this.title, this.value, this.icon);

  final String title;
  final String value;
  final IconData icon;
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
