import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/assets_controller.dart';
import '../controllers/expenses_controller.dart';
import '../controllers/official_papers_controller.dart';

Future<void> showExpenseFiltersModal(
  BuildContext context,
  ExpensesController controller,
) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExpenseFiltersSheet(controller: controller),
    );

Future<void> showAssetFiltersModal(
  BuildContext context,
  AssetsController controller,
) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssetFiltersSheet(controller: controller),
    );

Future<void> showOfficialPapersFiltersModal(
  BuildContext context,
  OfficialPapersController controller,
) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OfficialPapersFiltersSheet(controller: controller),
    );

class _ExpenseFiltersSheet extends StatefulWidget {
  const _ExpenseFiltersSheet({required this.controller});
  final ExpensesController controller;

  @override
  State<_ExpenseFiltersSheet> createState() => _ExpenseFiltersSheetState();
}

class _ExpenseFiltersSheetState extends State<_ExpenseFiltersSheet> {
  late String from;
  late String to;
  late String type;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    from = widget.controller.fromController.text;
    to = widget.controller.toController.text;
    type = widget.controller.expenseTypeFilter.value;
  }

  @override
  Widget build(BuildContext context) => _FilterShell(
        icon: Icons.receipt_long_outlined,
        title: 'فلترة المصاريف',
        subtitle: 'حدد الفترة ونوع المصروف المطلوب',
        saving: saving,
        onReset: _reset,
        onApply: _apply,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _FilterTitle('الفترة الزمنية'),
            Row(
              children: [
                Expanded(
                  child: _DateFilterField(
                    label: 'من تاريخ',
                    value: from,
                    onChanged: (value) => setState(() => from = value),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _DateFilterField(
                    label: 'إلى تاريخ',
                    value: to,
                    onChanged: (value) => setState(() => to = value),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            const _FilterTitle('نوع المصروف'),
            _FilterChoices(
              value: type,
              options: const {
                '': 'كل المصاريف',
                'general': 'عمومية',
                'salary': 'رواتب',
                'destruction': 'إتلاف بضاعة',
              },
              onChanged: (value) => setState(() => type = value),
            ),
          ],
        ),
      );

  Future<void> _apply() async {
    setState(() => saving = true);
    widget.controller.fromController.text = from;
    widget.controller.toController.text = to;
    widget.controller.expenseTypeFilter.value = type;
    await widget.controller.getAllExpenses(applyFilters: true);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _reset() async {
    setState(() => saving = true);
    await widget.controller.resetFilters();
    if (mounted) Navigator.of(context).pop();
  }
}

class _AssetFiltersSheet extends StatefulWidget {
  const _AssetFiltersSheet({required this.controller});
  final AssetsController controller;

  @override
  State<_AssetFiltersSheet> createState() => _AssetFiltersSheetState();
}

class _AssetFiltersSheetState extends State<_AssetFiltersSheet> {
  late String from;
  late String to;
  late String status;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    from = widget.controller.fromController.text;
    to = widget.controller.toController.text;
    status = widget.controller.assetStatusFilter.value;
  }

  @override
  Widget build(BuildContext context) => _FilterShell(
        icon: Icons.inventory_2_outlined,
        title: 'فلترة الأصول',
        subtitle: 'حدد الفترة وحالة الإهلاك',
        saving: saving,
        onReset: _reset,
        onApply: _apply,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _FilterTitle('تاريخ إضافة الأصل'),
            Row(
              children: [
                Expanded(
                  child: _DateFilterField(
                    label: 'من تاريخ',
                    value: from,
                    onChanged: (value) => setState(() => from = value),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _DateFilterField(
                    label: 'إلى تاريخ',
                    value: to,
                    onChanged: (value) => setState(() => to = value),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            const _FilterTitle('حالة الأصل والإهلاك'),
            _FilterChoices(
              value: status,
              options: const {
                '': 'كل الأصول',
                'active': 'فعّال',
                'fully_depreciated': 'مكتمل الإهلاك',
                'depreciated_this_month': 'تم إهلاك الشهر',
                'pending_this_month': 'بانتظار الإهلاك',
              },
              onChanged: (value) => setState(() => status = value),
            ),
          ],
        ),
      );

  Future<void> _apply() async {
    setState(() => saving = true);
    widget.controller.fromController.text = from;
    widget.controller.toController.text = to;
    widget.controller.assetStatusFilter.value = status;
    await widget.controller.getAllAssets(applyFilters: true);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _reset() async {
    setState(() => saving = true);
    await widget.controller.resetFilters();
    if (mounted) Navigator.of(context).pop();
  }
}

class _OfficialPapersFiltersSheet extends StatefulWidget {
  const _OfficialPapersFiltersSheet({required this.controller});
  final OfficialPapersController controller;

  @override
  State<_OfficialPapersFiltersSheet> createState() =>
      _OfficialPapersFiltersSheetState();
}

class _OfficialPapersFiltersSheetState
    extends State<_OfficialPapersFiltersSheet> {
  late String archiveStatus;
  late int contentTab;

  @override
  void initState() {
    super.initState();
    archiveStatus = widget.controller.archiveStatusFilter.value;
    contentTab = widget.controller.currentTab.value;
  }

  @override
  Widget build(BuildContext context) => _FilterShell(
        icon: Icons.folder_copy_outlined,
        title: 'فلترة الأوراق الرسمية',
        subtitle: 'حدد نوع المحتوى وحالة الحفظ',
        onReset: _reset,
        onApply: _apply,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _FilterTitle('نوع المحتوى'),
            _FilterChoices(
              value: '$contentTab',
              options: const {
                '0': 'الأوراق الرسمية',
                '1': 'الصور المهمة',
              },
              onChanged: (value) =>
                  setState(() => contentTab = int.parse(value)),
            ),
            SizedBox(height: 16.h),
            const _FilterTitle('حالة الأرشفة'),
            _FilterChoices(
              value: archiveStatus,
              options: const {
                'active': 'النشطة',
                'archived': 'المؤرشفة',
                'all': 'الكل',
              },
              onChanged: (value) => setState(() => archiveStatus = value),
            ),
          ],
        ),
      );

  void _apply() {
    widget.controller.currentTab.value = contentTab;
    widget.controller.archiveStatusFilter.value = archiveStatus;
    widget.controller.getAllExpenses();
    widget.controller.update();
    Navigator.of(context).pop();
  }

  void _reset() {
    widget.controller.currentTab.value = 0;
    widget.controller.resetFilters();
    Navigator.of(context).pop();
  }
}

class _FilterShell extends StatelessWidget {
  const _FilterShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onReset,
    required this.onApply,
    this.saving = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onReset;
  final VoidCallback onApply;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .86,
        ),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.darkColor
              : AppColors.operationalSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42.w,
              height: 4.h,
              margin: EdgeInsets.only(top: 9.h),
              decoration: BoxDecoration(
                color: AppColors.customGreyColor5.withValues(alpha: .45),
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 8.w, 8.h),
              child: Row(
                children: [
                  Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(
                      color: AppColors.operationalPurple.withValues(alpha: .11),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(icon, color: AppColors.operationalPurple),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                fontSize: 16.sp, fontWeight: FontWeight.w900)),
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 10.sp,
                                color: AppColors.customGreyColor5)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed:
                        saving ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.r),
                child: child,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 14.h),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: saving ? null : onReset,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('مسح الفلاتر'),
                    ),
                  ),
                  SizedBox(width: 9.w),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: saving ? null : onApply,
                      icon: saving
                          ? SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: const CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_rounded),
                      label: const Text('تطبيق الفلاتر'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.operationalPurple,
                      ),
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

