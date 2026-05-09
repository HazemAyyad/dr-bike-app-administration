import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/attendance_history_controller.dart';
import '../widgets/attendance_history_body.dart';

class EmployeeAttendanceHistoryScreen extends GetView<AttendanceHistoryController> {
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
              ? '${controller.employeeName} — ${'employeeAttendanceHistory'.tr}'
              : 'employeeAttendanceHistory'.tr,
          maxLines: 2,
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = controller.result.value;
        if (data == null || data.days.isEmpty) {
          return Center(child: Text('noData'.tr));
        }

        final head = data.employee;
        return AttendanceHistoryBody(employee: head, days: data.days);
      }),
    );
  }
}
