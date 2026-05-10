import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/month_year_picker.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/employee_points_log_model.dart';
import '../controllers/global_employee_points_controller.dart';
import 'employee_points_logs_dialog.dart';

/// Global "نقاط الموظفين" admin screen. Lists every employee with current
/// month points + reward status, and lets admins add/deduct points without
/// entering employee details.
class GlobalEmployeePointsScreen
    extends GetView<GlobalEmployeePointsController> {
  const GlobalEmployeePointsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final pageBg = isDark ? AppColors.darkColor : const Color(0xFFF5F6F8);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: CustomAppBar(
        title: 'globalEmployeePointsTitle',
        action: false,
        backgroundColor: pageBg,
        actions: [
          IconButton(
            tooltip: 'refresh'.tr,
            icon: Icon(
              Icons.refresh_rounded,
              size: 24.sp,
              color: isDark ? AppColors.primaryColor : AppColors.secondaryColor,
            ),
            onPressed: controller.loadRows,
          ),
        ],
      ),
      body: Column(
        children: [
          _Filters(isDark: isDark),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.rows.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.rows.isEmpty) {
                return RefreshIndicator(
                  onRefresh: controller.loadRows,
                  child: ListView(
                    children: [
                      SizedBox(height: 100.h),
                      Icon(Icons.group_outlined,
                          size: 56.sp, color: AppColors.primaryColor),
                      SizedBox(height: 12.h),
                      Center(
                        child: Text(
                          'globalEmployeePointsEmpty'.tr,
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
                onRefresh: controller.loadRows,
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12.w, vertical: 12.h),
                  itemCount: controller.rows.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (_, i) {
                    final row = controller.rows[i];
                    return _EmployeePointsRowCard(
                      row: row,
                      isDark: isDark,
                      onAdd: () => _openMutationDialog(
                          context, row: row, isAdd: true),
                      onDeduct: () => _openMutationDialog(
                          context, row: row, isAdd: false),
                      onLogs: () => _openLogsDialog(context, row: row),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _openMutationDialog(
    BuildContext context, {
    required EmployeePointsRowModel row,
    required bool isAdd,
  }) async {
    await showDialog<bool>(
      context: context,
      builder: (ctx) => _GlobalPointsMutationDialog(
        controller: controller,
        row: row,
        isAdd: isAdd,
      ),
    );
  }

  Future<void> _openLogsDialog(
    BuildContext context, {
    required EmployeePointsRowModel row,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => EmployeePointsLogsDialog(
        employeeId: row.employeeId,
        employeeName: row.employeeName ?? '',
        month: controller.selectedMonth.value,
        year: controller.selectedYear.value,
      ),
    );
  }
}

class _Filters extends StatefulWidget {
  const _Filters({required this.isDark});

  final bool isDark;

  @override
  State<_Filters> createState() => _FiltersState();
}

class _FiltersState extends State<_Filters> {
  late final TextEditingController _searchCtrl;
  late final GlobalEmployeePointsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<GlobalEmployeePointsController>();
    _searchCtrl = TextEditingController(text: controller.searchQuery.value);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 4.h),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'searchEmployee'.tr,
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 0),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: controller.setSearch,
            onChanged: (value) {
              if (value.isEmpty) controller.setSearch('');
            },
          ),
          SizedBox(height: 10.h),
          Obx(() {
            return Row(
              children: [
                Expanded(
                  child: _PeriodChip(
                    icon: Icons.calendar_month_rounded,
                    label: 'month'.tr,
                    value: MonthYearPicker.monthLabel(
                        controller.selectedMonth.value),
                    onTap: () => _pickMonth(context),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _PeriodChip(
                    icon: Icons.event_rounded,
                    label: 'year'.tr,
                    value: controller.selectedYear.value.toString(),
                    onTap: () => _pickYear(context),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Future<void> _pickMonth(BuildContext context) async {
    final picked = await MonthYearPicker.pickMonth(
      context,
      selected: controller.selectedMonth.value,
    );
    if (picked != null) controller.updatePeriod(month: picked);
  }

  Future<void> _pickYear(BuildContext context) async {
    final picked = await MonthYearPicker.pickYear(
      context,
      selected: controller.selectedYear.value,
    );
    if (picked != null) controller.updatePeriod(year: picked);
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

class _EmployeePointsRowCard extends StatelessWidget {
  const _EmployeePointsRowCard({
    required this.row,
    required this.isDark,
    required this.onAdd,
    required this.onDeduct,
    required this.onLogs,
  });

  final EmployeePointsRowModel row;
  final bool isDark;
  final VoidCallback onAdd;
  final VoidCallback onDeduct;
  final VoidCallback onLogs;

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.customGreyColor : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE5E7EB);
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final badgeColor =
        _parseHex(row.rewardStatusColor) ?? const Color(0xFF9CA3AF);

    final hasImage =
        row.employeeImg != null && row.employeeImg!.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor:
                    isDark ? Colors.white12 : const Color(0xFFEEF0F3),
                backgroundImage: hasImage
                    ? NetworkImage(
                        '${EndPoints.baserUrlForImage}${row.employeeImg}')
                    : null,
                child: hasImage
                    ? null
                    : Icon(Icons.person, color: subColor, size: 22.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.employeeName ?? '—',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    _StatusBadge(
                      label: row.rewardStatusLabel ?? 'noRewardStatus'.tr,
                      color: badgeColor,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${row.netPoints} ${'employeePointsBadgeUnit'.tr}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w900,
                        color: badgeColor,
                      ),
                    ),
                    Text(
                      '${row.rewardAmount} ${'currency'.tr}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: subColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              _MiniStat(
                label: 'earnedPoints'.tr,
                value: row.earnedPoints.toString(),
                color: const Color(0xFF16A34A),
                isDark: isDark,
              ),
              SizedBox(width: 8.w),
              _MiniStat(
                label: 'deductedPoints'.tr,
                value: row.deductedPoints.toString(),
                color: const Color(0xFFDC2626),
                isDark: isDark,
              ),
              SizedBox(width: 8.w),
              _MiniStat(
                label: 'totalNet'.tr,
                value: row.netPoints.toString(),
                color: badgeColor,
                isDark: isDark,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('addPointsAction'.tr),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF16A34A),
                    side: const BorderSide(color: Color(0xFF16A34A)),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDeduct,
                  icon: const Icon(Icons.remove, size: 18),
                  label: Text('deductPointsAction'.tr),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFDC2626)),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                tooltip: 'viewLogs'.tr,
                onPressed: onLogs,
                icon: const Icon(Icons.receipt_long_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                color:
                    isDark ? Colors.white70 : const Color(0xFF6B7280),
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlobalPointsMutationDialog extends StatefulWidget {
  const _GlobalPointsMutationDialog({
    required this.controller,
    required this.row,
    required this.isAdd,
  });

  final GlobalEmployeePointsController controller;
  final EmployeePointsRowModel row;
  final bool isAdd;

  @override
  State<_GlobalPointsMutationDialog> createState() =>
      _GlobalPointsMutationDialogState();
}

class _GlobalPointsMutationDialogState
    extends State<_GlobalPointsMutationDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _pointsCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  EmployeePointCategoryModel? _selectedCategory;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _pointsCtrl.dispose();
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isAdd
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);
    final categories = widget.controller.categories
        .where((c) => widget.isAdd ? c.isAdd : c.isDeduct)
        .toList();

    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.isAdd
                          ? Icons.add_circle_outline
                          : Icons.remove_circle_outline,
                      color: accent,
                      size: 22.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        widget.row.employeeName ?? '—',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                if (categories.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Text(
                      'pointCategoriesEmpty'.tr,
                      style: TextStyle(
                        color: const Color(0xFF6B7280),
                        fontSize: 12.sp,
                      ),
                    ),
                  )
                else
                  DropdownButtonFormField<int>(
                    initialValue: _selectedCategory?.id,
                    isExpanded: true,
                    decoration: _decoration('pointsCategory'.tr),
                    items: categories
                        .map(
                          (c) => DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(_categoryDisplayName(c)),
                          ),
                        )
                        .toList(),
                    validator: (v) =>
                        v == null ? 'pointsCategoryRequired'.tr : null,
                    onChanged: (id) {
                      final cat =
                          categories.firstWhere((c) => c.id == id);
                      setState(() {
                        _selectedCategory = cat;
                        _pointsCtrl.text = cat.defaultPoints.toString();
                      });
                    },
                  ),
                SizedBox(height: 10.h),
                TextFormField(
                  controller: _pointsCtrl,
                  keyboardType: TextInputType.number,
                  readOnly: _selectedCategory != null,
                  enabled: _selectedCategory == null,
                  decoration: _decoration('pointsValue'.tr).copyWith(
                    suffixIcon: _selectedCategory != null
                        ? Icon(
                            Icons.lock_outline_rounded,
                            size: 18.sp,
                            color: const Color(0xFF9CA3AF),
                          )
                        : null,
                    helperText: _selectedCategory != null
                        ? 'pointsCategoryAutoFill'.tr
                        : null,
                    helperStyle: TextStyle(
                      fontSize: 10.sp,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  validator: (v) {
                    if (_selectedCategory != null) return null;
                    if (v == null || v.isEmpty) {
                      return 'pointsValueRequired'.tr;
                    }
                    final n = int.tryParse(v.trim());
                    if (n == null || n < 1) return 'pointsValueMin'.tr;
                    return null;
                  },
                ),
                SizedBox(height: 10.h),
                TextFormField(
                  controller: _reasonCtrl,
                  decoration: _decoration('pointsReasonOptional'.tr),
                ),
                SizedBox(height: 10.h),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: _decoration('pointsNotesOptional'.tr),
                ),
                SizedBox(height: 10.h),
                InkWell(
                  borderRadius: BorderRadius.circular(10.r),
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? now,
                      firstDate: DateTime(now.year - 2),
                      lastDate: DateTime(now.year + 1),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration:
                        _decoration('pointsDateOptional'.tr).copyWith(
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      _selectedDate == null
                          ? '—'
                          : '${_selectedDate!.year.toString().padLeft(4, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Obx(() {
                  final loading = widget.controller.isMutating.value;
                  return Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: loading
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: Text('cancel'.tr),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                          onPressed: loading ? null : _submit,
                          child: loading
                              ? SizedBox(
                                  width: 18.w,
                                  height: 18.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text('save'.tr),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final overrideText = _pointsCtrl.text.trim();
    // When a configurable category is selected the points field is locked
    // and we let the backend resolve the value from the category default.
    final overridePoints = _selectedCategory != null
        ? null
        : (overrideText.isEmpty ? null : int.tryParse(overrideText));
    final ok = await widget.controller.mutatePoints(
      employeeId: widget.row.employeeId,
      isAdd: widget.isAdd,
      categoryId: _selectedCategory?.id,
      category: _selectedCategory?.code,
      points: overridePoints,
      reason: _reasonCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      pointsDate: _selectedDate,
    );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
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
