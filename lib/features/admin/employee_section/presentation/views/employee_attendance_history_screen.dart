import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/employee_attendance_history_model.dart';
import '../controllers/attendance_history_controller.dart';
import '../widgets/attendance_history_body.dart';

Future<void> _showEditDayDialog(
  BuildContext context,
  AttendanceHistoryController controller,
  EmployeeAttendanceDay day,
) async {
  if (!day.canEditDay) return;

  TimeOfDay parseTime(DateTime? dt, TimeOfDay fallback) {
    if (dt == null) return fallback;
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
  }

  final dateParts = day.date.split('-');
  final baseDate = DateTime(
    int.parse(dateParts[0]),
    int.parse(dateParts[1]),
    int.parse(dateParts[2]),
  );

  var checkInTime =
      parseTime(day.firstCheckIn, const TimeOfDay(hour: 9, minute: 0));
  var checkOutTime =
      parseTime(day.lastCheckOut, const TimeOfDay(hour: 17, minute: 0));
  var hasCheckout = day.lastCheckOut != null;

  final ok = await Get.dialog<bool>(
    StatefulBuilder(
      builder: (ctx, setState) {
        return AlertDialog(
          title: Text('editAttendanceDay'.tr),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('attendanceCheckIn'.tr),
                  subtitle: Text(checkInTime.format(ctx)),
                  trailing: const Icon(Icons.schedule),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: checkInTime,
                    );
                    if (picked != null) {
                      setState(() => checkInTime = picked);
                    }
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('hasCheckout'.tr),
                  value: hasCheckout,
                  onChanged: (v) => setState(() => hasCheckout = v),
                ),
                if (hasCheckout)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('attendanceCheckOut'.tr),
                    subtitle: Text(checkOutTime.format(ctx)),
                    trailing: const Icon(Icons.schedule),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: checkOutTime,
                      );
                      if (picked != null) {
                        setState(() => checkOutTime = picked);
                      }
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('cancel'.tr),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: Text('save'.tr),
            ),
          ],
        );
      },
    ),
  );

  if (ok != true) return;

  DateTime merge(TimeOfDay t) => DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        t.hour,
        t.minute,
      );

  await controller.updateAttendanceDay(
    workDate: day.date,
    checkInAt: merge(checkInTime),
    checkOutAt: hasCheckout ? merge(checkOutTime) : null,
  );
}

