import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/employee_point_rule_model.dart';
import '../controllers/employee_point_rules_controller.dart';
import '../widgets/employee_point_swipe_card.dart';

class EmployeePointRulesScreen extends GetView<EmployeePointRulesController> {
  const EmployeePointRulesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final pageBg = isDark ? AppColors.darkColor : const Color(0xFFF5F6F8);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: CustomAppBar(
        title: 'قواعد النقاط التلقائية',
        action: false,
        backgroundColor: pageBg,
        actions: [
          IconButton(
            tooltip: 'تشغيل القواعد',
            icon: Icon(Icons.play_circle_outline_rounded,
                size: 25.sp,
                color:
                    isDark ? AppColors.primaryColor : AppColors.secondaryColor),
            onPressed: () => controller.runRules(),
          ),
          IconButton(
            tooltip: 'إضافة قاعدة',
            icon: Icon(Icons.add_circle_rounded,
                size: 28.sp,
                color:
                    isDark ? AppColors.primaryColor : AppColors.secondaryColor),
            onPressed: () => _openEditor(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.rules.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.rules.isEmpty) {
          return Center(
            child: ElevatedButton.icon(
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.add),
              label: const Text('إضافة أول قاعدة'),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.loadRules,
          child: ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemBuilder: (_, i) {
              final rule = controller.rules[i];
              return _RuleCard(
                rule: rule,
                onEdit: () => _openEditor(context, rule: rule),
                onOptions: () => _openRuleOptions(context, rule),
              );
            },
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
            itemCount: controller.rules.length,
          ),
        );
      }),
    );
  }

  Future<void> _openEditor(BuildContext context,
      {EmployeePointRuleModel? rule}) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RuleEditorDialog(controller: controller, rule: rule),
    );
  }

  Future<void> _confirmDelete(BuildContext context, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف القاعدة'),
        content: const Text('هل تريد حذف قاعدة النقاط؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
    if (ok == true) await controller.deleteRule(id);
  }

  Future<void> _openRuleOptions(
      BuildContext context, EmployeePointRuleModel rule) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ActionsSheet(
        title: 'خيارات القاعدة',
        actions: [
          _SheetAction(
            icon: Icons.play_arrow_rounded,
            label: 'تشغيل القاعدة الآن',
            color: const Color(0xFF16A34A),
            onTap: () {
              Navigator.of(sheetContext).pop();
              controller.runRules(ruleId: rule.id);
            },
          ),
          _SheetAction(
            icon: rule.isActive
                ? Icons.pause_circle_outline_rounded
                : Icons.play_circle_outline_rounded,
            label: rule.isActive ? 'إيقاف القاعدة' : 'تفعيل القاعدة',
            color: const Color(0xFF64748B),
            onTap: () {
              Navigator.of(sheetContext).pop();
              controller.toggleRule(rule);
            },
          ),
          _SheetAction(
            icon: Icons.delete_outline_rounded,
            label: 'حذف القاعدة',
            color: const Color(0xFFDC2626),
            onTap: () {
              Navigator.of(sheetContext).pop();
              _confirmDelete(context, rule.id);
            },
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.rule,
    required this.onEdit,
    required this.onOptions,
  });

  final EmployeePointRuleModel rule;
  final VoidCallback onEdit;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final accent = rule.operationType == 'deduct'
        ? const Color(0xFFDC2626)
        : const Color(0xFF16A34A);
    final swipeActions = [
      EmployeePointSwipeAction(
        icon: Icons.edit_outlined,
        label: 'edit'.tr,
        color: AppColors.primaryColor,
        onTap: onEdit,
      ),
      EmployeePointSwipeAction(
        icon: Icons.more_horiz_rounded,
        label: 'الخيارات',
        color: AppColors.secondaryColor,
        onTap: onOptions,
      ),
    ];
    return EmployeePointSwipeCard(
      startActions: swipeActions,
      endActions: swipeActions,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F23) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rule_rounded, color: accent),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    rule.name,
                    style:
                        TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800),
                  ),
                ),
                _Badge(
                  label: rule.isActive ? 'فعالة' : 'موقوفة',
                  color: rule.isActive
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF9CA3AF),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _Badge(
                    label: _periodLabel(rule.periodType),
                    color: const Color(0xFF2563EB)),
                _Badge(
                    label: _conditionLabel(rule.conditionType),
                    color: const Color(0xFF7C3AED)),
                _Badge(
                  label:
                      '${rule.operationType == 'deduct' ? '-' : '+'}${rule.defaultPoints}',
                  color: accent,
                ),
                _Badge(
                  label: rule.appliesToAll
                      ? 'كل الموظفين'
                      : '${rule.employeeIds.length} موظف',
                  color: const Color(0xFFB45309),
                ),
                if (rule.conditionType ==
                    'employee_completed_all_tasks_before_time')
                  _Badge(
                      label: 'قبل ${_timeLabel(rule.cutoffTime)}',
                      color: const Color(0xFF0891B2)),
                if (rule.conditionType == 'employee_attended_on_time' ||
                    rule.conditionType ==
                        'employee_perfect_attendance_and_tasks')
                  _Badge(
                    label: 'سماح ${rule.graceMinutes} دقيقة',
                    color: const Color(0xFF0891B2),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetAction {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _ActionsSheet extends StatelessWidget {
  const _ActionsSheet({required this.title, required this.actions});

  final String title;
  final List<_SheetAction> actions;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 18.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 14.h),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(title,
                    style: TextStyle(
                        fontSize: 16.sp, fontWeight: FontWeight.w800)),
              ),
              SizedBox(height: 8.h),
              ...actions.map((action) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: action.color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(action.icon, color: action.color),
                    ),
                    title: Text(action.label,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    onTap: action.onTap,
                  )),
            ],
          ),
        ),
      );
}

