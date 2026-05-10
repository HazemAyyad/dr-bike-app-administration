import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/employee_points_log_model.dart';
import '../controllers/employee_points_controller.dart';

/// Points & Rewards tab body: monthly summary card, filters, logs, action buttons.
class EmployeePointsTab extends StatelessWidget {
  const EmployeePointsTab({Key? key, required this.employeeId})
      : super(key: key);

  final int employeeId;

  EmployeePointsController get _controller =>
      Get.find<EmployeePointsController>();

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final pageBg = isDark ? AppColors.darkColor : const Color(0xFFF7F8FA);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.currentEmployeeId.value != employeeId) {
        _controller.bindEmployee(employeeId);
      }
    });

    return Container(
      color: pageBg,
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _controller.loadMonthlySummary(),
            _controller.loadLogs(reset: true),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryCard(controller: _controller),
              SizedBox(height: 16.h),
              _ActionButtons(controller: _controller),
              SizedBox(height: 20.h),
              _FiltersBar(controller: _controller),
              SizedBox(height: 12.h),
              _LogsList(controller: _controller),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top-level summary card showing earned/deducted/net points and reward.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.controller});

  final EmployeePointsController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final cardColor = isDark ? const Color(0xFF1F1F23) : Colors.white;
    final borderColor =
        isDark ? Colors.white12 : const Color(0xFFE5E7EB);
    final headerColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final secondaryText =
        isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Obx(() {
      final summary = controller.summary.value;
      final loading = controller.isSummaryLoading.value;

      return Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor),
        ),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month_outlined,
                    color: const Color(0xFF374151), size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'currentMonthSummary'.tr,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: headerColor,
                  ),
                ),
                const Spacer(),
                if (loading)
                  SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            _PeriodPills(controller: controller),
            SizedBox(height: 14.h),
            LayoutBuilder(
              builder: (context, constraints) {
                final tile = (constraints.maxWidth - 24.w) / 2;
                return Wrap(
                  spacing: 12.w,
                  runSpacing: 12.h,
                  children: [
                    _SummaryTile(
                      width: tile,
                      label: 'earnedPoints'.tr,
                      value: '${summary?.earnedPoints ?? 0}',
                      accent: const Color(0xFF16A34A),
                      icon: Icons.trending_up_rounded,
                    ),
                    _SummaryTile(
                      width: tile,
                      label: 'deductedPoints'.tr,
                      value: '${summary?.deductedPoints ?? 0}',
                      accent: const Color(0xFFDC2626),
                      icon: Icons.trending_down_rounded,
                    ),
                    _SummaryTile(
                      width: tile,
                      label: 'netPoints'.tr,
                      value: '${summary?.netPoints ?? 0}',
                      accent: const Color(0xFF2563EB),
                      icon: Icons.score_rounded,
                    ),
                    _SummaryTile(
                      width: tile,
                      label: 'rewardAmount'.tr,
                      value: summary?.rewardAmount ?? '0.00',
                      accent: const Color(0xFFB45309),
                      icon: Icons.emoji_events_outlined,
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 10.h),
            Text(
              'finalSalaryFormulaHint'.tr,
              style: TextStyle(fontSize: 11.sp, color: secondaryText),
            ),
          ],
        ),
      );
    });
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
    required this.width,
  });

  final String label;
  final String value;
  final Color accent;
  final IconData icon;
  final double width;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final base = isDark ? const Color(0xFF26262B) : const Color(0xFFF5F6F8);
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    return SizedBox(
      width: width,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: accent, size: 18.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodPills extends StatelessWidget {
  const _PeriodPills({required this.controller});

  final EmployeePointsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeService.isDark.value;
      final color = isDark ? Colors.white70 : const Color(0xFF374151);
      return Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: [
          _PillSelector<int>(
            label: 'pointsFilterMonth'.tr,
            value: controller.selectedMonth.value,
            color: color,
            onTap: () async {
              final picked = await _pickMonth(context, controller.selectedMonth.value);
              if (picked != null) {
                controller.updatePeriod(month: picked);
              }
            },
            displayValue: controller.selectedMonth.value.toString().padLeft(2, '0'),
          ),
          _PillSelector<int>(
            label: 'pointsFilterYear'.tr,
            value: controller.selectedYear.value,
            color: color,
            onTap: () async {
              final picked = await _pickYear(context, controller.selectedYear.value);
              if (picked != null) {
                controller.updatePeriod(year: picked);
              }
            },
            displayValue: '${controller.selectedYear.value}',
          ),
        ],
      );
    });
  }

  Future<int?> _pickMonth(BuildContext context, int current) async {
    return showModalBottomSheet<int>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 12,
            itemBuilder: (_, i) {
              final m = i + 1;
              return ListTile(
                title: Text(m.toString().padLeft(2, '0')),
                trailing: m == current
                    ? const Icon(Icons.check_circle, color: Color(0xFF16A34A))
                    : null,
                onTap: () => Navigator.of(ctx).pop(m),
              );
            },
          ),
        );
      },
    );
  }

  Future<int?> _pickYear(BuildContext context, int current) async {
    final years = List<int>.generate(8, (i) => DateTime.now().year - 4 + i);
    return showModalBottomSheet<int>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: years
                .map((y) => ListTile(
                      title: Text('$y'),
                      trailing: y == current
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFF16A34A))
                          : null,
                      onTap: () => Navigator.of(ctx).pop(y),
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}

