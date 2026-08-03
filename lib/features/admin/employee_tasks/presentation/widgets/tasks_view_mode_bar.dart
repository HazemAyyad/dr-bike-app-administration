import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/employee_tasks_controller.dart';

class TasksViewModeBar extends GetView<EmployeeTasksController> {
  const TasksViewModeBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final mode = controller.tasksViewMode.value;
      controller.listEpoch.value;
      return Container(
        margin: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 4.h),
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor
              : AppColors.whiteColor2,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: ThemeService.isDark.value
                ? Colors.white10
                : AppColors.operationalCardBorder,
          ),
        ),
        child: Row(
          children: [
            _navButton(
              icon: Icons.chevron_right_rounded,
              onTap: () => controller.changePeriod(false),
            ),
            SizedBox(width: 2.w),
            _modeButton(
              icon: Icons.today_outlined,
              label: 'tasksViewDaily'.tr,
              selected: mode == EmployeeTasksController.tasksViewDaily,
              onTap: () => controller
                  .setTasksViewMode(EmployeeTasksController.tasksViewDaily),
            ),
            _modeButton(
              icon: Icons.view_week_outlined,
              label: 'tasksViewWeekly'.tr,
              selected: mode == EmployeeTasksController.tasksViewWeekly,
              onTap: () => controller
                  .setTasksViewMode(EmployeeTasksController.tasksViewWeekly),
            ),
            _modeButton(
              icon: Icons.calendar_month_outlined,
              label: 'tasksViewMonthly'.tr,
              selected: mode == EmployeeTasksController.tasksViewMonthly,
              onTap: () => controller
                  .setTasksViewMode(EmployeeTasksController.tasksViewMonthly),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                controller.compactPeriodLabel,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: ThemeService.isDark.value
                          ? AppColors.primaryColor
                          : AppColors.operationalNavy,
                    ),
              ),
            ),
            SizedBox(width: 2.w),
            _navButton(
              icon: Icons.chevron_left_rounded,
              onTap: () => controller.changePeriod(true),
            ),
          ],
        ),
      );
    });
  }

  Widget _modeButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final fg = selected
        ? Colors.white
        : ThemeService.isDark.value
            ? Colors.white70
            : AppColors.operationalNavy;

    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(8.r),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 34.w,
          height: 32.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.operationalPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 18.sp, color: fg),
        ),
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8.r),
      onTap: onTap,
      child: SizedBox(
        width: 30.w,
        height: 32.h,
        child: Icon(
          icon,
          color: AppColors.operationalPurple,
          size: 22.sp,
        ),
      ),
    );
  }
}