Future<void> _showAddDayDialog(
  BuildContext context,
  AttendanceHistoryController controller,
) async {
  final now = DateTime.now();
  final occupiedDates = (controller.result.value?.days ?? [])
      .where(
        (day) =>
            day.firstCheckIn != null ||
            day.lastCheckOut != null ||
            day.segments.isNotEmpty ||
            day.workedMinutes > 0 ||
            day.attendanceStatus == 'present' ||
            day.attendanceStatus == 'present_on_weekly_day_off',
      )
      .map((day) => day.date)
      .toSet();

  String fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool isAvailableDate(DateTime d) => !occupiedDates.contains(fmtDate(d));

  DateTime firstAvailableDate() {
    final start = DateTime(now.year, now.month, now.day);
    for (var i = 0; i < 370; i++) {
      final candidate = start.add(Duration(days: i));
      if (isAvailableDate(candidate)) return candidate;
    }
    return start;
  }

  final modalBg = const Color(0xFFF3F4F6);
  final fieldBg = const Color(0xFFE9EEF2);
  final textColor = const Color(0xFF1F2937);
  final mutedText = const Color(0xFF5F6B7A);
  final selectedBg = const Color(0xFFD3DAE2);
  final accent = AppColors.operationalNavy;

  var selectedDate = isAvailableDate(now)
      ? DateTime(now.year, now.month, now.day)
      : firstAvailableDate();
  var checkInTime = const TimeOfDay(hour: 9, minute: 0);
  var checkOutTime = const TimeOfDay(hour: 17, minute: 0);
  var hasCheckout = true;

  ThemeData pickerTheme(ThemeData base) => base.copyWith(
        colorScheme: ColorScheme.light(
          primary: selectedBg,
          onPrimary: textColor,
          surface: modalBg,
          onSurface: textColor,
          secondary: accent,
          onSecondary: textColor,
        ),
        dialogTheme: DialogThemeData(backgroundColor: modalBg),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: accent),
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: modalBg,
          dialBackgroundColor: fieldBg,
          dialHandColor: accent,
          dialTextColor: textColor,
          dayPeriodTextColor: textColor,
          hourMinuteColor: fieldBg,
          hourMinuteTextColor: textColor,
          helpTextStyle: TextStyle(color: textColor),
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: modalBg,
          headerBackgroundColor: fieldBg,
          headerForegroundColor: textColor,
          dayForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return mutedText;
            return textColor;
          }),
          dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return selectedBg;
            return null;
          }),
          todayForegroundColor: WidgetStateProperty.all(textColor),
          todayBackgroundColor: WidgetStateProperty.all(fieldBg),
        ),
      );

  final ok = await Get.dialog<bool>(
    StatefulBuilder(
      builder: (ctx, setState) {
        return AlertDialog(
          backgroundColor: modalBg,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'addAttendanceDay'.tr,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SingleChildScrollView(
            child: Theme(
              data: Theme.of(ctx).copyWith(
                listTileTheme: ListTileThemeData(
                  textColor: textColor,
                  titleTextStyle: TextStyle(
                    color: textColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  subtitleTextStyle: TextStyle(
                    color: mutedText,
                    fontSize: 12.sp,
                  ),
                  iconColor: accent,
                ),
                switchTheme: SwitchThemeData(
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return accent;
                    return mutedText;
                  }),
                  trackColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return selectedBg;
                    }
                    return fieldBg;
                  }),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('attendanceDayDate'.tr),
                    subtitle: Text(fmtDate(selectedDate)),
                    trailing: const Icon(Icons.event_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        firstDate: DateTime(now.year - 5),
                        lastDate: DateTime(now.year + 1, 12, 31),
                        initialDate: selectedDate,
                        selectableDayPredicate: isAvailableDate,
                        builder: (pickerContext, child) {
                          return Theme(
                            data: pickerTheme(Theme.of(pickerContext)),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate =
                              DateTime(picked.year, picked.month, picked.day);
                        });
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('attendanceCheckIn'.tr),
                    subtitle: Text(checkInTime.format(ctx)),
                    trailing: const Icon(Icons.schedule),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: checkInTime,
                        builder: (pickerContext, child) {
                          return Theme(
                            data: pickerTheme(Theme.of(pickerContext)),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() => checkInTime = picked);
                      }
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('hasCheckout'.tr),
                    value: hasCheckout,
                    onChanged: (v) => setState(() => hasCheckout = v),
                  ),
                  if (hasCheckout)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('attendanceCheckOut'.tr),
                      subtitle: Text(checkOutTime.format(ctx)),
                      trailing: const Icon(Icons.schedule),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: checkOutTime,
                          builder: (pickerContext, child) {
                            return Theme(
                              data: pickerTheme(Theme.of(pickerContext)),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() => checkOutTime = picked);
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              style: TextButton.styleFrom(foregroundColor: mutedText),
              child: Text('cancel'.tr),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: accent),
              child: Text('save'.tr),
            ),
          ],
        );
      },
    ),
  );

  if (ok != true) return;

  DateTime merge(TimeOfDay t) => DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        t.hour,
        t.minute,
      );

  await controller.updateAttendanceDay(
    workDate:
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
    checkInAt: merge(checkInTime),
    checkOutAt: hasCheckout ? merge(checkOutTime) : null,
  );
}