class _PillSelector<T> extends StatelessWidget {
  const _PillSelector({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
    required this.displayValue,
  });

  final String label;
  final T value;
  final Color color;
  final String displayValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF26262B) : const Color(0xFFEFF1F4),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: TextStyle(
                fontSize: 12.sp,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              displayValue,
              style: TextStyle(
                fontSize: 12.sp,
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.expand_more_rounded, size: 16.sp, color: color),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.controller});

  final EmployeePointsController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _openMutationDialog(context, isAdd: true),
            icon: const Icon(Icons.add_rounded),
            label: Text('addPointsAction'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _openMutationDialog(context, isAdd: false),
            icon: const Icon(Icons.remove_rounded),
            label: Text('deductPointsAction'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openMutationDialog(
    BuildContext context, {
    required bool isAdd,
  }) async {
    await showDialog<bool>(
      context: context,
      builder: (ctx) => _PointsMutationDialog(
        controller: controller,
        isAdd: isAdd,
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({required this.controller});

  final EmployeePointsController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return Obx(() {
      final categories = controller.allCategories();
      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F23) : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
        ),
        padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list_rounded,
                    size: 18.sp,
                    color: isDark ? Colors.white70 : const Color(0xFF6B7280)),
                SizedBox(width: 6.w),
                Text(
                  'pointsFilters'.tr,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const Spacer(),
                if (controller.selectedCategory.value != null ||
                    controller.selectedOperationType.value != null)
                  TextButton.icon(
                    icon: const Icon(Icons.clear_rounded, size: 16),
                    label: Text('pointsFilterClear'.tr),
                    onPressed: controller.clearFilters,
                  ),
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: controller.selectedOperationType.value,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'pointsFilterOperationType'.tr,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r)),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('pointsFilterAll'.tr),
                      ),
                      DropdownMenuItem<String>(
                        value: 'add',
                        child: Text('pointsFilterAdd'.tr),
                      ),
                      DropdownMenuItem<String>(
                        value: 'deduct',
                        child: Text('pointsFilterDeduct'.tr),
                      ),
                    ],
                    onChanged: (value) =>
                        controller.updateFilters(operationType: value ?? ''),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: controller.selectedCategory.value,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'pointsFilterCategory'.tr,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r)),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                    ),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('pointsFilterAll'.tr),
                      ),
                      ...categories.map(
                        (c) => DropdownMenuItem<String>(
                          value: c,
                          child: Text(_categoryLabel(c)),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        controller.updateFilters(category: value ?? ''),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _LogsList extends StatelessWidget {
  const _LogsList({required this.controller});

  final EmployeePointsController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final cardColor = isDark ? const Color(0xFF1F1F23) : Colors.white;
    final borderColor =
        isDark ? Colors.white12 : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 6.h),
            child: Row(
              children: [
                Icon(Icons.history_rounded,
                    size: 18.sp,
                    color: isDark ? Colors.white70 : const Color(0xFF6B7280)),
                SizedBox(width: 6.w),
                Text(
                  'pointsLogsTitle'.tr,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          Obx(() {
            final loading = controller.isLogsLoading.value;
            final items = controller.logs;

            if (loading && items.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 32.h),
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            if (items.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(20.w),
                child: Center(
                  child: Text(
                    'pointsLogsEmpty'.tr,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: borderColor),
              itemBuilder: (_, i) => _LogTile(item: items[i]),
            );
          }),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.item});

  final EmployeePointsLogModel item;

  @override
  Widget build(BuildContext context) {
    final isAdd = item.isAdd;
    final accent =
        isAdd ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final isDark = ThemeService.isDark.value;
    final secondary = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAdd ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 14.sp,
                  color: accent,
                ),
                SizedBox(width: 4.w),
                Text(
                  '${isAdd ? '+' : '-'}${item.points}',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _categoryLabel(item.category),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                        ),
                      ),
                    ),
                    Text(
                      isAdd ? 'pointsAddBadge'.tr : 'pointsDeductBadge'.tr,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                if ((item.reason ?? '').isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: Text(
                      item.reason!,
                      style: TextStyle(fontSize: 12.sp, color: secondary),
                    ),
                  ),
                if ((item.notes ?? '').isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: Text(
                      item.notes!,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: secondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 4.h,
                  children: [
                    if (item.pointsDate != null)
                      _MetaChip(
                        icon: Icons.calendar_today_outlined,
                        text: item.pointsDate!,
                      ),
                    if ((item.createdByName ?? '').isNotEmpty)
                      _MetaChip(
                        icon: Icons.person_outline,
                        text: '${'pointsCreatedBy'.tr}: ${item.createdByName!}',
                      ),
                    if (item.source != 'manual')
                      _MetaChip(
                        icon: Icons.source_outlined,
                        text: item.source,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF26262B) : const Color(0xFFEFF1F4),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 11.sp,
              color: isDark ? Colors.white70 : const Color(0xFF6B7280)),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.sp,
              color: isDark ? Colors.white70 : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsMutationDialog extends StatefulWidget {
  const _PointsMutationDialog({
    required this.controller,
    required this.isAdd,
  });

  final EmployeePointsController controller;
  final bool isAdd;

  @override
  State<_PointsMutationDialog> createState() => _PointsMutationDialogState();
}

class _PointsMutationDialogState extends State<_PointsMutationDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _pointsCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  /// Legacy free-text category code (used when no configurable category is selected).
  String? _selectedLegacyCategory;
  EmployeePointCategoryModel? _selectedConfigurableCategory;
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
    final isDark = ThemeService.isDark.value;
    final dialogBg = isDark ? const Color(0xFF1F1F23) : Colors.white;

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
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
                        widget.isAdd
                            ? 'addPointsDialogTitle'.tr
                            : 'deductPointsDialogTitle'.tr,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Obx(() {
                  final all = widget.controller.categories.value;
                  final configurable = (all?.configurable ?? const [])
                      .where((c) =>
                          c.isActive &&
                          (widget.isAdd ? c.isAdd : c.isDeduct))
                      .toList();
                  final legacy = widget.isAdd
                      ? (all?.positive ?? const <String>[])
                      : (all?.negative ?? const <String>[]);

                  // Prefer configurable categories. If admin hasn't defined any,
                  // gracefully fall back to the legacy free-text dropdown.
                  if (configurable.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: _selectedConfigurableCategory?.id,
                          isExpanded: true,
                          decoration: _decoration(
                            'pointsCategory'.tr,
                            hint: 'pointsCategoryHint'.tr,
                          ),
                          items: configurable
                              .map(
                                (c) => DropdownMenuItem<int>(
                                  value: c.id,
                                  child: Text(_categoryDisplayName(c)),
                                ),
                              )
                              .toList(),
                          validator: (v) => v == null
                              ? 'pointsCategoryRequired'.tr
                              : null,
                          onChanged: (id) {
                            final cat = configurable
                                .firstWhere((c) => c.id == id);
                            setState(() {
                              _selectedConfigurableCategory = cat;
                              _pointsCtrl.text = cat.defaultPoints.toString();
                            });
                          },
                        ),
                        if (_selectedConfigurableCategory != null)
                          Padding(
                            padding: EdgeInsets.only(top: 6.h),
                            child: Text(
                              '${widget.isAdd ? '+' : '-'} '
                              '${_selectedConfigurableCategory!.defaultPoints} '
                              '· ${'pointsCategoryAutoFill'.tr}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                      ],
                    );
                  }

                  // Legacy fallback (older installs without configured categories)
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedLegacyCategory,
                    isExpanded: true,
                    decoration: _decoration('pointsCategory'.tr,
                        hint: 'pointsCategoryHint'.tr),
                    items: legacy
                        .map((c) => DropdownMenuItem<String>(
                              value: c,
                              child: Text(_categoryLabel(c)),
                            ))
                        .toList(),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'pointsCategoryRequired'.tr
                        : null,
                    onChanged: (v) =>
                        setState(() => _selectedLegacyCategory = v),
                  );
                }),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _pointsCtrl,
                  keyboardType: TextInputType.number,
                  readOnly: _selectedConfigurableCategory != null,
                  enabled: _selectedConfigurableCategory == null,
                  decoration: _decoration(
                    'pointsValue'.tr,
                  ).copyWith(
                    suffixIcon: _selectedConfigurableCategory != null
                        ? Icon(
                            Icons.lock_outline_rounded,
                            size: 18.sp,
                            color: const Color(0xFF9CA3AF),
                          )
                        : null,
                    helperText: _selectedConfigurableCategory != null
                        ? 'pointsCategoryAutoFill'.tr
                        : null,
                    helperStyle: TextStyle(
                      fontSize: 10.sp,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  validator: (v) {
                    if (_selectedConfigurableCategory != null) return null;
                    if (v == null || v.isEmpty) {
                      return 'pointsValueRequired'.tr;
                    }
                    final n = int.tryParse(v.trim());
                    if (n == null || n < 1) return 'pointsValueMin'.tr;
                    return null;
                  },
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _reasonCtrl,
                  decoration: _decoration('pointsReasonOptional'.tr),
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: _decoration('pointsNotesOptional'.tr),
                ),
                SizedBox(height: 12.h),
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
                    decoration: _decoration('pointsDateOptional'.tr).copyWith(
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      _selectedDate == null
                          ? '—'
                          : '${_selectedDate!.year.toString().padLeft(4, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                Obx(() {
                  final loading = widget.controller.isMutating.value;
                  return Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed:
                              loading ? null : () => Navigator.of(context).pop(false),
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
    final overridePoints =
        overrideText.isEmpty ? null : int.tryParse(overrideText);

    bool ok;
    if (_selectedConfigurableCategory != null) {
      // Category drives the points value; admin cannot override here.
      ok = await widget.controller.mutatePoints(
        isAdd: widget.isAdd,
        categoryId: _selectedConfigurableCategory!.id,
        category: _selectedConfigurableCategory!.code,
        points: null,
        reason: _reasonCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        pointsDate: _selectedDate,
      );
    } else {
      ok = await widget.controller.mutatePoints(
        isAdd: widget.isAdd,
        points: overridePoints,
        category: _selectedLegacyCategory,
        reason: _reasonCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        pointsDate: _selectedDate,
      );
    }
    if (ok && mounted) {
      Navigator.of(context).pop(true);
    }
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

/// Translates a points category key into the localized label.
String _categoryLabel(String key) {
  if (key.isEmpty) return '';
  final translated = 'pointsCat_$key'.tr;
  if (translated.startsWith('pointsCat_')) {
    return key.replaceAll('_', ' ');
  }
  return translated;
}

/// Resolve display name for a configurable category, preferring the Arabic
/// name with a localized fallback if missing.
String _categoryDisplayName(EmployeePointCategoryModel cat) {
  final isArabic = Get.locale?.languageCode == 'ar';
  if (isArabic) {
    if (cat.nameAr.isNotEmpty) return cat.nameAr;
    return cat.nameEn ?? cat.code;
  }
  if (cat.nameEn != null && cat.nameEn!.isNotEmpty) return cat.nameEn!;
  return cat.nameAr.isNotEmpty ? cat.nameAr : cat.code;
}
