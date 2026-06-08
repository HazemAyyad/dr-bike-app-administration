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
    final isDark = ThemeService.isDark.value;
    final pageBg =
        isDark ? AppColors.darkColor : const Color(0xFFF5F5F5);
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          controller.employeeName.isNotEmpty
              ? controller.employeeName
              : 'employeeAttendanceHistory'.tr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      floatingActionButton: Obx(() {
        if (!controller.canManualCheckoutToday) {
          return const SizedBox.shrink();
        }
        final loading = controller.isCheckoutLoading.value;
        return FloatingActionButton.extended(
          onPressed: loading
              ? null
              : () async {
                  final ok = await Get.dialog<bool>(
                    AlertDialog(
                      title: Text('manualCheckout'.tr),
                      content: Text('manualCheckoutConfirm'.tr),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(result: false),
                          child: Text('cancel'.tr),
                        ),
                        TextButton(
                          onPressed: () => Get.back(result: true),
                          child: Text('confirm'.tr),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await controller.manualCheckout();
                  }
                },
          icon: loading
              ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout),
          label: Text('manualCheckout'.tr),
        );
      }),
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
              if (data == null) {
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
              final hasContent = data.days.isNotEmpty ||
                  data.monthlySummary != null ||
                  controller.isViewingCurrentMonth;
              if (!hasContent) {
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
                showTodaySummary: controller.isViewingCurrentMonth,
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
    final isDark = ThemeService.isDark.value;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
            width: 1,
          ),
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
            SizedBox(width: 8.w),
            // ── الشهر ──
            Expanded(
              flex: 2,
              child: _PickerButton(
                label: AttendanceHistoryController.monthNames[month - 1],
                icon: Icons.date_range_outlined,
                onTap: () => _pickMonth(context, year),
              ),
            ),
            SizedBox(width: 8.w),
            // ── زر التحديث ──
            SizedBox(
              width: 42.w,
              child: IconButton(
              onPressed: controller.load,
              icon: const Icon(Icons.refresh),
              color: AppColors.primaryColor,
              tooltip: 'refresh'.tr,
            ),
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
    final isDark = ThemeService.isDark.value;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade300, width: 1),
          borderRadius: BorderRadius.circular(8.r),
          color: isDark ? Colors.white10 : Colors.grey.shade50,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16.sp, color: AppColors.primaryColor),
            SizedBox(width: 6.w),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF222222),
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
