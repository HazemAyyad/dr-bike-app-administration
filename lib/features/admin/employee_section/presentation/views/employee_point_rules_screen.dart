import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/employee_point_rule_model.dart';
import '../controllers/employee_point_rules_controller.dart';

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
          IconButton(
            tooltip: 'تحديث',
            icon: Icon(Icons.refresh_rounded,
                size: 24.sp,
                color:
                    isDark ? AppColors.primaryColor : AppColors.secondaryColor),
            onPressed: controller.loadRules,
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
                onRun: () => controller.runRules(ruleId: rule.id),
                onToggle: () => controller.toggleRule(rule),
                onDelete: () => _confirmDelete(context, rule.id),
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
    await showDialog<bool>(
      context: context,
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
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.rule,
    required this.onEdit,
    required this.onRun,
    required this.onToggle,
    required this.onDelete,
  });

  final EmployeePointRuleModel rule;
  final VoidCallback onEdit;
  final VoidCallback onRun;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final accent = rule.operationType == 'deduct'
        ? const Color(0xFFDC2626)
        : const Color(0xFF16A34A);
    return Container(
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
                    label: 'قبل ${rule.cutoffTime}',
                    color: const Color(0xFF0891B2)),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text('edit'.tr),
              ),
              TextButton.icon(
                onPressed: onRun,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('تشغيل'),
              ),
              TextButton.icon(
                onPressed: onToggle,
                icon: Icon(rule.isActive
                    ? Icons.toggle_on_rounded
                    : Icons.toggle_off_rounded),
                label: Text(rule.isActive ? 'إيقاف' : 'تفعيل'),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Color(0xFFDC2626)),
                label: const Text('حذف',
                    style: TextStyle(color: Color(0xFFDC2626))),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
  late final TextEditingController _cutoffCtrl;
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
    _cutoffCtrl = TextEditingController(text: r?.cutoffTime ?? '02:00');
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
    _cutoffCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 20.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.rule == null ? 'إضافة قاعدة نقاط' : 'تعديل قاعدة نقاط',
                  style:
                      TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 14.h),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: _decoration('اسم القاعدة'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                SizedBox(height: 10.h),
                DropdownButtonFormField<String>(
                  initialValue: _condition,
                  decoration: _decoration('الشرط'),
                  items: const [
                    DropdownMenuItem(
                      value: 'employee_completed_all_tasks_before_time',
                      child: Text('الموظف أنهى كل مهامه قبل وقت معين'),
                    ),
                    DropdownMenuItem(
                      value: 'all_employees_completed_tasks',
                      child: Text('كل الموظفين أنهوا مهامهم'),
                    ),
                    DropdownMenuItem(
                      value: 'employee_has_incomplete_tasks',
                      child: Text('الموظف عنده مهام غير منتهية'),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _condition = v ?? _condition),
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
                          DropdownMenuItem(value: 'add', child: Text('إضافة')),
                          DropdownMenuItem(value: 'deduct', child: Text('خصم')),
                        ],
                        onChanged: (v) =>
                            setState(() => _operation = v ?? _operation),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _pointsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _decoration('النقاط'),
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          return n == null || n < 0 ? '0 أو أكثر' : null;
                        },
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: TextFormField(
                        controller: _cutoffCtrl,
                        decoration: _decoration('وقت القطع HH:mm'),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          return RegExp(r'^\d{2}:\d{2}$').hasMatch(value)
                              ? null
                              : 'مثال 02:00';
                        },
                      ),
                    ),
                  ],
                ),
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
                  onChanged: (v) =>
                      setState(() => _effectivePolicy = v ?? _effectivePolicy),
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
      cutoffTime: _cutoffCtrl.text.trim(),
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
    case 'all_employees_completed_tasks':
      return 'كل الموظفين أنهوا المهام';
    case 'employee_has_incomplete_tasks':
      return 'مهام غير منتهية';
    default:
      return 'إنهاء قبل وقت محدد';
  }
}
