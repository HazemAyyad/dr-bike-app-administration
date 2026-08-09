import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/widgets/attendance_dual_time_text.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/employee_attendance_history_model.dart';
import '../../data/models/employee_advances_model.dart';
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
    this.advances,
    this.advancesLoading = false,
    this.onAddAdvance,
  }) : super(key: key);

  final EmployeeAttendanceHead employee;
  final List<EmployeeAttendanceDay> days;
  final EmployeeAttendanceMonthlySummary? monthlySummary;
  final Widget? headerExtra;
  final bool showTodaySummary;
  final bool showAdminEdit;
  final Future<void> Function(EmployeeAttendanceDay day)? onEditDay;
  final EmployeeAdvancesResult? advances;
  final bool advancesLoading;
  final VoidCallback? onAddAdvance;

  List<EmployeeAttendanceDay> get _logDays {
    final list = showTodaySummary
        ? days.where((d) => d.date != _todayDateKey()).toList()
        : List<EmployeeAttendanceDay>.from(days);
    // من الأحدث إلى الأقدم
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// ملخص الأسبوع — يُحسب من صفوف الأيام المحمّلة (آخر 7 أيام ضمن البيانات).
  // ignore: unused_element
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
          _AttendanceDaysTable(
            days: _logDays,
            showAdminEdit: showAdminEdit,
            onEditDay: onEditDay,
          ),
          SizedBox(height: 14.h),
          _EmployeeAdvancesInlineSection(
            advances: advances,
            loading: advancesLoading,
            onAdd: onAddAdvance,
          ),
        ],
      ],
    );
  }
}

class _EmployeeAdvancesInlineSection extends StatelessWidget {
  const _EmployeeAdvancesInlineSection({
    required this.advances,
    required this.loading,
    required this.onAdd,
  });

  final EmployeeAdvancesResult? advances;
  final bool loading;
  final VoidCallback? onAdd;

  String _status(String value) {
    switch (value) {
      case 'approved':
        return 'مقبولة';
      case 'rejected':
        return 'مرفوضة';
      case 'paid':
        return 'مدفوعة';
      default:
        return 'قيد المراجعة';
    }
  }

  Color _statusColor(String value) {
    switch (value) {
      case 'approved':
      case 'paid':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return AppColors.customOrange3;
    }
  }

