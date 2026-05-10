import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/models/employee_attendance_history_model.dart';
import '../controllers/attendance_history_controller.dart';

/// Shared list body for admin and employee attendance history screens.
class AttendanceHistoryBody extends StatelessWidget {
  const AttendanceHistoryBody({
    Key? key,
    required this.employee,
    required this.days,
    this.monthlySummary,
    this.headerExtra,
  }) : super(key: key);

  final EmployeeAttendanceHead employee;
  final List<EmployeeAttendanceDay> days;
  final EmployeeAttendanceMonthlySummary? monthlySummary;
  final Widget? headerExtra;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        if (headerExtra != null) headerExtra!,
        if (monthlySummary != null) ...[
          Card(
            margin: EdgeInsets.only(bottom: 12.h),
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'monthlySummaryTitle'.tr,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6.h),
                  _attendanceHistoryRow(
                    context,
                    'rangeLabel'.tr,
                    '${monthlySummary!.rangeFrom ?? '—'} → ${monthlySummary!.rangeTo ?? '—'}',
                  ),
                  _attendanceHistoryRow(
                    context,
                    'workedHoursLabel'.tr,
                    monthlySummary!.rangeWorkedHours ?? '—',
                  ),
                  _attendanceHistoryRow(
                    context,
                    'requiredHoursLabel'.tr,
                    monthlySummary!.rangeRequiredHours ?? '—',
                  ),
                  _attendanceHistoryRow(
                    context,
                    'overtimeHoursLabel'.tr,
                    monthlySummary!.rangeOvertimeHours ?? '—',
                  ),
                  _attendanceHistoryRow(
                    context,
                    'totalSalaryLabel'.tr,
                    monthlySummary!.rangeTotalSalary ?? '—',
                  ),
                ],
              ),
            ),
          ),
        ],
        if (employee.startWorkTime != null &&
            employee.startWorkTime!.isNotEmpty) ...[
          Text(
            '${'scheduledStart'.tr}: ${employee.startWorkTime}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 4.h),
        ],
        if (employee.numberOfWorkHours != null &&
            employee.numberOfWorkHours!.isNotEmpty) ...[
          Text(
            '${'expectedDailyHours'.tr}: ${employee.numberOfWorkHours}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: 16.h),
        ],
        ...days.map((d) => AttendanceHistoryDayCard(day: d)),
      ],
    );
  }
}

class AttendanceHistoryDayCard extends StatelessWidget {
  const AttendanceHistoryDayCard({Key? key, required this.day})
      : super(key: key);

  final EmployeeAttendanceDay day;

  @override
  Widget build(BuildContext context) {
    final dateStr = day.date;
    final df = DateFormat('yyyy-MM-dd');
    DateTime? date;
    try {
      date = df.parse(dateStr);
    } catch (_) {}

    final title = date != null
        ? DateFormat('EEEE, d MMM yyyy', Get.locale?.toString()).format(date)
        : dateStr;

    final onTime = day.onTime;
    final onTimeLabel =
        onTime == null ? '—' : (onTime ? 'onTimeYes'.tr : 'onTimeNo'.tr);

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${AttendanceHistoryController.formatMinutes(day.workedMinutes)} · ${'awayMinutesLabel'.tr}: ${AttendanceHistoryController.formatMinutes(day.awayMinutes)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _attendanceHistoryRow(
                  context,
                  'workedTodayLabel'.tr,
                  AttendanceHistoryController.formatMinutes(day.workedMinutes),
                ),
                if (day.workedHours != null ||
                    day.requiredHours != null ||
                    day.normalHours != null ||
                    day.overtimeHours != null) ...[
                  SizedBox(height: 6.h),
                  Text(
                    'contractOvertimeTitle'.tr,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6.h),
                  if (day.workedHours != null)
                    _attendanceHistoryRow(
                      context,
                      'workedHoursLabel'.tr,
                      day.workedHours!,
                    ),
                  if (day.requiredHours != null)
                    _attendanceHistoryRow(
                      context,
                      'requiredHoursLabel'.tr,
                      day.requiredHours!,
                    ),
                  if (day.normalHours != null)
                    _attendanceHistoryRow(
                      context,
                      'normalHoursLabel'.tr,
                      day.normalHours!,
                    ),
                  if (day.overtimeHours != null)
                    _attendanceHistoryRow(
                      context,
                      'overtimeHoursLabel'.tr,
                      day.overtimeHours!,
                    ),
                  if (day.totalSalary != null) ...[
                    _attendanceHistoryRow(
                      context,
                      'totalSalaryLabel'.tr,
                      day.totalSalary!,
                    ),
                  ],
                ],
                _attendanceHistoryRow(
                  context,
                  'awayMinutesLabel'.tr,
                  AttendanceHistoryController.formatMinutes(day.awayMinutes),
                ),
                _attendanceHistoryRow(
                  context,
                  'expectedWorkLabel'.tr,
                  AttendanceHistoryController.formatMinutes(
                      day.expectedWorkMinutes),
                ),
                _attendanceHistoryRow(
                  context,
                  'overtimeLabel'.tr,
                  AttendanceHistoryController.formatMinutes(day.overtimeMinutes),
                ),
                _attendanceHistoryRow(context, 'onTimeLabel'.tr, onTimeLabel),
                _attendanceHistoryRow(
                  context,
                  'currentlyInBuilding'.tr,
                  day.currentlyIn ? 'yes'.tr : 'noLabel'.tr,
                ),
                if (day.firstCheckIn != null)
                  _attendanceHistoryRow(
                    context,
                    'firstCheckInLabel'.tr,
                    DateFormat('HH:mm').format(day.firstCheckIn!.toLocal()),
                  ),
                if (day.lastCheckOut != null)
                  _attendanceHistoryRow(
                    context,
                    'lastCheckOutLabel'.tr,
                    DateFormat('HH:mm').format(day.lastCheckOut!.toLocal()),
                  ),
                SizedBox(height: 8.h),
                Text(
                  'segmentsTitle'.tr,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6.h),
                ...day.segments.map((s) {
                  final open = s.open;
                  final cin = s.checkInAt;
                  final cout = s.checkOutAt;
                  final wm = s.workedMinutes;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Text(
                      open
                          ? '${'attendanceCheckIn'.tr}: ${cin != null ? DateFormat('HH:mm').format(cin.toLocal()) : '—'} → ${'stillInside'.tr}'
                          : '${'attendanceCheckIn'.tr}: ${cin != null ? DateFormat('HH:mm').format(cin.toLocal()) : '—'} → ${'attendanceCheckOut'.tr}: ${cout != null ? DateFormat('HH:mm').format(cout.toLocal()) : '—'} (${wm != null ? AttendanceHistoryController.formatMinutes(wm) : '—'})',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }),
                SizedBox(height: 8.h),
                Text(
                  'scansLogTitle'.tr,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6.h),
                ...day.scans.map((row) {
                  final at = row.at;
                  final dir = row.direction;
                  final dirLabel = dir == 'in'
                      ? 'scanDirectionIn'.tr
                      : 'scanDirectionOut'.tr;
                  return Text(
                    '${DateFormat('yyyy-MM-dd HH:mm').format(at.toLocal())} — $dirLabel',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _attendanceHistoryRow(
    BuildContext context, String label, String value) {
  return Padding(
    padding: EdgeInsets.only(bottom: 6.h),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    ),
  );
}