class _FilterTitle extends StatelessWidget {
  const _FilterTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 7.h),
        child: Text(text,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900)),
      );
}

class _DateFilterField extends StatelessWidget {
  const _DateFilterField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () async {
          final parsed = DateTime.tryParse(value);
          final date = await showDatePicker(
            context: context,
            initialDate: parsed ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (date != null) onChanged(DateFormat('yyyy-MM-dd').format(date));
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : AppColors.whiteColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.operationalCardBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: AppColors.operationalPurple, size: 18),
              SizedBox(width: 7.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 8.5.sp,
                            color: AppColors.customGreyColor5)),
                    Text(value.isEmpty ? 'غير محدد' : value,
                        maxLines: 1,
                        style: TextStyle(
                            fontSize: 10.5.sp, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              if (value.isNotEmpty)
                InkWell(
                  onTap: () => onChanged(''),
                  child: const Icon(Icons.close_rounded, size: 17),
                ),
            ],
          ),
        ),
      );
}

class _FilterChoices extends StatelessWidget {
  const _FilterChoices({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 7.w,
        runSpacing: 7.h,
        children: options.entries
            .map((option) => ChoiceChip(
                  selected: value == option.key,
                  onSelected: (_) => onChanged(option.key),
                  label: Text(option.value),
                  selectedColor:
                      AppColors.operationalPurple.withValues(alpha: .16),
                  side: BorderSide(
                    color: value == option.key
                        ? AppColors.operationalPurple
                        : AppColors.operationalCardBorder,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w700,
                    color: value == option.key
                        ? AppColors.operationalPurple
                        : null,
                  ),
                ))
            .toList(),
      );
}
