import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../admin/employee_section/presentation/controllers/attendance_history_controller.dart';
import '../controllers/employee_dashbord_controller.dart';

class EmployeeTodayAttendanceCard extends GetView<EmployeeDashbordController> {
  const EmployeeTodayAttendanceCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.todayAttendanceLoading.value) {
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      }
      final day = controller.todayAttendance.value;
      return InkWell(
        onTap: () => Get.toNamed(AppRoutes.MYATTENDANCEHISTORY),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : AppColors.whiteColor2,
            border: Border.all(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor7
                  : AppColors.customGreyColor4.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 30.sp,
                color: AppColors.secondaryColor,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'todayAttendanceTitle'.tr,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    SizedBox(height: 4.h),
                    if (day == null)
                      Text(
                        'noAttendanceToday'.tr,
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else ...[
                      Text(
                        AttendanceHistoryController.formatMinutes(
                            day.workedMinutes),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (day.currentlyIn)
                        Text(
                          'stillInside'.tr,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.green.shade700,
                                  ),
                        ),
                    ],
                    SizedBox(height: 2.h),
                    Text(
                      'tapForFullAttendanceHistory'.tr,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: ThemeService.isDark.value
                                ? AppColors.customGreyColor5
                                : AppColors.customGreyColor4,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left,
                color: AppColors.customGreyColor4,
                size: 22.sp,
              ),
            ],
          ),
        ),
      );
    });
  }
}
