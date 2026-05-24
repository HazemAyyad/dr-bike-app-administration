import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../controllers/employee_tasks_controller.dart';

class TasksViewModeBar extends GetView<EmployeeTasksController> {
  const TasksViewModeBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final mode = controller.tasksViewMode.value;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        child: Row(
          children: [
            _chip(
              label: 'tasksViewDaily'.tr,
              selected: mode == EmployeeTasksController.tasksViewDaily,
              onTap: () => controller.setTasksViewMode(EmployeeTasksController.tasksViewDaily),
            ),
            SizedBox(width: 6.w),
            _chip(
              label: 'tasksViewWeekly'.tr,
              selected: mode == EmployeeTasksController.tasksViewWeekly,
              onTap: () => controller.setTasksViewMode(EmployeeTasksController.tasksViewWeekly),
            ),
            SizedBox(width: 6.w),
            _chip(
              label: 'tasksViewMonthly'.tr,
              selected: mode == EmployeeTasksController.tasksViewMonthly,
              onTap: () => controller.setTasksViewMode(EmployeeTasksController.tasksViewMonthly),
            ),
          ],
        ),
      );
    });
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 7.h),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.operationalPurple
                : AppColors.whiteColor,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: selected
                  ? AppColors.operationalPurple
                  : AppColors.operationalCardBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.operationalNavy,
            ),
          ),
        ),
      ),
    );
  }
}
