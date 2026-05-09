import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../admin/employee_section/presentation/widgets/attendance_history_body.dart';
import '../controllers/my_attendance_history_controller.dart';

class MyAttendanceHistoryScreen extends GetView<MyAttendanceHistoryController> {
  const MyAttendanceHistoryScreen({Key? key}) : super(key: key);

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
        if (data == null || data.days.isEmpty) {
          return Center(child: Text('noData'.tr));
        }
        return AttendanceHistoryBody(
          employee: data.employee,
          days: data.days,
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