class _RuleEditorDialog extends StatefulWidget {
  const _RuleEditorDialog({required this.controller, this.rule});

  final EmployeePointRulesController controller;
  final EmployeePointRuleModel? rule;

  @override
  State<_RuleEditorDialog> createState() => _RuleEditorDialogState();
}

class _RuleEditorDialogState extends State<_RuleEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _pointsCtrl;
  late final TextEditingController _graceMinutesCtrl;
  int _cutoffHour = 2;
  String _cutoffMinute = '00';
  String _cutoffPeriod = 'am';
  String _condition = 'employee_completed_all_tasks_before_time';
  String _period = 'daily';
  String _operation = 'add';
  String _effectivePolicy = 'today';
  bool _appliesToAll = true;
  bool _isActive = true;
  final Set<int> _employeeIds = <int>{};

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    _nameCtrl = TextEditingController(text: r?.name ?? '');
    _pointsCtrl =
        TextEditingController(text: r?.defaultPoints.toString() ?? '0');
    _graceMinutesCtrl =
        TextEditingController(text: r?.graceMinutes.toString() ?? '0');
    _initCutoff(r?.cutoffTime ?? '02:00');
    _condition = r?.conditionType ?? _condition;
    _period = r?.periodType ?? _period;
    _operation = r?.operationType ?? _operation;
    _appliesToAll = r?.appliesToAll ?? true;
    _isActive = r?.isActive ?? true;
    _employeeIds.addAll(r?.employeeIds ?? const <int>[]);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pointsCtrl.dispose();
    _graceMinutesCtrl.dispose();
    super.dispose();
  }

  void _initCutoff(String value) {
    final parts = value.split(':');
    final hour24 = int.tryParse(parts.isNotEmpty ? parts.first : '') ?? 2;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    _cutoffPeriod = hour24 >= 12 ? 'pm' : 'am';
    _cutoffHour = hour24 % 12;
    if (_cutoffHour == 0) _cutoffHour = 12;
    _cutoffMinute = minute.clamp(0, 59).toString().padLeft(2, '0');
  }

  String _cutoff24h() {
    var hour = _cutoffHour % 12;
    if (_cutoffPeriod == 'pm') hour += 12;
    return '${hour.toString().padLeft(2, '0')}:$_cutoffMinute';
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: keyboard),
      child: Material(
        color: Theme.of(context).dialogTheme.backgroundColor ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * .9,
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: .45),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      widget.rule == null
                          ? 'إضافة قاعدة نقاط'
                          : 'تعديل قاعدة نقاط',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16.sp, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 14.h),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _decoration('اسم القاعدة'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'مطلوب' : null,
                    ),
                    SizedBox(height: 10.h),
                    DropdownSearch<_RuleConditionOption>(
                      selectedItem: _conditionOptions.firstWhere(
                        (item) => item.value == _condition,
                        orElse: () => _conditionOptions.first,
                      ),
                      items: (filter, _) async {
                        final query = filter.trim().toLowerCase();
                        if (query.isEmpty) return _conditionOptions;
                        return _conditionOptions
                            .where((item) =>
                                item.label.toLowerCase().contains(query))
                            .toList();
                      },
                      itemAsString: (item) => item.label,
                      compareFn: (a, b) => a.value == b.value,
                      decoratorProps: DropDownDecoratorProps(
                        decoration: _decoration('الشرط').copyWith(
                          hintText: 'ابحث عن الشرط',
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                      popupProps: const PopupProps.menu(
                        showSearchBox: true,
                        searchDelay: Duration(milliseconds: 100),
                        constraints: BoxConstraints(maxHeight: 360),
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            labelText: 'بحث في الشروط',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      onChanged: (item) => setState(() {
                        if (item != null) _condition = item.value;
                      }),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _period,
                            decoration: _decoration('الفترة'),
                            items: const [
                              DropdownMenuItem(
                                  value: 'daily', child: Text('يومية')),
                              DropdownMenuItem(
                                  value: 'weekly', child: Text('أسبوعية')),
                              DropdownMenuItem(
                                  value: 'monthly', child: Text('شهرية')),
                            ],
                            onChanged: (v) =>
                                setState(() => _period = v ?? _period),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _operation,
                            decoration: _decoration('العملية'),
                            items: const [
                              DropdownMenuItem(
                                  value: 'add', child: Text('إضافة')),
                              DropdownMenuItem(
                                  value: 'deduct', child: Text('خصم')),
                            ],
                            onChanged: (v) =>
                                setState(() => _operation = v ?? _operation),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    TextFormField(
                      controller: _pointsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _decoration('النقاط'),
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim());
                        return n == null || n < 0 ? '0 أو أكثر' : null;
                      },
                    ),
                    SizedBox(height: 10.h),
                    if (_condition ==
                        'employee_completed_all_tasks_before_time')
                      InputDecorator(
                        decoration: _decoration('وقت القطع'),
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _cutoffHour,
                                  isExpanded: true,
                                  items: List.generate(12, (i) => i + 1)
                                      .map(
                                        (h) => DropdownMenuItem(
                                          value: h,
                                          child: Text('$h'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(
                                    () => _cutoffHour = v ?? _cutoffHour,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _cutoffMinute,
                                  isExpanded: true,
                                  items: List.generate(
                                    60,
                                    (i) => i.toString().padLeft(2, '0'),
                                  )
                                      .map(
                                        (m) => DropdownMenuItem(
                                          value: m,
                                          child: Text(m),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(
                                    () => _cutoffMinute = v ?? _cutoffMinute,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _cutoffPeriod,
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'am',
                                      child: Text('صباحا'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'pm',
                                      child: Text('مساء'),
                                    ),
                                  ],
                                  onChanged: (v) => setState(
                                    () => _cutoffPeriod = v ?? _cutoffPeriod,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_condition == 'employee_attended_on_time' ||
                        _condition ==
                            'employee_perfect_attendance_and_tasks') ...[
                      SizedBox(height: 10.h),
                      TextFormField(
                        controller: _graceMinutesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _decoration('فترة سماح التأخير بالدقائق'),
                        validator: (value) {
                          final minutes = int.tryParse((value ?? '').trim());
                          return minutes == null || minutes < 0 || minutes > 240
                              ? 'أدخل قيمة من 0 إلى 240'
                              : null;
                        },
                      ),
                    ],
                    SizedBox(height: 8.h),
                    DropdownButtonFormField<String>(
                      initialValue: _effectivePolicy,
                      decoration: _decoration('يبدأ التطبيق من'),
                      items: const [
                        DropdownMenuItem(value: 'today', child: Text('اليوم')),
                        DropdownMenuItem(
                            value: 'current_week',
                            child: Text('بداية الأسبوع الحالي')),
                        DropdownMenuItem(
                            value: 'current_month',
                            child: Text('بداية الشهر الحالي')),
                      ],
                      onChanged: (v) => setState(
                          () => _effectivePolicy = v ?? _effectivePolicy),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('تطبيق على كل الموظفين'),
                      value: _appliesToAll,
                      onChanged: (v) => setState(() => _appliesToAll = v),
                    ),
                    if (!_appliesToAll)
                      _EmployeePicker(
                        controller: widget.controller,
                        selectedIds: _employeeIds,
                        onChanged: () => setState(() {}),
                      ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('القاعدة فعالة'),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                    SizedBox(height: 8.h),
                    Obx(() => Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: widget.controller.isMutating.value
                                    ? null
                                    : () => Navigator.of(context).pop(false),
                                child: Text('cancel'.tr),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: widget.controller.isMutating.value
                                    ? null
                                    : _submit,
                                child: Text('save'.tr),
                              ),
                            ),
                          ],
                        )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_appliesToAll && _employeeIds.isEmpty) {
      Get.snackbar('خطأ', 'اختر موظف واحد على الأقل');
      return;
    }
    final ok = await widget.controller.saveRule(
      id: widget.rule?.id,
      name: _nameCtrl.text.trim(),
      conditionType: _condition,
      periodType: _period,
      operationType: _operation,
      defaultPoints: int.parse(_pointsCtrl.text.trim()),
      appliesToAll: _appliesToAll,
      employeeIds: _employeeIds.toList(),
      cutoffTime: _cutoff24h(),
      graceMinutes: int.tryParse(_graceMinutesCtrl.text.trim()) ?? 0,
      effectivePolicy: _effectivePolicy,
      isActive: _isActive,
    );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      );
}

class _RuleConditionOption {
  const _RuleConditionOption(this.value, this.label);

  final String value;
  final String label;
}

const List<_RuleConditionOption> _conditionOptions = [
  _RuleConditionOption(
    'employee_completed_all_tasks_before_time',
    'الموظف أنهى كل مهامه قبل وقت معين',
  ),
  _RuleConditionOption(
    'employee_completed_all_tasks',
    'الموظف أنهى جميع مهامه',
  ),
  _RuleConditionOption(
    'employee_attended_on_time',
    'الموظف حضر في الموعد',
  ),
  _RuleConditionOption(
    'employee_perfect_attendance_and_tasks',
    'حضور كامل بلا تأخير ولا مهام ناقصة',
  ),
  _RuleConditionOption(
    'all_employees_completed_tasks',
    'كل الموظفين أنهوا مهامهم',
  ),
  _RuleConditionOption(
    'employee_has_incomplete_tasks',
    'الموظف عنده مهام غير منتهية',
  ),
];

class _EmployeePicker extends StatelessWidget {
  const _EmployeePicker({
    required this.controller,
    required this.selectedIds,
    required this.onChanged,
  });

  final EmployeePointRulesController controller;
  final Set<int> selectedIds;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final employees = controller.employees;
    if (employees.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('قائمة الموظفين غير محملة'),
      );
    }
    return Container(
      constraints: BoxConstraints(maxHeight: 180.h),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: employees.length,
        itemBuilder: (_, i) {
          final e = employees[i];
          final selected = selectedIds.contains(e.id);
          return CheckboxListTile(
            dense: true,
            value: selected,
            title: Text(e.employeeName),
            onChanged: (v) {
              if (v == true) {
                selectedIds.add(e.id);
              } else {
                selectedIds.remove(e.id);
              }
              onChanged();
            },
          );
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

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
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11.sp, fontWeight: FontWeight.w700),
      ),
    );
  }
}

String _timeLabel(String value) {
  final parts = value.split(':');
  final hour24 = int.tryParse(parts.isNotEmpty ? parts.first : '') ?? 0;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  final period = hour24 >= 12 ? 'مساء' : 'صباحا';
  var hour = hour24 % 12;
  if (hour == 0) hour = 12;
  return '${hour.toString().padLeft(2, '0')}:${minute.clamp(0, 59).toString().padLeft(2, '0')} $period';
}

String _periodLabel(String value) {
  switch (value) {
    case 'weekly':
      return 'أسبوعية';
    case 'monthly':
      return 'شهرية';
    default:
      return 'يومية';
  }
}

String _conditionLabel(String value) {
  switch (value) {
    case 'employee_completed_all_tasks':
      return 'أنهى جميع مهامه';
    case 'employee_attended_on_time':
      return 'حضر في الموعد';
    case 'employee_perfect_attendance_and_tasks':
      return 'حضور ومهام مكتملة';
    case 'all_employees_completed_tasks':
      return 'كل الموظفين أنهوا المهام';
    case 'employee_has_incomplete_tasks':
      return 'مهام غير منتهية';
    default:
      return 'إنهاء قبل وقت محدد';
  }
}
