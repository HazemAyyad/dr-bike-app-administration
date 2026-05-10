import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/attendance_report_model.dart';
import '../../domain/entities/working_times_entity.dart';
import '../models/attendance_report_navigation_args.dart';

/// من تبويب الدوام: يفتح التقرير. من شاشة التقرير: [onApplyInPlace] يطبّق الفلتر بدون تنقل جديد.
Future<void> showAttendanceReportFilterDialog(
  BuildContext context, {
  required List<WorkingTimesEntity> employees,
  AttendanceReportArgs? initialFilters,
  void Function(AttendanceReportArgs)? onApplyInPlace,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _AttendanceReportFilterDialogContent(
      employees: employees,
      initialFilters: initialFilters,
      onApplyInPlace: onApplyInPlace,
    ),
  );
}

class _AttendanceReportFilterDialogContent extends StatefulWidget {
  const _AttendanceReportFilterDialogContent({
    required this.employees,
    this.initialFilters,
    this.onApplyInPlace,
  });

  final List<WorkingTimesEntity> employees;
  final AttendanceReportArgs? initialFilters;
  final void Function(AttendanceReportArgs)? onApplyInPlace;

  @override
  State<_AttendanceReportFilterDialogContent> createState() =>
      _AttendanceReportFilterDialogContentState();
}

