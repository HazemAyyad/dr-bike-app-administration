import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/month_year_picker.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/employee_points_log_model.dart';
import '../controllers/employee_points_report_controller.dart';

class EmployeePointsReportScreen
    extends GetView<EmployeePointsReportController> {
  const EmployeePointsReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final pageBg = isDark ? AppColors.darkColor : const Color(0xFFF5F6F8);
    return Scaffold(
      backgroundColor: pageBg,
      appBar: CustomAppBar(
        title: 'pointsReportTitle',
        action: false,
        backgroundColor: pageBg,
        actions: [
          IconButton(
            tooltip: 'refresh'.tr,
            icon: Icon(Icons.refresh_rounded,
                size: 24.sp,
                color: isDark
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor),
            onPressed: controller.runReport,
          ),
        ],
      ),
      body: Column(
        children: [
          _Filters(isDark: isDark),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.report.value == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final report = controller.report.value;
              if (report == null || report.employees.isEmpty) {
                return RefreshIndicator(
                  onRefresh: controller.runReport,
                  child: ListView(
                    children: [
                      SizedBox(height: 100.h),
                      Icon(Icons.analytics_outlined,
                          size: 56.sp, color: AppColors.primaryColor),
                      SizedBox(height: 12.h),
                      Center(
                        child: Text(
                          'pointsReportEmpty'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.runReport,
                child: ListView(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12.w, vertical: 12.h),
                  children: [
                    _TotalsCard(report: report, isDark: isDark),
                    SizedBox(height: 10.h),
                    ...report.employees.map(
                      (row) => Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: _ReportRowCard(
                          row: row,
                          isDark: isDark,
                          isExpanded:
                              controller.expandedRows.contains(row.employeeId),
                          onToggle: () =>
                              controller.toggleExpand(row.employeeId),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<EmployeePointsReportController>();
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 4.h),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(() => _PeriodChip(
                      icon: Icons.calendar_month_rounded,
                      label: 'month'.tr,
                      value: MonthYearPicker.monthLabel(
                          c.selectedMonth.value),
                      onTap: () => _pickMonth(context, c),
                    )),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Obx(() => _PeriodChip(
                      icon: Icons.event_rounded,
                      label: 'year'.tr,
                      value: c.selectedYear.value.toString(),
                      onTap: () => _pickYear(context, c),
                    )),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Obx(() {
            return Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: c.selectedCategoryId.value,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'pointCategoriesTitle'.tr,
                      labelStyle: TextStyle(fontSize: 12.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 12.h),
                      isDense: true,
                    ),
                    items: <DropdownMenuItem<int?>>[
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text('pointCategoryFilterAll'.tr),
                      ),
                      ...c.categories.map(
                        (cat) => DropdownMenuItem<int?>(
                          value: cat.id,
                          child: Text(_categoryDisplayName(cat)),
                        ),
                      ),
                    ],
                    onChanged: c.setCategoryId,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: c.selectedOperationType.value,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText:
                          'pointCategoryOperationType'.tr,
                      labelStyle: TextStyle(fontSize: 12.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 12.h),
                      isDense: true,
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('pointCategoryFilterAll'.tr),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'add',
                        child: Text('pointCategoryFilterAdd'.tr),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'deduct',
                        child: Text('pointCategoryFilterDeduct'.tr),
                      ),
                    ],
                    onChanged: c.setOperationType,
                  ),
                ),
              ],
            );
          }),
          SizedBox(height: 6.h),
          Obx(() => SwitchListTile.adaptive(
                dense: true,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                title: Text('pointsReportIncludeLogs'.tr,
                    style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600)),
                value: c.includeLogs.value,
                onChanged: c.toggleIncludeLogs,
              )),
        ],
      ),
    );
  }

  Future<void> _pickMonth(
      BuildContext context, EmployeePointsReportController c) async {
    final picked = await MonthYearPicker.pickMonth(
      context,
      selected: c.selectedMonth.value,
    );
    if (picked != null) c.updatePeriod(month: picked);
  }

  Future<void> _pickYear(
      BuildContext context, EmployeePointsReportController c) async {
    final picked = await MonthYearPicker.pickYear(
      context,
      selected: c.selectedYear.value,
    );
    if (picked != null) c.updatePeriod(year: picked);
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final accent =
        isDark ? AppColors.primaryColor : AppColors.secondaryColor;
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F23) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(7.w),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, size: 16.sp, color: accent),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white70
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18.sp,
              color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.report, required this.isDark});

  final EmployeePointsReportModel report;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F23) : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'pointsReportTotals'.tr,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              _Total(
                label: 'earnedPoints'.tr,
                value: report.totalEarnedPoints.toString(),
                color: const Color(0xFF16A34A),
              ),
              _Total(
                label: 'deductedPoints'.tr,
                value: report.totalDeductedPoints.toString(),
                color: const Color(0xFFDC2626),
              ),
              _Total(
                label: 'totalNet'.tr,
                value: report.totalNetPoints.toString(),
                color: const Color(0xFF2563EB),
              ),
              _Total(
                label: 'totalReward'.tr,
                value: report.totalRewardAmount,
                color: const Color(0xFFB45309),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: color)),
            SizedBox(height: 2.h),
            Text(label,
                style: TextStyle(
                    color: const Color(0xFF6B7280),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ReportRowCard extends StatelessWidget {
  const _ReportRowCard({
    required this.row,
    required this.isDark,
    required this.isExpanded,
    required this.onToggle,
  });

  final EmployeePointsRowModel row;
  final bool isDark;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.customGreyColor : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE5E7EB);
    final badgeColor =
        _parseHex(row.rewardStatusColor) ?? const Color(0xFF9CA3AF);

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.employeeName ?? '—',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '${row.netPoints} ${'employeePointsBadgeUnit'.tr}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              _Mini('earnedPoints'.tr, row.earnedPoints.toString(),
                  const Color(0xFF16A34A)),
              _Mini('deductedPoints'.tr, row.deductedPoints.toString(),
                  const Color(0xFFDC2626)),
              _Mini('totalReward'.tr, row.rewardAmount,
                  const Color(0xFFB45309)),
            ],
          ),
          SizedBox(height: 6.h),
          if (row.rewardStatusLabel != null &&
              row.rewardStatusLabel!.isNotEmpty)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                children: [
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Text(row.rewardStatusLabel!,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: badgeColor,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ),
          if (row.logs.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: onToggle,
                icon: Icon(
                  isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                ),
                label: Text(
                  isExpanded ? 'collapseLogs'.tr : 'expandLogs'.tr,
                ),
              ),
            ),
            if (isExpanded)
              Column(
                children: row.logs
                    .map((log) => _ReportLogRow(log: log))
                    .toList(),
              ),
          ],
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2.w),
        padding: EdgeInsets.symmetric(vertical: 6.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                    color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 10.sp,
                    color: const Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }
}

