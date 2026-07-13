import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/widgets/attendance_dual_time_text.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/employee_attendance_history_model.dart';
import '../controllers/attendance_history_controller.dart';

String _weeklyDaysOffLabel(List<String> stored) => stored.isEmpty
    ? 'noWeeklyDaysOff'.tr
    : stored.map((d) => 'day_${d.toLowerCase()}'.tr).join(' · ');

bool _isPresentOnWeeklyDayOff(EmployeeAttendanceDay day) =>
    day.attendanceStatus == 'present_on_weekly_day_off';

String _todayDateKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

EmployeeAttendanceDay? _findTodayDay(List<EmployeeAttendanceDay> days) {
  final key = _todayDateKey();
  for (final d in days) {
    if (d.date == key) return d;
  }
  return null;
}

String _compactDayTitle(String dateStr) {
  final df = DateFormat('yyyy-MM-dd');
  try {
    final date = df.parse(dateStr);
    return DateFormat('EEEE d/M', Get.locale?.toString()).format(date);
  } catch (_) {
    return dateStr;
  }
}

Color _cardBg(bool isDark) =>
    isDark ? AppColors.customGreyColor4 : AppColors.whiteColor;

BorderSide _cardBorder(bool isDark) => BorderSide(
      color: isDark ? Colors.white12 : AppColors.operationalCardBorder,
    );

/// Shared list body for admin and employee attendance history screens.
class AttendanceHistoryBody extends StatelessWidget {
  const AttendanceHistoryBody({
    Key? key,
    required this.employee,
    required this.days,
    this.monthlySummary,
    this.headerExtra,
    this.showTodaySummary = false,
    this.showAdminEdit = false,
    this.onEditDay,
  }) : super(key: key);

  final EmployeeAttendanceHead employee;
  final List<EmployeeAttendanceDay> days;
  final EmployeeAttendanceMonthlySummary? monthlySummary;
  final Widget? headerExtra;
  final bool showTodaySummary;
  final bool showAdminEdit;
  final Future<void> Function(EmployeeAttendanceDay day)? onEditDay;

  List<EmployeeAttendanceDay> get _logDays {
    final list = showTodaySummary
        ? days.where((d) => d.date != _todayDateKey()).toList()
        : List<EmployeeAttendanceDay>.from(days);
    // من الأحدث إلى الأقدم
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// ملخص الأسبوع — يُحسب من صفوف الأيام المحمّلة (آخر 7 أيام ضمن البيانات).
  List<Widget> _buildWeeklySection() {
    final agg = _WeeklyAggregate.fromDays(days);
    if (agg == null) return const [];
    return [_WeeklySummarySection(aggregate: agg)];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final todayDay = _findTodayDay(days);

    return ListView(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 16.h),
      children: [
        if (headerExtra != null) headerExtra!,
        if (showTodaySummary)
          _TodayShiftSummaryCard(
            employee: employee,
            day: todayDay,
          ),
        if (monthlySummary != null)
          _MonthlySummarySection(summary: monthlySummary!),
        ..._buildWeeklySection(),
        if (_logDays.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 4.h, 4.w, 8.h),
            child: Text(
              'attendanceDaysLogTitle'.tr,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.operationalNavy,
              ),
            ),
          ),
          ..._logDays.map(
            (d) => _CompactAttendanceDayCard(
              day: d,
              showAdminEdit: showAdminEdit,
              onEdit: onEditDay == null ? null : () => onEditDay!(d),
            ),
          ),
        ],
      ],
    );
  }
}

class _TodayShiftSummaryCard extends StatelessWidget {
  const _TodayShiftSummaryCard({
    required this.employee,
    required this.day,
  });

  final EmployeeAttendanceHead employee;
  final EmployeeAttendanceDay? day;

  String _statusLabel() {
    if (day == null) return 'shiftStatusNoRecord'.tr;
    if (day!.currentlyIn) {
      if (day!.overtimeMinutes > 0) return 'shiftStatusOvertime'.tr;
      return 'shiftStatusWorking'.tr;
    }
    if (day!.firstCheckIn != null) return 'shiftStatusLeft'.tr;
    return 'shiftStatusNoRecord'.tr;
  }

  Color _statusColor() {
    if (day == null) return AppColors.customGreyColor5;
    if (day!.currentlyIn) {
      return day!.overtimeMinutes > 0
          ? AppColors.customOrange3
          : AppColors.customGreen1;
    }
    if (day!.firstCheckIn != null) return AppColors.customGreyColor5;
    return Colors.red.shade400;
  }

