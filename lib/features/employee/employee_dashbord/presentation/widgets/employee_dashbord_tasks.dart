import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/dashbord_employee_details_model.dart';
import '../controllers/employee_dashbord_controller.dart';

/// Legacy export — uses operational card UI.
class EmployeeDashbordTasks extends GetView<EmployeeDashbordController> {
  const EmployeeDashbordTasks({Key? key, required this.task}) : super(key: key);

  final Task task;

  @override
  Widget build(BuildContext context) {
    final completed = task.status == 'completed';
    final repeated = task.taskRecurrence != 'noRepeat';
    final color = completed ? Colors.green : AppColors.operationalPurple;
    final time = DateFormat('h:mm a', Get.locale?.toString())
        .format(task.endTime.toLocal());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.openTaskDetails(task),
        child: Container(
          constraints: BoxConstraints(minHeight: 54.h),
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : Colors.white,
            border: const Border(
              bottom: BorderSide(color: AppColors.operationalCardBorder),
            ),
          ),
          child: Row(children: [
            Icon(
              completed
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: color,
              size: 23.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                task.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                  color: ThemeService.isDark.value
                      ? Colors.white
                      : AppColors.operationalNavy,
                ),
              ),
            ),
            SizedBox(width: 5.w),
            if (repeated)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: (task.taskRecurrence == 'daily'
                          ? Colors.green
                          : Colors.deepOrange)
                      .withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.sync_rounded,
                      size: 13.sp,
                      color: task.taskRecurrence == 'daily'
                          ? Colors.green
                          : Colors.deepOrange),
                  SizedBox(width: 2.w),
                  Text(
                    task.taskRecurrence == 'daily' ? 'يومية' : 'متكررة',
                    style: TextStyle(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w700,
                      color: task.taskRecurrence == 'daily'
                          ? Colors.green
                          : Colors.deepOrange,
                    ),
                  ),
                ]),
              )
            else ...[
              Icon(Icons.schedule_rounded,
                  size: 16.sp, color: AppColors.operationalPurple),
              SizedBox(width: 3.w),
              Text(time,
                  style:
                      TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700)),
            ],
          ]),
        ),
      ),
    );
  }
}