class _ReportLogRow extends StatelessWidget {
  const _ReportLogRow({required this.log});

  final EmployeePointsLogModel log;

  @override
  Widget build(BuildContext context) {
    final accent =
        log.isAdd ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final name = (Get.locale?.languageCode == 'ar'
            ? log.categoryNameAr
            : log.categoryNameEn) ??
        log.category;
    return Container(
      margin: EdgeInsets.only(top: 6.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(
            log.isAdd
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            color: accent,
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700)),
                if (log.reason != null && log.reason!.isNotEmpty)
                  Text(log.reason!,
                      style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF6B7280))),
                if (log.pointsDate != null)
                  Text(log.pointsDate!,
                      style: TextStyle(
                          fontSize: 10.sp,
                          color: const Color(0xFF9CA3AF))),
              ],
            ),
          ),
          Text('${log.isAdd ? '+' : '-'}${log.points}',
              style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w900,
                  color: accent)),
        ],
      ),
    );
  }
}

String _categoryDisplayName(EmployeePointCategoryModel cat) {
  final isArabic = Get.locale?.languageCode == 'ar';
  if (isArabic) {
    if (cat.nameAr.isNotEmpty) return cat.nameAr;
    return cat.nameEn ?? cat.code;
  }
  if (cat.nameEn != null && cat.nameEn!.isNotEmpty) return cat.nameEn!;
  return cat.nameAr.isNotEmpty ? cat.nameAr : cat.code;
}

Color? _parseHex(String? input) {
  if (input == null) return null;
  var s = input.trim();
  if (s.isEmpty) return null;
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length == 6) s = 'FF$s';
  if (s.length != 8) return null;
  final value = int.tryParse(s, radix: 16);
  if (value == null) return null;
  return Color(value);
}