Future<void> _showWeeklyOffImportDialog(
  BuildContext context,
  AttendanceHistoryController controller,
) async {
  await controller.loadWeeklyOffImportCandidates();
  if (!context.mounted) return;

  String timeLabel(DateTime? dt) {
    if (dt == null) return '-';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  await Get.dialog<void>(
    AlertDialog(
      title: Text('weeklyOffImportsTitle'.tr),
      content: SizedBox(
        width: 520.w,
        child: Obx(() {
          if (controller.isWeeklyOffImportLoading.value) {
            return SizedBox(
              height: 120.h,
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          final days = controller.weeklyOffImportCandidates;
          if (days.isEmpty) {
            return SizedBox(
              height: 110.h,
              child: Center(
                child: Text(
                  'weeklyOffImportsEmpty'.tr,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 420.h),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: days.length,
              separatorBuilder: (_, __) => Divider(height: 1.h),
              itemBuilder: (ctx, index) {
                final day = days[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.event_available_outlined,
                    color: AppColors.primaryColor,
                  ),
                  title: Text(day.date),
                  subtitle: Text(
                    '${'attendanceCheckIn'.tr}: ${timeLabel(day.firstScanAt)}  •  '
                    '${'attendanceCheckOut'.tr}: ${timeLabel(day.lastScanAt)}  •  '
                    '${day.logsCount} ${'fingerprintLogs'.tr}',
                  ),
                  trailing: Obx(() {
                    final loading =
                        controller.importingWeeklyOffDate.value == day.date;
                    return TextButton.icon(
                      onPressed: loading
                          ? null
                          : () async {
                              await controller
                                  .importWeeklyOffAttendanceDay(day.date);
                            },
                      icon: loading
                          ? SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.download_done_outlined),
                      label: Text('importAttendanceDay'.tr),
                    );
                  }),
                );
              },
            ),
          );
        }),
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

class EmployeeAttendanceHistoryScreen
    extends GetView<AttendanceHistoryController> {
  const EmployeeAttendanceHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final pageBg = isDark ? AppColors.darkColor : const Color(0xFFF5F5F5);
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          controller.reportMode
              ? 'تقرير دوام ${controller.employeeName}'
              : (controller.employeeName.isNotEmpty
                  ? controller.employeeName
                  : 'employeeAttendanceHistory'.tr),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (!controller.reportMode)
            IconButton(
              tooltip: 'addAttendanceDay'.tr,
              onPressed: () => _showAddDayDialog(context, controller),
              icon: const Icon(
                Icons.add_task_outlined,
                color: AppColors.primaryColor,
              ),
            ),
          if (!controller.reportMode)
            IconButton(
              tooltip: 'weeklyOffImportsTitle'.tr,
              onPressed: () => _showWeeklyOffImportDialog(context, controller),
              icon: const Icon(
                Icons.event_repeat_outlined,
                color: AppColors.primaryColor,
              ),
            ),
          Obx(() {
            final ready = controller.result.value != null &&
                controller.result.value!.days.isNotEmpty;
            final loading = controller.isExporting.value;
            return PopupMenuButton<String>(
              tooltip: 'attendanceReportAction'.tr,
              enabled: ready && !loading,
              icon: loading
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: AppColors.primaryColor,
                    ),
              onSelected: (value) async {
                if (value == 'share') {
                  await controller.exportPdfShare();
                } else if (value == 'save') {
                  await controller.exportPdfSaveAndOpen();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'share',
                  child: Text('exportPdfShare'.tr),
                ),
                PopupMenuItem(
                  value: 'save',
                  child: Text('exportPdfSave'.tr),
                ),
              ],
            );
          }),
          SizedBox(width: 6.w),
        ],
      ),
      floatingActionButton: controller.reportMode
          ? null
          : Obx(() {
              if (!controller.canManualCheckoutToday) {
                return const SizedBox.shrink();
              }
              final loading = controller.isCheckoutLoading.value;
              return FloatingActionButton.extended(
                onPressed: loading
                    ? null
                    : () async {
                        final ok = await Get.dialog<bool>(
                          AlertDialog(
                            title: Text('manualCheckout'.tr),
                            content: Text('manualCheckoutConfirm'.tr),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(result: false),
                                child: Text('cancel'.tr),
                              ),
                              TextButton(
                                onPressed: () => Get.back(result: true),
                                child: Text('confirm'.tr),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await controller.manualCheckout();
                        }
                      },
                icon: loading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout),
                label: Text('manualCheckout'.tr),
              );
            }),
      body: Column(
        children: [
          // ── منتقي السنة والشهر ──
          _MonthYearPicker(controller: controller),
          // ── المحتوى ──
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = controller.result.value;
              if (data == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy,
                          size: 64.sp, color: Colors.grey.shade400),
                      SizedBox(height: 12.h),
                      Text(
                        'noData'.tr,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              final hasContent = data.days.isNotEmpty ||
                  data.monthlySummary != null ||
                  controller.includesToday;
              if (!hasContent) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy,
                          size: 64.sp, color: Colors.grey.shade400),
                      SizedBox(height: 12.h),
                      Text(
                        'noData'.tr,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              final head = data.employee;
              if (controller.reportMode) {
                return _EmployeeAttendanceReportPreview(
                  result: data,
                  periodLabel: controller.periodLabel,
                  isDark: isDark,
                );
              }
              return AttendanceHistoryBody(
                employee: head,
                monthlySummary: data.monthlySummary,
                days: data.days,
                showTodaySummary: controller.includesToday,
                showAdminEdit: true,
                onEditDay: (day) =>
                    _showEditDayDialog(context, controller, day),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _EmployeeAttendanceReportPreview extends StatelessWidget {
  const _EmployeeAttendanceReportPreview({
    required this.result,
    required this.periodLabel,
    required this.isDark,
  });

  final EmployeeAttendanceHistoryResult result;
  final String periodLabel;
  final bool isDark;

  static String _time(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final h = hour12.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final marker = local.hour < 12 ? 'صباحاً' : 'مساءً';
    return '$h:$m $marker';
  }

  static String _dateWithDay(String value) {
    final names = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    try {
      final date = DateTime.parse(value);
      return '${names[date.weekday - 1]} - $value';
    } catch (_) {
      return value;
    }
  }

  static String _dayWorkLabel(EmployeeAttendanceDay day) {
    final holidayNotice = day.attendanceStatus == 'present_on_weekly_day_off'
        ? (day.attendanceStatusLabel ?? 'حضور في يوم عطلة رسمية')
        : null;

    if (day.segments.isNotEmpty) {
      final workedSegments = day.segments.map((segment) {
        final from = _time(segment.checkInAt);
        final to = segment.open ? 'داخل العمل' : _time(segment.checkOutAt);
        return '$from - $to';
      }).join('\n');

      return holidayNotice == null
          ? workedSegments
          : '$workedSegments\n$holidayNotice';
    }
    if (day.firstCheckIn != null || day.lastCheckOut != null) {
      final workedTime =
          '${_time(day.firstCheckIn)} - ${day.currentlyIn ? 'داخل العمل' : _time(day.lastCheckOut)}';

      return holidayNotice == null ? workedTime : '$workedTime\n$holidayNotice';
    }
    return day.attendanceStatusLabel ??
        (day.expectedWorkMinutes <= 0 ? 'عطلة رسمية' : 'عدم حضور');
  }

  static String _hoursFromMinutes(int minutes) {
    return (minutes / 60).toStringAsFixed(2);
  }

  static String _money(String? value) {
    final n = double.tryParse(value ?? '');
    if (n == null) return value?.isNotEmpty == true ? value! : '0.00';
    return n.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final summary = result.monthlySummary;
    final workedTotal = summary?.rangeWorkedHours ??
        summary?.monthlyWorkedHours ??
        _hoursFromMinutes(
          result.days.fold<int>(0, (sum, day) => sum + day.workedMinutes),
        );
    final requiredTotal = summary?.rangeRequiredHours ??
        summary?.monthlyRequiredHours ??
        _hoursFromMinutes(
          result.days.fold<int>(
            0,
            (sum, day) => sum + day.expectedWorkMinutes,
          ),
        );
    final salaryTotal = _money(summary?.rangeTotalSalary);

    final bg = isDark ? AppColors.customGreyColor4 : Colors.white;
    final border = isDark ? Colors.white12 : const Color(0xFFE1E5EE);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final muted = isDark ? Colors.white70 : const Color(0xFF6B7280);

    final rows = result.days.map((day) {
      return DataRow(
        cells: [
          DataCell(Text(_dateWithDay(day.date))),
          DataCell(Text(_dayWorkLabel(day))),
          DataCell(
              Text(day.workedHours ?? _hoursFromMinutes(day.workedMinutes))),
          DataCell(Text(
              day.requiredHours ?? _hoursFromMinutes(day.expectedWorkMinutes))),
          DataCell(Text(_money(day.totalSalary))),
        ],
      );
    }).toList()
      ..add(
        DataRow(
          color: WidgetStateProperty.resolveWith(
            (_) => AppColors.primaryColor.withValues(alpha: 0.08),
          ),
          cells: [
            DataCell(Text(
              'المجموع',
              style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
            )),
            const DataCell(Text('-')),
            DataCell(Text(
              workedTotal,
              style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
            )),
            DataCell(Text(
              requiredTotal,
              style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
            )),
            DataCell(Text(
              salaryTotal,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.primaryColor,
              ),
            )),
          ],
        ),
      );

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.employee.name ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 10.w,
                  runSpacing: 6.h,
                  children: [
                    _MetaChip(
                      label: 'الفترة',
                      value: periodLabel,
                      color: muted,
                    ),
                    _MetaChip(
                      label: 'سعر ساعة العمل',
                      value: _money(result.employee.hourWorkPrice),
                      color: muted,
                    ),
                    _MetaChip(
                      label: 'أيام التقرير',
                      value: result.days.length.toString(),
                      color: muted,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.sizeOf(context).width - 28.w,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: border),
                ),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.resolveWith(
                    (_) => AppColors.primaryColor,
                  ),
                  headingTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                  dataTextStyle: TextStyle(color: textColor),
                  dividerThickness: 0.8,
                  columnSpacing: 18.w,
                  horizontalMargin: 10.w,
                  columns: const [
                    DataColumn(label: Text('اليوم والتاريخ')),
                    DataColumn(label: Text('الدوام')),
                    DataColumn(label: Text('الصافي')),
                    DataColumn(label: Text('المطلوب')),
                    DataColumn(label: Text('الحساب')),
                  ],
                  rows: rows,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// ودجة منتقي السنة والشهر
// ────────────────────────────────────────────────────────────────
class _MonthYearPicker extends StatelessWidget {
  const _MonthYearPicker({required this.controller});
  final AttendanceHistoryController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Obx(() {
        final year = controller.selectedYear.value;
        final month = controller.selectedMonth.value;
        final isCustom = controller.isCustomRange;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // ── السنة ──
                Expanded(
                  child: _PickerButton(
                    label: year.toString(),
                    icon: Icons.calendar_today_outlined,
                    onTap: () => _pickYear(context),
                  ),
                ),
                SizedBox(width: 8.w),
                // ── الشهر ──
                Expanded(
                  flex: 2,
                  child: _PickerButton(
                    label: AttendanceHistoryController.monthNames[month - 1],
                    icon: Icons.date_range_outlined,
                    onTap: () => _pickMonth(context, year),
                  ),
                ),
                SizedBox(width: 8.w),
                // ── زر التحديث ──
                SizedBox(
                  width: 42.w,
                  child: IconButton(
                    onPressed: controller.load,
                    icon: const Icon(Icons.refresh),
                    color: AppColors.primaryColor,
                    tooltip: 'refresh'.tr,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            // ── فلتر مدى الأيام (من / إلى) ──
            Row(
              children: [
                Expanded(
                  child: _PickerButton(
                    label: isCustom
                        ? '${_fmtDate(controller.customFrom.value!)} → ${_fmtDate(controller.customTo.value!)}'
                        : 'filterByDateRange'.tr,
                    icon: Icons.filter_alt_outlined,
                    onTap: () => _pickDateRange(context),
                  ),
                ),
                if (isCustom) ...[
                  SizedBox(width: 8.w),
                  SizedBox(
                    width: 42.w,
                    child: IconButton(
                      onPressed: controller.clearDateRange,
                      icon: const Icon(Icons.clear),
                      color: Colors.red.shade400,
                      tooltip: 'clearDateFilter'.tr,
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      }),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final initialRange = controller.isCustomRange
        ? DateTimeRange(
            start: controller.customFrom.value!,
            end: controller.customTo.value!,
          )
        : null;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initialRange,
      helpText: 'filterByDateRange'.tr,
      saveText: 'confirm'.tr,
    );
    if (picked != null) {
      controller.applyDateRange(picked.start, picked.end);
    }
  }

  void _pickYear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('اختر السنة'),
        children: controller.availableYears.map((y) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              controller.changeMonth(y, controller.selectedMonth.value);
            },
            child: Text(
              y.toString(),
              style: TextStyle(
                fontWeight: controller.selectedYear.value == y
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: controller.selectedYear.value == y
                    ? AppColors.primaryColor
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _pickMonth(BuildContext context, int year) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text('اختر الشهر — $year'),
        children: List.generate(12, (i) {
          final m = i + 1;
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              controller.changeMonth(year, m);
            },
            child: Text(
              AttendanceHistoryController.monthNames[i],
              style: TextStyle(
                fontWeight: controller.selectedMonth.value == m
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: controller.selectedMonth.value == m
                    ? AppColors.primaryColor
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade300, width: 1),
          borderRadius: BorderRadius.circular(8.r),
          color: isDark ? Colors.white10 : Colors.grey.shade50,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16.sp, color: AppColors.primaryColor),
            SizedBox(width: 6.w),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF222222),
              ),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.arrow_drop_down,
                size: 18.sp, color: AppColors.primaryColor),
          ],
        ),
      ),
    );
  }
}
