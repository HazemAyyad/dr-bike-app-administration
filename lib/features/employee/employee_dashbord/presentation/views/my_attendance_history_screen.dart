import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../admin/employee_section/presentation/widgets/attendance_history_body.dart';
import '../controllers/my_attendance_history_controller.dart';

class MyAttendanceHistoryScreen extends GetView<MyAttendanceHistoryController> {
  const MyAttendanceHistoryScreen({Key? key}) : super(key: key);

  bool _rangeIncludesToday(MyAttendanceHistoryController c) {
    final now = DateTime.now();
    final from = DateTime(c.fromDate.year, c.fromDate.month, c.fromDate.day);
    final to = DateTime(
      c.toDate.year,
      c.toDate.month,
      c.toDate.day,
      23,
      59,
      59,
    );
    return !now.isBefore(from) && !now.isAfter(to);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      appBar: AppBar(
        title: Text('myAttendanceRecord'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => controller.pickDateRange(context),
            tooltip: 'selectDateRange'.tr,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = controller.result.value;
        if (data == null) {
          return Center(child: Text('noData'.tr));
        }
        final includesToday = _rangeIncludesToday(controller);
        final hasContent = data.days.isNotEmpty ||
            data.monthlySummary != null ||
            includesToday;
        if (!hasContent) {
          return Center(child: Text('noData'.tr));
        }
        return AttendanceHistoryBody(
          employee: data.employee,
          monthlySummary: data.monthlySummary,
          days: data.days,
          showTodaySummary: includesToday,
          headerExtra: Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Text(
              MyAttendanceHistoryController.formatRange(
                controller.fromDate,
                controller.toDate,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      }),
    );
  }
}