class _AttendanceReportFilterDialogContentState
    extends State<_AttendanceReportFilterDialogContent> {
  static const _types = ['daily', 'weekly', 'monthly'];

  late String _reportType;
  late int _month;
  late int _year;
  late int _day;
  late int _week;
  late bool _allEmployees;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final i = widget.initialFilters;

    if (i != null) {
      _reportType = i.reportType;
      _month = i.month;
      _year = i.year;
      final dim = DateTime(i.year, i.month + 1, 0).day;
      _day = (i.day ?? now.day).clamp(1, dim);
      final maxW = math.max(1, (dim / 7).ceil());
      _week = (i.week ?? 1).clamp(1, maxW);
      _allEmployees = i.allEmployees;
      if (widget.employees.isEmpty && !_allEmployees) {
        _allEmployees = true;
      }
      _selectedIds
        ..clear()
        ..addAll(i.employeeIds);
    } else {
      _reportType = 'monthly';
      _month = now.month;
      _year = now.year;
      _day = now.day;
      _week = 1;
      _allEmployees = true;
    }
  }

  void _reset() {
    final now = DateTime.now();
    setState(() {
      _reportType = 'monthly';
      _month = now.month;
      _year = now.year;
      _day = now.day;
      _week = 1;
      _allEmployees = true;
      _selectedIds.clear();
    });
  }

  int _daysInMonth() => DateTime(_year, _month + 1, 0).day;

  /// كتل 7 أيام تبدأ من أول يوم بالشهر (الأسبوع الأخير قد يكون أقصر).
  int _maxWeekBlocksInMonth() {
    final d = _daysInMonth();
    return math.max(1, (d / 7).ceil());
  }

  void _clampWeekToMonth() {
    final maxW = _maxWeekBlocksInMonth();
    if (_week > maxW) {
      _week = maxW;
    }
    if (_week < 1) {
      _week = 1;
    }
  }

  List<int> _yearOptions() {
    final y = DateTime.now().year;
    return List.generate(6, (i) => y - i);
  }

  void _apply() {
    if (!_allEmployees && _selectedIds.isEmpty) {
      Get.snackbar(
        'warning'.tr,
        'attendanceReportSelectEmployeeWarning'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (_reportType == 'daily' && (_day < 1 || _day > _daysInMonth())) {
      Get.snackbar(
        'error'.tr,
        'attendanceReportInvalidDay'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final args = AttendanceReportArgs(
      reportType: _reportType,
      month: _month,
      year: _year,
      day: _reportType == 'daily' ? _day : null,
      week: _reportType == 'weekly' ? _week : null,
      allEmployees: _allEmployees,
      employeeIds:
          _allEmployees ? const <int>[] : (_selectedIds.toList()..sort()),
    );

    if (widget.onApplyInPlace != null) {
      Navigator.of(context).pop();
      widget.onApplyInPlace!(args);
      return;
    }

    Navigator.of(context).pop();
    Get.toNamed(
      AppRoutes.ATTENDANCEREPORTSCREEN,
      arguments: AttendanceReportNavigationArgs(
        reportFilters: args,
        employees: widget.employees,
      ),
    );
  }

  String _typeLabel(String code) {
    switch (code) {
      case 'daily':
        return 'reportTypeDaily'.tr;
      case 'weekly':
        return 'reportTypeWeekly'.tr;
      case 'monthly':
        return 'reportTypeMonthly'.tr;
      default:
        return code;
    }
  }

  String _monthLabel(int m) =>
      DateFormat.MMMM(Get.locale.toString()).format(DateTime(2000, m, 1));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ThemeService.isDark.value;
    final inplace = widget.onApplyInPlace != null;
    final chipLabelStyle = theme.textTheme.bodyMedium?.copyWith(
      color: isDark ? Colors.white : const Color(0xFF222222),
      fontWeight: FontWeight.w600,
    );

    return AlertDialog(
      backgroundColor:
          isDark ? AppColors.customGreyColor4 : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      title: Text(
        'attendanceReportFiltersTitle'.tr,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF1F1F1F),
        ),
      ),
      contentPadding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('attendanceReportTypeLabel'.tr,
                  style: theme.textTheme.titleSmall),
              SizedBox(height: 6.h),
              Wrap(
                spacing: 8.w,
                children: _types.map((t) {
                  final sel = _reportType == t;
                  return FilterChip(
                    label: Text(_typeLabel(t)),
                    selected: sel,
                    selectedColor:
                        AppColors.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primaryColor,
                    labelStyle: chipLabelStyle,
                    onSelected: (_) => setState(() {
                      _reportType = t;
                      if (t == 'weekly') {
                        _clampWeekToMonth();
                      }
                    }),
                  );
                }).toList(),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'monthLabel'.tr,
                        isDense: true,
                      ),
                      value: _month,
                      items: List.generate(
                        12,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text(_monthLabel(i + 1)),
                        ),
                      ),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _month = v;
                          _day = _day.clamp(1, _daysInMonth());
                          _clampWeekToMonth();
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'yearLabel'.tr,
                        isDense: true,
                      ),
                      value: _year,
                      items: _yearOptions()
                          .map(
                            (y) => DropdownMenuItem(
                              value: y,
                              child: Text('$y'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _year = v;
                          _day = _day.clamp(1, _daysInMonth());
                          _clampWeekToMonth();
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (_reportType == 'daily') ...[
                SizedBox(height: 10.h),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'dayLabel'.tr,
                    isDense: true,
                  ),
                  value: _day.clamp(1, _daysInMonth()),
                  items: List.generate(
                    _daysInMonth(),
                    (i) =>
                        DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                  ),
                  onChanged: (v) => setState(() => _day = v ?? _day),
                ),
              ],
              if (_reportType == 'weekly') ...[
                SizedBox(height: 10.h),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'weekOfMonthLabel'.tr,
                    isDense: true,
                    helperText:
                        '${'weekOfMonthHint'.tr} (${_maxWeekBlocksInMonth()} ${'weekBlocksCountSuffix'.tr})',
                  ),
                  value: math.min(_week, _maxWeekBlocksInMonth()),
                  items: List.generate(
                    _maxWeekBlocksInMonth(),
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('${i + 1}'),
                    ),
                  ),
                  onChanged: (v) => setState(() {
                    _week = v ?? _week;
                    _clampWeekToMonth();
                  }),
                ),
              ],
              SizedBox(height: 12.h),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('allEmployeesToggle'.tr),
                value: _allEmployees,
                onChanged: (v) => setState(() => _allEmployees = v ?? true),
              ),
              if (!_allEmployees) ...[
                Text('pickEmployeesHint'.tr, style: theme.textTheme.bodySmall),
                SizedBox(height: 6.h),
                if (widget.employees.isEmpty)
                  Text(
                    'attendanceReportNoEmployeeListHint'.tr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 180.h),
                    child: ListView(
                      shrinkWrap: true,
                      children: widget.employees.map((e) {
                        final checked = _selectedIds.contains(e.id);
                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(e.employeeName,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          value: checked,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selectedIds.add(e.id);
                              } else {
                                _selectedIds.remove(e.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                ),
                onPressed: _apply,
                child: Text(
                  inplace
                      ? 'attendanceReportApplyFiltersButton'.tr
                      : 'generateReportButton'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDark ? Colors.white70 : const Color(0xFF6B6B6B),
                        side: BorderSide(
                          color: isDark ? Colors.white12 : Colors.grey.shade300,
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 10.h),
                      ),
                      child: Text('cancel'.tr),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDark ? Colors.white70 : const Color(0xFF6B6B6B),
                        side: BorderSide(
                          color: isDark ? Colors.white12 : Colors.grey.shade300,
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 10.h),
                      ),
                      child: Text('resetFiltersButton'.tr),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
