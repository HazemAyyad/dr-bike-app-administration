import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/employee_dashbord_controller.dart';

/// Opens attendance history; shows a dot when today has a record or user is still inside.
class EmployeeAttendanceAppBarButton extends GetView<EmployeeDashbordController> {
  const EmployeeAttendanceAppBarButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.todayAttendanceLoading.value;
      final day = controller.todayAttendance.value;
      final hasRecord = day != null;
      final inside = day?.currentlyIn == true;

      return Tooltip(
        message: 'attendanceAppBarHint'.tr,
        child: Padding(
        padding: EdgeInsets.only(right: 4.w),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              ClipOval(
                child: Material(
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor
                      : AppColors.whiteColor2,
                  child: InkWell(
                    onTap: controller.openMyAttendanceHistory,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: loading
                          ? Padding(
                              padding: EdgeInsets.all(12.w),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.schedule_rounded,
                              color: AppColors.primaryColor,
                              size: 25.sp,
                            ),
                    ),
                  ),
                ),
              ),
              if (!loading && (hasRecord || inside))
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: inside ? Colors.green : AppColors.secondaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      );
    });
  }
}
