// بناء بطاقات الإحصائيات
import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../admin/employee_section/presentation/controllers/attendance_history_controller.dart';
import '../../data/models/dashbord_employee_details_model.dart';
import '../controllers/employee_dashbord_controller.dart';
import 'employee_compact_stat_tile.dart';

class EmployeeHomeStatisticsCard extends GetView<EmployeeDashbordController> {
  const EmployeeHomeStatisticsCard({Key? key}) : super(key: key);

  static String _hoursSubtitle(String raw) {
    final n = int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return n > 10 ? 'hour'.tr : 'hours'.tr;
  }

  static String? _formatClock(DateTime? value) {
    if (value == null) return null;
    return DateFormat('h:mm a', Get.locale?.toString()).format(value.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      children: [
        Obx(() {
          final day = controller.todayAttendance.value;
          final inside =
              controller.isStartWork || day?.currentlyIn == true;
          final checkIn = day?.firstCheckIn ??
              day?.firstCheckInServer ??
              controller.startTime;
          final checkInLabel = _formatClock(checkIn);

          if (inside) {
            final tick = controller.elapsed.value;
            Duration elapsed = tick;
            if (!controller.isStartWork && checkIn != null) {
              elapsed = DateTime.now().difference(checkIn);
            }
            final hours = elapsed.inHours;
            final minutes = elapsed.inMinutes % 60;
            final seconds = elapsed.inSeconds % 60;

            return Column(
              children: [
                AppButton(
                  text: 'leaveWork',
                  onPressed: () {
                    Get.toNamed(AppRoutes.FULLSCREENQRSCANNER);
                  },
                  color: Colors.red,
                  borderRadius: BorderRadius.all(Radius.circular(8.r)),
                ),
                if (checkInLabel != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    '${'firstCheckInLabel'.tr}: $checkInLabel',
                    style: theme.bodyMedium?.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: ThemeService.isDark.value
                          ? AppColors.customGreyColor6
                          : AppColors.secondaryColor,
                    ),
                  ),
                ],
                SizedBox(height: 6.h),
                Text(
                  'stillInside'.tr,
                  style: theme.bodySmall?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$seconds : $minutes : $hours',
                  style: theme.bodyLarge?.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            );
          }

          if (day != null) {
            final checkOut = day.lastCheckOut ?? day.lastCheckOutServer;
            final checkOutLabel = _formatClock(checkOut);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (checkInLabel != null)
                  Text(
                    '${'firstCheckInLabel'.tr}: $checkInLabel',
                    textAlign: TextAlign.center,
                    style: theme.bodyMedium?.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (checkOutLabel != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    '${'lastCheckOutLabel'.tr}: $checkOutLabel',
                    textAlign: TextAlign.center,
                    style: theme.bodyMedium?.copyWith(
                      fontSize: 14.sp,
                      color: AppColors.customGreyColor5,
                    ),
                  ),
                ],
                SizedBox(height: 6.h),
                Text(
                  AttendanceHistoryController.formatMinutes(day.workedMinutes),
                  textAlign: TextAlign.center,
                  style: theme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryColor,
                  ),
                ),
              ],
            );
          }

          return AppButton(
            text: 'startWork',
            onPressed: () {
              Get.toNamed(AppRoutes.FULLSCREENQRSCANNER);
            },
            color: Colors.green,
            borderRadius: BorderRadius.all(Radius.circular(8.r)),
          );
        }),
        SizedBox(height: 10.h),
        Obx(() {
          final summary =
              controller.employeeData.value?.todayTasksSummary ??
              const TodayTasksSummary();
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: controller.openTasksTab,
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              color: AppColors.operationalPurple.withValues(alpha: 0.08),
              border: Border.all(
                color: AppColors.operationalPurple.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'todayTasksProgress'.tr,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.operationalNavy,
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Text(
                      '${summary.progressPercent}%',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.operationalPurple,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'todayTasksProgressSubtitle'.trParams({
                              'done': '${summary.completed}',
                              'total': '${summary.total}',
                            }),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.customGreyColor5,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4.r),
                            child: LinearProgressIndicator(
                              value: summary.total > 0
                                  ? summary.progressPercent / 100
                                  : 0,
                              minHeight: 6.h,
                              color: AppColors.operationalPurple,
                              backgroundColor: AppColors.operationalSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
        }),
        SizedBox(height: 8.h),
        GetBuilder<EmployeeDashbordController>(
          builder: (c) {
            final data = c.employeeData.value;
            final tiles = <Widget>[
              EmployeeCompactStatTile(
                title: 'workingHours',
                iconAsset: AssetsManager.doneIcon,
                value: data?.totalWorkHours ?? '0',
                subtitle: data == null
                    ? null
                    : _hoursSubtitle(data.numberOfWorkHours),
                formatNumber: false,
              ),
              EmployeeCompactStatTile(
                title: 'hourlyRate',
                iconAsset: AssetsManager.moneyIcon,
                value: data?.hourWorkPrice.toString() ?? '0',
                subtitle: 'currency',
              ),
              EmployeeCompactStatTile(
                title: 'advancesAndDebts',
                iconAsset: AssetsManager.cashIcon,
                value: data?.debts ?? '0',
                subtitle: 'currency',
              ),
              EmployeeCompactStatTile(
                title: 'remainingBalance',
                iconAsset: AssetsManager.cashIcon,
                value: data?.salary.toString() ?? '0',
                subtitle: 'currency',
              ),
              EmployeeCompactStatTile(
                title: 'points',
                iconAsset: AssetsManager.cashIcon4,
                value: data?.points ?? '0',
                subtitle: 'point',
                formatNumber: false,
              ),
            ];
            return Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9.r),
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor
                    : AppColors.whiteColor2,
              ),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 6.h,
                crossAxisSpacing: 6.w,
                childAspectRatio: 2.35,
                children: tiles,
              ),
            );
          },
        ),
      ],
    );
  }
}
