// بناء بطاقات الإحصائيات
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../admin/employee_section/data/models/employee_attendance_history_model.dart';
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
    return Column(
      children: [
        Obx(
          () => _CompactAttendanceStrip(
            day: controller.todayAttendance.value,
            inside: controller.isStartWork ||
                controller.todayAttendance.value?.currentlyIn == true,
            elapsed: controller.elapsed.value,
            isStartWork: controller.isStartWork,
            startTime: controller.startTime,
            formatClock: _formatClock,
          ),
        ),
        SizedBox(height: 8.h),
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

class _CompactAttendanceStrip extends StatelessWidget {
  const _CompactAttendanceStrip({
    required this.day,
    required this.inside,
    required this.elapsed,
    required this.isStartWork,
    required this.startTime,
    required this.formatClock,
  });

  final EmployeeAttendanceDay? day;
  final bool inside;
  final Duration elapsed;
  final bool isStartWork;
  final DateTime? startTime;
  final String? Function(DateTime?) formatClock;

  void _openQrCheckout() => Get.toNamed(AppRoutes.FULLSCREENQRSCANNER);

  BoxDecoration _cardDecoration({Color? accent}) {
    final isDark = ThemeService.isDark.value;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(10.r),
      color: isDark ? AppColors.customGreyColor : AppColors.whiteColor2,
      border: Border.all(
        color: accent ??
            (isDark
                ? AppColors.customGreyColor7
                : AppColors.customGreyColor4.withValues(alpha: 0.35)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final checkIn = day?.firstCheckIn ?? day?.firstCheckInServer ?? startTime;
    final checkInLabel = formatClock(checkIn);

    if (inside) {
      Duration live = elapsed;
      if (!isStartWork && checkIn != null) {
        live = DateTime.now().difference(checkIn);
      }
      final h = live.inHours.toString().padLeft(2, '0');
      final m = (live.inMinutes % 60).toString().padLeft(2, '0');
      final s = (live.inSeconds % 60).toString().padLeft(2, '0');

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: _cardDecoration(accent: Colors.green.shade200),
        child: Row(
          children: [
            Container(
              width: 8.r,
              height: 8.r,
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$h:$m:$s',
                    style: theme.titleMedium?.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Colors.green.shade800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    [
                      if (checkInLabel != null)
                        '${'firstCheckInLabel'.tr} $checkInLabel',
                      'stillInside'.tr,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySmall?.copyWith(
                      fontSize: 10.sp,
                      color: AppColors.customGreyColor5,
                    ),
                  ),
                ],
              ),
            ),
            Tooltip(
              message: 'leaveWork'.tr,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openQrCheckout,
                  borderRadius: BorderRadius.circular(8.r),
                  child: Container(
                    width: 34.r,
                    height: 34.r,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      size: 18.sp,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (day != null) {
      final checkOut = day!.lastCheckOut ?? day!.lastCheckOutServer;
      final checkOutLabel = formatClock(checkOut);
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: _cardDecoration(accent: AppColors.secondaryColor.withValues(alpha: 0.25)),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 18.sp,
              color: AppColors.secondaryColor,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'todayAttendanceTitle'.tr,
                    style: theme.labelMedium?.copyWith(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryColor,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    [
                      if (checkInLabel != null) checkInLabel,
                      if (checkOutLabel != null) '→ $checkOutLabel',
                      AttendanceHistoryController.formatMinutes(day!.workedMinutes),
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySmall?.copyWith(
                      fontSize: 10.sp,
                      color: AppColors.customGreyColor5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openQrCheckout,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: _cardDecoration(accent: Colors.green.shade200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner_rounded,
                  size: 18.sp, color: Colors.green.shade700),
              SizedBox(width: 6.w),
              Text(
                'startWork'.tr,
                style: theme.labelLarge?.copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