  String _checkOutFallback() {
    if (day == null) return 'notCheckedOutYet'.tr;
    if (day!.currentlyIn) return 'stillInside'.tr;
    if (day!.lastCheckOut != null) return '';
    return 'notCheckedOutYet'.tr;
  }

  String _onTimeLabel() {
    if (day?.onTime == null) return '—';
    return day!.onTime! ? 'onTimeYes'.tr : 'onTimeNo'.tr;
  }

  Color _onTimeColor() {
    if (day?.onTime == null) return AppColors.customGreyColor5;
    return day!.onTime! ? AppColors.customGreen1 : Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final worked = day?.workedMinutes ?? 0;
    final required = day?.expectedWorkMinutes ??
        _parseDailyMinutes(employee.numberOfWorkHours);
    final overtime = day?.overtimeMinutes ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: _cardBg(isDark),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.fromBorderSide(_cardBorder(isDark)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.operationalNavy.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.operationalPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.today_rounded,
                  size: 20.sp,
                  color: AppColors.operationalPurple,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'todayShiftSummaryTitle'.tr,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.operationalNavy,
                  ),
                ),
              ),
              _StatusChip(label: _statusLabel(), color: _statusColor()),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: AttendanceDualTimeTile(
                  label: 'attendanceCheckIn'.tr,
                  deviceAt: day?.firstCheckIn,
                  serverAt: null,
                  source: null,
                  accent: AppColors.customGreen1,
                  fallback:
                      day?.firstCheckIn == null ? 'notCheckedInYet'.tr : null,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: AttendanceDualTimeTile(
                  label: 'attendanceCheckOut'.tr,
                  deviceAt: day?.currentlyIn == true ? null : day?.lastCheckOut,
                  serverAt: null,
                  source: null,
                  accent: AppColors.customOrange3,
                  fallback: _checkOutFallback(),
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _MiniStatTile(
                  icon: Icons.schedule_rounded,
                  label: 'onTimeLabel'.tr,
                  value: _onTimeLabel(),
                  accent: _onTimeColor(),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Expanded(
                child: _MiniStatTile(
                  icon: Icons.flag_outlined,
                  label: 'todayRequiredShort'.tr,
                  value: AttendanceHistoryController.formatMinutes(required),
                  accent: AppColors.operationalPurple,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _MiniStatTile(
                  icon: Icons.timelapse_rounded,
                  label: 'todayWorkedShort'.tr,
                  value: AttendanceHistoryController.formatMinutes(worked),
                  accent: day?.currentlyIn == true
                      ? AppColors.customGreen1
                      : AppColors.operationalNavy,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _MiniStatTile(
                  icon: Icons.more_time_rounded,
                  label: 'overtimeLabel'.tr,
                  value: AttendanceHistoryController.formatMinutes(overtime),
                  accent: AppColors.customOrange3,
                ),
              ),
            ],
          ),
          if (employee.startWorkTime != null &&
              employee.startWorkTime!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              '${'scheduledStart'.tr}: ${employee.startWorkTime}',
              style: TextStyle(
                fontSize: 10.5.sp,
                color: AppColors.customGreyColor5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _parseDailyMinutes(String? hours) {
    if (hours == null || hours.isEmpty) return 0;
    final n = double.tryParse(hours.replaceAll(',', '.'));
    if (n == null) return 0;
    return (n * 60).round();
  }
}

class _MonthlySummarySection extends StatelessWidget {
  const _MonthlySummarySection({required this.summary});

  final EmployeeAttendanceMonthlySummary summary;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;

    final stats = <_SummaryStat>[
      _SummaryStat(
        icon: Icons.timelapse_rounded,
        label: 'workedHoursLabel'.tr,
        value: summary.rangeWorkedHours ??
            AttendanceHistoryController.formatMinutes(
              summary.rangeWorkedMinutes ?? 0,
            ),
        color: AppColors.operationalPurple,
      ),
      _SummaryStat(
        icon: Icons.flag_outlined,
        label: 'requiredHoursLabel'.tr,
        value: summary.rangeRequiredHours ??
            AttendanceHistoryController.formatMinutes(
              summary.rangeRequiredMinutes ?? 0,
            ),
        color: AppColors.operationalNavy,
      ),
      _SummaryStat(
        icon: Icons.more_time_rounded,
        label: 'overtimeHoursLabel'.tr,
        value: summary.rangeOvertimeHours ??
            AttendanceHistoryController.formatMinutes(
              summary.rangeOvertimeMinutes ?? 0,
            ),
        color: AppColors.customOrange3,
      ),
      if (summary.monthlyWorkingDaysCount != null)
        _SummaryStat(
          icon: Icons.calendar_month_outlined,
          label: 'monthlyWorkingDaysLabel'.tr,
          value: summary.monthlyWorkingDaysCount.toString(),
          color: AppColors.customGreen1,
        ),
      if (summary.rangeTotalSalary != null &&
          summary.rangeTotalSalary!.isNotEmpty)
        _SummaryStat(
          icon: Icons.payments_outlined,
          label: 'totalSalaryLabel'.tr,
          value: summary.rangeTotalSalary!,
          color: const Color(0xFF059669),
        ),
    ];

    return _CollapsibleSummaryCard(
      icon: Icons.insights_rounded,
      title: 'monthlySummaryTitle'.tr,
      rangeText: (summary.rangeFrom != null && summary.rangeTo != null)
          ? '${summary.rangeFrom} → ${summary.rangeTo}'
          : null,
      stats: stats,
      footer: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: AppColors.operationalSurface,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            Icon(
              Icons.beach_access_outlined,
              size: 16.sp,
              color: AppColors.customGreyColor5,
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                '${'weeklyDaysOffTitle'.tr}: ${_weeklyDaysOffLabel(summary.weeklyDaysOff)}',
                style: TextStyle(
                  fontSize: 10.5.sp,
                  color: isDark ? Colors.white70 : AppColors.customGreyColor5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// تجميعة بيانات الأسبوع المحسوبة محليًا من صفوف الأيام.
class _WeeklyAggregate {
  const _WeeklyAggregate({
    required this.from,
    required this.to,
    required this.workedMinutes,
    required this.requiredMinutes,
    required this.overtimeMinutes,
    required this.workingDays,
    required this.totalSalary,
  });

  final String from;
  final String to;
  final int workedMinutes;
  final int requiredMinutes;
  final int overtimeMinutes;
  final int workingDays;
  final double totalSalary;

  /// يحسب ملخص آخر 7 أيام ضمن البيانات المحمّلة (اعتمادًا على أحدث يوم موجود).
  static _WeeklyAggregate? fromDays(List<EmployeeAttendanceDay> days) {
    if (days.isEmpty) return null;

    DateTime? parse(String s) {
      try {
        return DateTime.parse(s);
      } catch (_) {
        return null;
      }
    }

    DateTime? anchor;
    for (final d in days) {
      final dt = parse(d.date);
      if (dt == null) continue;
      if (anchor == null || dt.isAfter(anchor)) anchor = dt;
    }
    if (anchor == null) return null;

    final daysSinceSaturday = (anchor.weekday - DateTime.saturday + 7) % 7;
    final weekStart = anchor.subtract(Duration(days: daysSinceSaturday));
    final weekEnd = weekStart.add(const Duration(days: 6));

    var workedMinutes = 0;
    var requiredMinutes = 0;
    var workingDays = 0;
    var totalSalary = 0.0;

    for (final d in days) {
      final dt = parse(d.date);
      if (dt == null) continue;
      if (dt.isBefore(weekStart) || dt.isAfter(weekEnd)) continue;
      workedMinutes += d.workedMinutes;
      requiredMinutes += d.expectedWorkMinutes;
      workingDays += 1;
      final s = double.tryParse(d.totalSalary ?? '');
      if (s != null) totalSalary += s;
    }

    if (workingDays == 0) return null;

    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return _WeeklyAggregate(
      from: fmt(weekStart),
      to: fmt(weekEnd),
      workedMinutes: workedMinutes,
      requiredMinutes: requiredMinutes,
      overtimeMinutes:
          workedMinutes > requiredMinutes ? workedMinutes - requiredMinutes : 0,
      workingDays: workingDays,
      totalSalary: totalSalary,
    );
  }
}

class _WeeklySummarySection extends StatelessWidget {
  const _WeeklySummarySection({required this.aggregate});

  final _WeeklyAggregate aggregate;

  @override
  Widget build(BuildContext context) {
    final stats = <_SummaryStat>[
      _SummaryStat(
        icon: Icons.timelapse_rounded,
        label: 'workedHoursLabel'.tr,
        value: AttendanceHistoryController.formatMinutes(
          aggregate.workedMinutes,
        ),
        color: AppColors.operationalPurple,
      ),
      _SummaryStat(
        icon: Icons.flag_outlined,
        label: 'requiredHoursLabel'.tr,
        value: AttendanceHistoryController.formatMinutes(
          aggregate.requiredMinutes,
        ),
        color: AppColors.operationalNavy,
      ),
      _SummaryStat(
        icon: Icons.more_time_rounded,
        label: 'overtimeHoursLabel'.tr,
        value: AttendanceHistoryController.formatMinutes(
          aggregate.overtimeMinutes,
        ),
        color: AppColors.customOrange3,
      ),
      _SummaryStat(
        icon: Icons.calendar_view_week_outlined,
        label: 'weeklyWorkingDaysLabel'.tr,
        value: aggregate.workingDays.toString(),
        color: AppColors.customGreen1,
      ),
      if (aggregate.totalSalary > 0)
        _SummaryStat(
          icon: Icons.payments_outlined,
          label: 'totalSalaryLabel'.tr,
          value: aggregate.totalSalary.toStringAsFixed(2),
          color: const Color(0xFF059669),
        ),
    ];

    return _CollapsibleSummaryCard(
      icon: Icons.calendar_view_week_rounded,
      title: 'weeklySummaryTitle'.tr,
      rangeText: '${aggregate.from} → ${aggregate.to}',
      stats: stats,
    );
  }
}

/// بطاقة ملخص قابلة للطي (مغلقة افتراضيًا) — تُستخدم للشهري والأسبوعي.
class _CollapsibleSummaryCard extends StatelessWidget {
  const _CollapsibleSummaryCard({
    required this.icon,
    required this.title,
    required this.stats,
    this.rangeText,
    this.footer,
  });

  final IconData icon;
  final String title;
  final List<_SummaryStat> stats;
  final String? rangeText;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: _cardBg(isDark),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.fromBorderSide(_cardBorder(isDark)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: EdgeInsets.symmetric(horizontal: 12.w),
          childrenPadding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          leading: Icon(icon, size: 20.sp, color: AppColors.operationalPurple),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.operationalNavy,
            ),
          ),
          subtitle: rangeText == null
              ? null
              : Text(
                  rangeText!,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.customGreyColor5,
                  ),
                ),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final w = (constraints.maxWidth - 6.w) / 2;
                return Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: stats
                      .map(
                        (s) => SizedBox(
                          width: w,
                          child: _SummaryStatCard(stat: s, isDark: isDark),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            if (footer != null) ...[
              SizedBox(height: 8.h),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryStat {
  const _SummaryStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class _SummaryStatCard extends StatelessWidget {
  const _SummaryStatCard({required this.stat, required this.isDark});

  final _SummaryStat stat;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: stat.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(stat.icon, size: 18.sp, color: stat.color),
          SizedBox(height: 4.h),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5.sp,
              color: AppColors.customGreyColor5,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.operationalNavy,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactAttendanceDayCard extends StatelessWidget {
  const _CompactAttendanceDayCard({
    required this.day,
    this.showAdminEdit = false,
    this.onEdit,
  });

  final EmployeeAttendanceDay day;
  final bool showAdminEdit;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final primaryText = isDark ? Colors.white : AppColors.operationalNavy;
    final hasDetails = day.segments.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      decoration: BoxDecoration(
        color: _cardBg(isDark),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.fromBorderSide(_cardBorder(isDark)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 0),
          childrenPadding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 10.h),
          visualDensity: VisualDensity.compact,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showAdminEdit && day.canEditDay && onEdit != null)
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 18.sp),
                  tooltip: 'editAttendanceDay'.tr,
                  onPressed: onEdit,
                ),
              const Icon(Icons.expand_more),
            ],
          ),
          leading: Container(
            width: 36.w,
            height: 36.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.operationalPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.event_note_outlined,
              size: 18.sp,
              color: AppColors.operationalPurple,
            ),
          ),
          title: Text(
            _compactDayTitle(day.date),
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: primaryText,
              height: 1.2,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${'attendanceCheckIn'.tr}:',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.customGreyColor5,
                          ),
                        ),
                        AttendanceDualTimeText(
                          deviceAt: day.firstCheckIn,
                          serverAt: null,
                          source: null,
                          compact: true,
                          inline: true,
                          fallback: 'notCheckedInYet'.tr,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${'attendanceCheckOut'.tr}:',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.customGreyColor5,
                          ),
                        ),
                        day.currentlyIn
                            ? Text(
                                'stillInside'.tr,
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.customGreyColor5,
                                ),
                              )
                            : AttendanceDualTimeText(
                                deviceAt: day.lastCheckOut,
                                serverAt: null,
                                source: null,
                                compact: true,
                                inline: true,
                                fallback: 'notCheckedOutYet'.tr,
                              ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Wrap(
                spacing: 4.w,
                runSpacing: 4.h,
                children: [
                  _StatusChip(
                    label: AttendanceHistoryController.formatMinutes(
                      day.workedMinutes,
                    ),
                    color: AppColors.operationalNavy,
                    compact: true,
                  ),
                  if (day.onTime != null)
                    _StatusChip(
                      label: day.onTime! ? 'onTimeYes'.tr : 'onTimeNo'.tr,
                      color: day.onTime!
                          ? AppColors.customGreen1
                          : Colors.red.shade400,
                      compact: true,
                    ),
                  if (_isPresentOnWeeklyDayOff(day))
                    _StatusChip(
                      label: 'workedOnWeeklyDayOff'.tr,
                      color: AppColors.customOrange3,
                      compact: true,
                    ),
                  if (day.overtimeMinutes > 0)
                    _StatusChip(
                      label:
                          '${'overtimeLabel'.tr} ${AttendanceHistoryController.formatMinutes(day.overtimeMinutes)}',
                      color: AppColors.customOrange3,
                      compact: true,
                    ),
                  if (day.overtimeRequestStatus == 'pending' &&
                      day.overtimeRequestedMinutes > 0)
                    _StatusChip(
                      label:
                          '${'overtimePendingApproval'.tr} ${AttendanceHistoryController.formatMinutes(day.overtimeRequestedMinutes)}',
                      color: Colors.orange.shade700,
                      compact: true,
                    ),
                  if (day.overtimeRequestStatus == 'approved' &&
                      (day.overtimeApprovedMinutes ?? 0) > 0)
                    _StatusChip(
                      label:
                          '${'overtimeApprovedLabel'.tr} ${AttendanceHistoryController.formatMinutes(day.overtimeApprovedMinutes ?? 0)}',
                      color: AppColors.customGreen1,
                      compact: true,
                    ),
                  if (day.overtimeRequestStatus == 'rejected')
                    _StatusChip(
                      label: 'overtimeRejectedLabel'.tr,
                      color: Colors.red.shade400,
                      compact: true,
                    ),
                  if (day.source != null && day.source!.isNotEmpty)
                    _StatusChip(
                      label: _sourceLabel(day.source!),
                      color: _sourceColor(day.source!),
                      compact: true,
                    ),
                ],
              ),
              if (hasDetails)
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: Text(
                    'detailsTapExpand'.tr,
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: AppColors.customGreyColor5,
                    ),
                  ),
                ),
            ],
          ),
          children: hasDetails
              ? [
                  if (day.segments.isNotEmpty) ...[
                    _DetailSectionTitle('segmentsTitle'.tr),
                    ...day.segments.map((s) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${'attendanceCheckIn'.tr}:',
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color: AppColors.customGreyColor5,
                                        ),
                                      ),
                                      AttendanceDualTimeText(
                                        deviceAt: s.checkInAt,
                                        serverAt: null,
                                        source: null,
                                        compact: true,
                                        inline: true,
                                      ),
                                    ],
                                  ),
                                ),
                                if (!s.open) ...[
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${'attendanceCheckOut'.tr}:',
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            color: AppColors.customGreyColor5,
                                          ),
                                        ),
                                        AttendanceDualTimeText(
                                          deviceAt: s.checkOutAt,
                                          serverAt: null,
                                          source: null,
                                          compact: true,
                                          inline: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (s.open)
                              Padding(
                                padding: EdgeInsets.only(top: 2.h),
                                child: Text(
                                  'stillInside'.tr,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: AppColors.customGreen1,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ]
              : [
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Text(
                      'noData'.tr,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.customGreyColor5,
                      ),
                    ),
                  ),
                ],
        ),
      ),
    );
  }

  static String _sourceLabel(String source) {
    final s = source.toLowerCase().trim();
    if (s == 'fingerprint') return 'fingerprintAttendance'.tr;
    if (s == 'manual') return 'manualAttendance'.tr;
    if (s == 'qr') return 'qrAttendance'.tr;
    return source;
  }

  static Color _sourceColor(String source) {
    final s = source.toLowerCase().trim();
    if (s == 'fingerprint') return const Color(0xFF2563EB);
    if (s == 'manual') return const Color(0xFF6B7280);
    if (s == 'qr') return const Color(0xFF7C3AED);
    return AppColors.customGreyColor5;
  }
}

class _MiniStatTile extends StatelessWidget {
  const _MiniStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16.sp, color: accent),
          SizedBox(height: 4.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.sp,
              color: AppColors.customGreyColor5,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.operationalNavy,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    this.compact = false,
  });

  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6.w : 8.w,
        vertical: compact ? 2.h : 4.h,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 9.sp : 10.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _DetailSectionTitle extends StatelessWidget {
  const _DetailSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h, top: 2.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.operationalNavy,
        ),
      ),
    );
  }
}
