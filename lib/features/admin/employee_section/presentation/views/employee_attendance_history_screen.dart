import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/attendance_history_controller.dart';
import '../widgets/attendance_history_body.dart';

class EmployeeAttendanceHistoryScreen
    extends GetView<AttendanceHistoryController> {
  const EmployeeAttendanceHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      appBar: AppBar(
        title: Text(
          controller.employeeName.isNotEmpty
              ? controller.employeeName
              : 'employeeAttendanceHistory'.tr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          // ── منتقي السنة والشهر ──
          _MonthYearPicker(controller: controller),
          // ── المحتوى ──
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = controller.result.value;
              if (data == null || data.days.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy,
                          size: 64.sp, color: Colors.grey.shade400),
                      SizedBox(height: 12.h),
                      Text(
                        'noData'.tr,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              final head = data.employee;
              return AttendanceHistoryBody(
                employee: head,
                monthlySummary: data.monthlySummary,
                days: data.days,
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// ودجة منتقي السنة والشهر
// ────────────────────────────────────────────────────────────────
class _MonthYearPicker extends StatelessWidget {
  const _MonthYearPicker({required this.controller});
  final AttendanceHistoryController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(
              color: AppColors.primaryColor.withValues(alpha: 0.15), width: 1),
        ),
      ),
      child: Obx(() {
        final year  = controller.selectedYear.value;
        final month = controller.selectedMonth.value;

        return Row(
          children: [
            // ── السنة ──
            Expanded(
              child: _PickerButton(
                label: year.toString(),
                icon: Icons.calendar_today_outlined,
                onTap: () => _pickYear(context),
              ),
            ),
            SizedBox(width: 10.w),
            // ── الشهر ──
            Expanded(
              flex: 2,
              child: _PickerButton(
                label: AttendanceHistoryController.monthNames[month - 1],
                icon: Icons.date_range_outlined,
                onTap: () => _pickMonth(context, year),
              ),
            ),
            SizedBox(width: 10.w),
            // ── زر التحديث ──
            IconButton(
              onPressed: controller.load,
              icon: const Icon(Icons.refresh),
              color: AppColors.primaryColor,
              tooltip: 'refresh'.tr,
            ),
          ],
        );
      }),
    );
  }

  void _pickYear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('اختر السنة'),
        children: controller.availableYears.map((y) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              controller.changeMonth(y, controller.selectedMonth.value);
            },
            child: Text(
              y.toString(),
              style: TextStyle(
                fontWeight: controller.selectedYear.value == y
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: controller.selectedYear.value == y
                    ? AppColors.primaryColor
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _pickMonth(BuildContext context, int year) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text('اختر الشهر — $year'),
        children: List.generate(12, (i) {
          final m = i + 1;
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              controller.changeMonth(year, m);
            },
            child: Text(
              AttendanceHistoryController.monthNames[i],
              style: TextStyle(
                fontWeight: controller.selectedMonth.value == m
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: controller.selectedMonth.value == m
                    ? AppColors.primaryColor
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.4), width: 1),
          borderRadius: BorderRadius.circular(8.r),
          color: AppColors.primaryColor.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16.sp, color: AppColors.primaryColor),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.arrow_drop_down,
                size: 18.sp, color: AppColors.primaryColor),
          ],
        ),
      ),
    );
  }
}
