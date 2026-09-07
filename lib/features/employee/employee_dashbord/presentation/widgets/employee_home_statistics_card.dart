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
import '../controllers/employee_dashbord_controller.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.operationalPurple.withValues(alpha: .20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.operationalPurple.withValues(alpha: .05),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(14.w, 13.h, 14.w, 8.h),
          child: Row(children: [
            Icon(Icons.bar_chart_rounded,
                color: AppColors.operationalPurple, size: 22.sp),
            SizedBox(width: 7.w),
            Text(
              'ملخصي اليوم',
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w900,
                color: ThemeService.isDark.value
                    ? Colors.white
                    : AppColors.operationalNavy,
              ),
            ),
          ]),
        ),
        GetBuilder<EmployeeDashbordController>(builder: (c) {
          final data = c.employeeData.value;
          final tiles = <Widget>[
            _SummaryStat(
              title: 'workingHours',
              iconAsset: AssetsManager.doneIcon,
              value: data?.totalWorkHours ?? '0',
              subtitle:
                  data == null ? null : _hoursSubtitle(data.numberOfWorkHours),
              formatNumber: false,
            ),
            _SummaryStat(
              title: 'hourlyRate',
              iconAsset: AssetsManager.moneyIcon,
              value: data?.hourWorkPrice.toString() ?? '0',
              subtitle: 'currency',
            ),
            _SummaryStat(
              title: 'advancesAndDebts',
              iconAsset: AssetsManager.cashIcon,
              value: data?.debts ?? '0',
              subtitle: 'currency',
            ),
            _SummaryStat(
              title: 'remainingBalance',
              iconAsset: AssetsManager.cashIcon,
              value: data?.salary.toString() ?? '0',
              subtitle: 'currency',
            ),
            _SummaryStat(
              title: 'points',
              iconAsset: AssetsManager.cashIcon4,
              value: data?.points ?? '0',
              subtitle: 'point',
              formatNumber: false,
            ),
          ];
          return SizedBox(
            height: 72.h,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(tiles.length, (index) {
                  return Expanded(
                    child: Container(
                      decoration: index == tiles.length - 1
                          ? null
                          : BoxDecoration(
                              border: BorderDirectional(
                                end: BorderSide(
                                  color: AppColors.operationalPurple
                                      .withValues(alpha: .16),
                                ),
                              ),
                            ),
                      child: tiles[index],
                    ),
                  );
                }),
              ),
            ),
          );
        }),
        Obx(() {
          final summary = controller.employeeData.value?.todayTasksSummary;
          final total = summary?.total ?? 0;
          final completed = summary?.completed ?? 0;
          final progress = summary?.progressPercent ?? 0;
          return InkWell(
            onTap: controller.openTasksTab,
            child: Padding(
              padding: EdgeInsets.fromLTRB(13.w, 7.h, 13.w, 4.h),
              child: Row(children: [
                Icon(Icons.task_alt_rounded,
                    color: AppColors.operationalPurple, size: 20.sp),
                SizedBox(width: 7.w),
                Text(
                  'todayTasksProgress'.tr,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : progress / 100,
                      minHeight: 7.h,
                      color: AppColors.operationalPurple,
                      backgroundColor:
                          AppColors.operationalPurple.withValues(alpha: .10),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '$completed/$total',
                  style: TextStyle(
                    color: AppColors.operationalPurple,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ]),
            ),
          );
        }),
        Divider(height: 18.h, color: AppColors.operationalCardBorder),
        Padding(
          padding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 10.h),
          child: Obx(
            () => _CompactAttendanceStrip(
              day: controller.todayAttendance.value,
              inside: controller.isAttendanceInside,
              loading: controller.todayAttendanceLoading.value,
              elapsed: controller.elapsed.value,
              isStartWork: controller.isStartWork,
              startTime: controller.startTime,
              formatClock: _formatClock,
            ),
          ),
        ),
      ]),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.title,
    required this.iconAsset,
    required this.value,
    this.subtitle,
    this.formatNumber = true,
  });

  final String title;
  final String iconAsset;
  final String value;
  final String? subtitle;
  final bool formatNumber;

  String get displayValue {
    if (!formatNumber) return value;
    final number = double.tryParse(value.replaceAll(',', ''));
    return number == null ? value : NumberFormat('#,###.##').format(number);
  }

  @override
  Widget build(BuildContext context) {
    final shortTitle = <String, String>{
          'workingHours': 'ساعات العمل',
          'hourlyRate': 'سعر الساعة',
          'advancesAndDebts': 'السلف والديون',
          'remainingBalance': 'الرصيد',
          'points': 'النقاط',
        }[title] ??
        title.tr;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 4.h),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.asset(iconAsset, width: 13.w, height: 13.w),
          SizedBox(width: 2.w),
          Flexible(
            child: Text(
              shortTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 7.5.sp,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: ThemeService.isDark.value
                    ? Colors.white70
                    : AppColors.operationalNavy,
              ),
            ),
          ),
        ]),
        const Spacer(),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            displayValue,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.operationalPurple,
            ),
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!.tr,
            maxLines: 1,
            style: TextStyle(fontSize: 7.sp, color: AppColors.customGreyColor5),
          ),
      ]),
    );
  }
}

class _CompactAttendanceStrip extends StatelessWidget {
  const _CompactAttendanceStrip({
    required this.day,
    required this.inside,
    required this.loading,
    required this.elapsed,
    required this.isStartWork,
    required this.startTime,
    required this.formatClock,
  });

  final EmployeeAttendanceDay? day;
  final bool inside;
  final bool loading;
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
    if (loading) {
      return Container(
        height: 52.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: _cardDecoration(),
        alignment: Alignment.center,
        child: SizedBox(
          width: 18.r,
          height: 18.r,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

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
        decoration: _cardDecoration(
            accent: AppColors.secondaryColor.withValues(alpha: 0.25)),
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
                      AttendanceHistoryController.formatMinutes(
                          day!.workedMinutes),
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
