import 'package:doctorbike/core/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/dashbord_employee_details_model.dart';
import '../controllers/employee_dashbord_controller.dart';

class EmployeeDashbordTasks extends GetView<EmployeeDashbordController> {
  const EmployeeDashbordTasks({Key? key, required this.task}) : super(key: key);

  final Task task;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(
          AppRoutes.TASKDETAILS,
          arguments: {
            'taskId': task.id.toString(),
            'EmployeeDashbordController': controller
          },
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9.r),
          border: Border.all(color: AppColors.primaryColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 80.w,
              child: Text(
                task.name,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      color: ThemeService.isDark.value
                          ? AppColors.customGreyColor7
                          : AppColors.customGreyColor4,
                    ),
              ),
            ),
            Container(
              height: 20.h,
              width: 1.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9.r),
                color: AppColors.primaryColor,
              ),
            ),
            Text(
              showData(task.startTime),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor7
                        : AppColors.customGreyColor4,
                  ),
            ),
            Container(
              height: 20.h,
              width: 1.w,
              padding: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9.r),
                color: AppColors.primaryColor,
              ),
            ),
            Text(
              showData(task.endTime),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor7
                        : AppColors.customGreyColor4,
                  ),
            ),
            Container(
              height: 20.h,
              width: 1.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9.r),
                color: AppColors.primaryColor,
              ),
            ),
            Transform.scale(
              scale: 1.5,
              child: Checkbox(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.r),
                ),
                side: const BorderSide(color: AppColors.primaryColor),
                value: task.status == 'completed',
                onChanged: (value) {
                  if (value == true) {
                    controller.changeTaskToCompleted(
                      context: context,
                      isSubTask: false,
                      taskId: task.id,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