  IconData _statusIcon(String value) {
    switch (value) {
      case 'approved':
      case 'paid':
        return Icons.arrow_downward_rounded;
      case 'rejected':
        return Icons.close_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  String _money(String value) {
    final amount = double.tryParse(value);
    if (amount == null) return value;
    return '${NumberFormat("#,##0.##").format(amount)} ${'currency'.tr}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final items = advances?.advances ?? const <EmployeeAdvanceModel>[];
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: _cardBg(isDark),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.fromBorderSide(_cardBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'السلف',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.operationalNavy,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'إضافة سلفة',
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.primaryColor,
              ),
            ],
          ),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (items.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Text(
                'لا توجد سلف في هذه الفترة',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
              ),
            )
          else
            Column(
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _AdvanceSummaryText(
                          label: 'المجموع',
                          value: _money(advances?.total ?? '0'),
                          color: isDark
                              ? Colors.white70
                              : AppColors.operationalNavy,
                        ),
                      ),
                      Expanded(
                        child: _AdvanceSummaryText(
                          label: 'المقبول',
                          value: _money(advances?.approvedTotal ?? '0'),
                          color: Colors.green,
                          alignEnd: true,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final advance = entry.value;
                  final color = _statusColor(advance.status);
                  final approved = advance.approvedLoanValue;
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.12),
                            radius: 22.r,
                            child: Icon(
                              _statusIcon(advance.status),
                              color: color,
                              size: 24.sp,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${advance.date}  ${advance.time}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.operationalNavy,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _money(advance.amount),
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w900,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4.h),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 3.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.10),
                                        borderRadius:
                                            BorderRadius.circular(999.r),
                                      ),
                                      child: Text(
                                        _status(advance.status),
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w800,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                    if (approved != null) ...[
                                      SizedBox(width: 8.w),
                                      Flexible(
                                        child: Text(
                                          'المعتمد: ${_money(approved)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            color: AppColors.customGreyColor5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if ((advance.reviewedAt ?? '').isNotEmpty ||
                                    (advance.rejectionReason ?? '')
                                        .isNotEmpty) ...[
                                  SizedBox(height: 4.h),
                                  Text(
                                    advance.rejectionReason?.isNotEmpty == true
                                        ? 'سبب الرفض: ${advance.rejectionReason}'
                                        : 'تمت المراجعة: ${advance.reviewedAt}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: AppColors.customGreyColor5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (index != items.length - 1)
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 10.h),
                          height: 1.h,
                          color:
                              isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                        ),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }
}

class _AdvanceSummaryText extends StatelessWidget {
  const _AdvanceSummaryText({
    required this.label,
    required this.value,
    required this.color,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }
}

class _AttendanceDaysTable extends StatelessWidget {
  const _AttendanceDaysTable({
    required this.days,
    required this.showAdminEdit,
    required this.onEditDay,
  });

  final List<EmployeeAttendanceDay> days;
  final bool showAdminEdit;
  final Future<void> Function(EmployeeAttendanceDay day)? onEditDay;

  static String _time(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  static String _value(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null || value.toString().isEmpty) return '-';
    return value.toString();
  }

  static String _durationValue(Map<String, dynamic> data, String key) {
    final raw = data[key];
    final minutes =
        raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '');
    if (minutes == null) return _value(data, key);
    return AttendanceHistoryController.formatMinutes(minutes);
  }

  static String _sourceLabel(String? source) {
    switch (source) {
      case 'admin_edit':
        return 'تعديل يدوي';
      case 'fingerprint':
        return 'بصمة';
      case 'qr':
        return 'QR';
      case 'manual':
        return 'يدوي';
      case 'auto':
        return 'تلقائي';
      default:
        return source == null || source.isEmpty ? '-' : source;
    }
  }

  static String _editDisabledReason(EmployeeAttendanceDay day) {
    switch (day.canEditDayReason) {
      case 'shift_open':
        return 'لا يمكن تعديل اليوم والموظف ما زال داخل الدوام. سجل خروج أولا.';
      default:
        return 'لا يمكن تعديل هذا اليوم حاليا';
    }
  }

  static String _scanLine(Map<String, dynamic> scan) {
    final direction = scan['direction']?.toString() == 'out' ? 'خروج' : 'دخول';
    final source = _sourceLabel(scan['source']?.toString());
    final rawAt = scan['scanned_at']?.toString() ?? '';
    final at = rawAt.length >= 16 ? rawAt.substring(11, 16) : rawAt;
    return '$direction: $at ($source)';
  }

  static Widget _scanList(String title, Map<String, dynamic> values) {
    final raw = values['scans'];
    final scans = raw is List ? raw.whereType<Map>().toList() : const <Map>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 4.h),
        if (scans.isEmpty)
          Text('-', style: TextStyle(fontSize: 11.sp))
        else
          ...scans.map(
            (scan) => Text(
              _scanLine(Map<String, dynamic>.from(scan)),
              style: TextStyle(fontSize: 11.sp),
            ),
          ),
      ],
    );
  }

  static String _timeValue(Map<String, dynamic> data, String key) {
    final value = _value(data, key);
    if (value == '-' || value.length < 5) return value;
    return value.substring(0, 5);
  }

  static String _rangeValue(Map<String, dynamic> data) {
    return 'من ${_timeValue(data, 'arrived_at')} إلى ${_timeValue(data, 'left_at')}';
  }

  static String _countedCheckoutValue(Map<String, dynamic> data) {
    final arrived = _timeValue(data, 'arrived_at');
    final worked = data['worked_minutes'];
    final minutes =
        worked is num ? worked.toInt() : int.tryParse(worked?.toString() ?? '');
    if (arrived == '-' || minutes == null) return _timeValue(data, 'left_at');

    final parts = arrived.split(':');
    if (parts.length < 2) return _timeValue(data, 'left_at');
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return _timeValue(data, 'left_at');

    final total = (hour * 60 + minute + minutes) % (24 * 60);
    return '${(total ~/ 60).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';
  }

  static String _timeBundleValue(Map<String, dynamic> data) {
    return 'دخول ${_timeValue(data, 'arrived_at')} | فعلي ${_timeValue(data, 'left_at')} | محسوب ${_countedCheckoutValue(data)}';
  }

  static Widget _dayTimeHistory(EmployeeAttendanceDay day) {
    final rows = <Widget>[];

    if (day.adjustments.isNotEmpty) {
      rows.add(_tableTimeLine(
        title: 'الأصلي',
        values: day.adjustments.first.beforeValues,
        isLatest: false,
      ));
      for (var i = 0; i < day.adjustments.length; i++) {
        final adjustment = day.adjustments[i];
        rows.add(_tableTimeLine(
          title: i == day.adjustments.length - 1 ? 'المعتمد' : 'تعديل ${i + 1}',
          values: adjustment.afterValues,
          isLatest: i == day.adjustments.length - 1,
        ));
      }
    } else {
      rows.add(_plainTimeLine(
        title: 'المعتمد',
        value:
            'دخول ${_time(day.firstCheckIn)} | فعلي ${_time(day.actualCheckOut ?? day.lastCheckOut)} | محسوب ${_time(day.calculatedCheckOut ?? day.lastCheckOut)}',
      ));
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 190.w, maxWidth: 280.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: rows,
      ),
    );
  }

  static Widget _plainTimeLine({
    required String title,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Text(
        '$title: $value',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
      ),
    );
  }

  static Widget _tableTimeLine({
    required String title,
    required Map<String, dynamic> values,
    required bool isLatest,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 3.h),
      child: Text(
        '$title: ${_timeBundleValue(values)}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: isLatest ? FontWeight.w900 : FontWeight.w700,
          color: isLatest ? AppColors.primaryColor : null,
        ),
      ),
    );
  }

  static Widget _timeStateRow({
    required String title,
    required Map<String, dynamic> values,
    required bool isLatest,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isLatest
            ? AppColors.primaryColor.withValues(alpha: 0.08)
            : const Color(0xFFF8FAFC),
        border: Border.all(
          color: isLatest ? AppColors.primaryColor : const Color(0xFFE5E7EB),
        ),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(
            isLatest ? Icons.check_circle_outline : Icons.history,
            size: 18.sp,
            color:
                isLatest ? AppColors.primaryColor : AppColors.customGreyColor5,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                    color: isLatest
                        ? AppColors.primaryColor
                        : AppColors.operationalNavy,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _rangeValue(values),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (isLatest)
            Text(
              'المعتمد',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryColor,
              ),
            ),
        ],
      ),
    );
  }

  static Widget _adjustmentsTimeline(
      List<EmployeeAttendanceAdjustmentRow> adjustments) {
    final widgets = <Widget>[];
    final first = adjustments.first;
    widgets.add(_timeStateRow(
      title: 'الوقت الأصلي',
      values: first.beforeValues,
      isLatest: false,
    ));

    for (var i = 0; i < adjustments.length; i++) {
      final adjustment = adjustments[i];
      final isLatest = i == adjustments.length - 1;
      widgets.add(_timeStateRow(
        title: 'بعد تعديل #${adjustment.id}',
        values: adjustment.afterValues,
        isLatest: isLatest,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  void _showAdjustments(EmployeeAttendanceDay day) {
    if (day.adjustments.isEmpty) return;
    Get.dialog<void>(
      AlertDialog(
        title: Text('تعديلات ${day.date}'),
        content: SizedBox(
          width: 560.w,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _adjustmentsTimeline(day.adjustments),
                SizedBox(height: 8.h),
                Text(
                  'تفاصيل التعديلات',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6.h),
                ...day.adjustments.map((adjustment) {
                  final before = adjustment.beforeValues;
                  final after = adjustment.afterValues;
                  return Container(
                    margin: EdgeInsets.only(bottom: 10.h),
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          adjustment.createdAt == null
                              ? 'تعديل #${adjustment.id}'
                              : 'تعديل #${adjustment.id} - ${_time(adjustment.createdAt)}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'بواسطة: ${adjustment.editedByName ?? adjustment.editedBy?.toString() ?? '-'}   المصدر: ${_sourceLabel(adjustment.source)}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.customGreyColor5,
                          ),
                        ),
                        if ((adjustment.note ?? '').isNotEmpty) ...[
                          SizedBox(height: 3.h),
                          Text(
                            adjustment.note!,
                            style: TextStyle(fontSize: 11.sp),
                          ),
                        ],
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'قبل: ${_rangeValue(before)}',
                                style: TextStyle(fontSize: 12.sp),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'بعد: ${_rangeValue(after)}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'الصافي: ${_durationValue(after, 'worked_minutes')}   '
                          'العادي: ${_durationValue(after, 'normal_minutes')}   '
                          'الأوفر: ${_durationValue(after, 'overtime_minutes')}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.customGreyColor5,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: EdgeInsets.zero,
                          title: Text(
                            'حركات الدخول والخروج قبل/بعد',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child:
                                        _scanList('حركات اليوم قبل', before)),
                                SizedBox(width: 12.w),
                                Expanded(
                                    child: _scanList('حركات اليوم بعد', after)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final bg = isDark ? AppColors.customGreyColor4 : Colors.white;
    final border = isDark ? Colors.white12 : const Color(0xFFE1E5EE);
    final weeklyOffColor = isDark
        ? AppColors.customOrange3.withValues(alpha: 0.22)
        : const Color(0xFFFFF3D8);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: border),
        ),
        child: DataTable(
          columnSpacing: 18.w,
          horizontalMargin: 10.w,
          dataRowMinHeight: 46.h,
          dataRowMaxHeight: 128.h,
          headingRowColor: WidgetStateProperty.resolveWith(
            (_) => AppColors.primaryColor,
          ),
          headingTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          columns: [
            const DataColumn(label: Text('التاريخ')),
            const DataColumn(label: Text('الحالة')),
            const DataColumn(label: Text('حركات اليوم')),
            const DataColumn(label: Text('الصافي')),
            const DataColumn(label: Text('أوفر تايم')),
            const DataColumn(label: Text('تعديلات')),
            if (showAdminEdit) const DataColumn(label: Text('')),
          ],
          rows: days.map((day) {
            final isOff = day.isWeeklyOff || _isPresentOnWeeklyDayOff(day);
            return DataRow(
              color: WidgetStateProperty.resolveWith(
                (_) => isOff ? weeklyOffColor : null,
              ),
              cells: [
                DataCell(Text(_compactDayTitle(day.date))),
                DataCell(Text(day.attendanceStatusLabel ?? '-')),
                DataCell(_dayTimeHistory(day)),
                DataCell(Text(
                  day.workedHours ??
                      AttendanceHistoryController.formatMinutes(
                        day.calculatedWorkedMinutes,
                      ),
                )),
                DataCell(Text(
                  AttendanceHistoryController.formatMinutes(
                    day.contractOvertimeMinutes ?? day.overtimeMinutes,
                  ),
                )),
                DataCell(
                  day.adjustments.isEmpty
                      ? const Text('-')
                      : TextButton.icon(
                          onPressed: () => _showAdjustments(day),
                          icon: const Icon(Icons.history, size: 16),
                          label: Text('${day.adjustments.length}'),
                        ),
                ),
                if (showAdminEdit)
                  DataCell(
                    day.canEditDay && onEditDay != null
                        ? IconButton(
                            tooltip: 'editAttendanceDay'.tr,
                            onPressed: () => onEditDay!(day),
                            icon: const Icon(Icons.edit_outlined),
                          )
                        : Tooltip(
                            message: _editDisabledReason(day),
                            child: const Icon(
                              Icons.lock_clock_outlined,
                              color: Colors.grey,
                            ),
                          ),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
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

// ignore: unused_element
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

// ignore: unused_element
class _CompactAttendanceDayCard extends StatelessWidget {
  const _CompactAttendanceDayCard({
    required this.day,
    required this.showAdminEdit,
    required this.onEdit,
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
