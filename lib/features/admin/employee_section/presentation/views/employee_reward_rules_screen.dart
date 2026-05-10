import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/employee_reward_rule_model.dart';
import '../controllers/employee_reward_rules_controller.dart';

class EmployeeRewardRulesScreen
    extends GetView<EmployeeRewardRulesController> {
  const EmployeeRewardRulesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final pageBg = isDark ? AppColors.darkColor : const Color(0xFFF5F6F8);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: CustomAppBar(
        title: 'rewardRulesTitle',
        action: false,
        backgroundColor: pageBg,
        actions: [
          IconButton(
            tooltip: 'addRewardRule'.tr,
            icon: Icon(
              Icons.add_circle_rounded,
              size: 28.sp,
              color: isDark ? AppColors.primaryColor : AppColors.secondaryColor,
            ),
            onPressed: () => _openRuleEditor(context),
          ),
          IconButton(
            tooltip: 'refresh'.tr,
            icon: Icon(
              Icons.refresh_rounded,
              size: 24.sp,
              color: isDark ? AppColors.primaryColor : AppColors.secondaryColor,
            ),
            onPressed: controller.loadRules,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.rules.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.rules.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.loadRules,
            child: ListView(
              children: [
                SizedBox(height: 80.h),
                Icon(Icons.workspace_premium_outlined,
                    size: 56.sp, color: const Color(0xFFB45309)),
                SizedBox(height: 12.h),
                Center(
                  child: Text(
                    'rewardRulesEmpty'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isDark
                          ? Colors.white70
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _openRuleEditor(context),
                    icon: const Icon(Icons.add),
                    label: Text('addRewardRule'.tr),
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.loadRules,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            itemBuilder: (_, i) => _RewardRuleCard(
              rule: controller.rules[i],
              onEdit: () => _openRuleEditor(context, rule: controller.rules[i]),
              onToggle: () => controller.toggleActive(controller.rules[i]),
              onDelete: () =>
                  _confirmDelete(context, controller.rules[i].id),
            ),
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
            itemCount: controller.rules.length,
          ),
        );
      }),
    );
  }

  Future<void> _openRuleEditor(BuildContext context,
      {EmployeeRewardRuleModel? rule}) async {
    await showDialog<bool>(
      context: context,
      builder: (ctx) => _RewardRuleEditorDialog(
        controller: controller,
        existingRule: rule,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, int id) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('rewardRulesTitle'.tr),
        content: Text('rewardRuleDeleteConfirm'.tr),
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
    if (result == true) {
      await controller.deleteRule(id);
    }
  }
}

class _RewardRuleCard extends StatelessWidget {
  const _RewardRuleCard({
    required this.rule,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final EmployeeRewardRuleModel rule;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final cardColor = isDark ? const Color(0xFF1F1F23) : Colors.white;
    final borderColor =
        isDark ? Colors.white12 : const Color(0xFFE5E7EB);
    final accent =
        rule.isActive ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: const Color(0xFFB45309).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: const Icon(Icons.emoji_events_outlined,
                color: Color(0xFFB45309)),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${'rewardRuleMinPoints'.tr}: ${rule.minPoints} • ${'rewardRuleMaxPoints'.tr}: ${rule.maxPoints?.toString() ?? '∞'}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        rule.isActive
                            ? 'rewardRuleActive'.tr
                            : 'rewardRuleInactive'.tr,
                        style: TextStyle(
                          color: accent,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  '${'rewardRuleAmount'.tr}: ${rule.rewardAmount}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color:
                        isDark ? Colors.white70 : const Color(0xFF374151),
                  ),
                ),
                if ((rule.statusLabel != null &&
                        rule.statusLabel!.isNotEmpty) ||
                    (rule.statusColor != null &&
                        rule.statusColor!.isNotEmpty)) ...[
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Container(
                        width: 14.w,
                        height: 14.w,
                        decoration: BoxDecoration(
                          color: _parseHex(rule.statusColor) ??
                              const Color(0xFF9CA3AF),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          rule.statusLabel ?? '',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: _parseHex(rule.statusColor) ??
                                (isDark
                                    ? Colors.white
                                    : const Color(0xFF111827)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 6.h),
                Wrap(
                  spacing: 8.w,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text('edit'.tr),
                      onPressed: onEdit,
                    ),
                    TextButton.icon(
                      icon: Icon(
                        rule.isActive
                            ? Icons.toggle_on_rounded
                            : Icons.toggle_off_rounded,
                        size: 22,
                        color: accent,
                      ),
                      label: Text(rule.isActive
                          ? 'rewardRuleInactive'.tr
                          : 'rewardRuleActive'.tr),
                      onPressed: onToggle,
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Color(0xFFDC2626)),
                      label: Text(
                        'delete'.tr,
                        style: const TextStyle(color: Color(0xFFDC2626)),
                      ),
                      onPressed: onDelete,
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

class _RewardRuleEditorDialog extends StatefulWidget {
  const _RewardRuleEditorDialog({
    required this.controller,
    this.existingRule,
  });

  final EmployeeRewardRulesController controller;
  final EmployeeRewardRuleModel? existingRule;

  @override
  State<_RewardRuleEditorDialog> createState() =>
      _RewardRuleEditorDialogState();
}

class _RewardRuleEditorDialogState extends State<_RewardRuleEditorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _statusLabelCtrl;
  late String _statusColor;
  bool _isActive = true;

  static const List<String> _palette = [
    '#9CA3AF',
    '#F59E0B',
    '#2563EB',
    '#16A34A',
    '#DC2626',
    '#7C3AED',
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.existingRule;
    _minCtrl = TextEditingController(text: r?.minPoints.toString() ?? '');
    _maxCtrl = TextEditingController(text: r?.maxPoints?.toString() ?? '');
    _amountCtrl = TextEditingController(text: r?.rewardAmount ?? '');
    _statusLabelCtrl = TextEditingController(text: r?.statusLabel ?? '');
    _statusColor =
        (r?.statusColor != null && r!.statusColor!.isNotEmpty)
            ? r.statusColor!
            : _palette.first;
    _isActive = r?.isActive ?? true;
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _amountCtrl.dispose();
    _statusLabelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUpdate = widget.existingRule != null;
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
                    const Icon(Icons.workspace_premium_outlined,
                        color: Color(0xFFB45309)),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        isUpdate
                            ? 'editRewardRule'.tr
                            : 'addRewardRule'.tr,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                TextFormField(
                  controller: _minCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('rewardRuleMinPoints'.tr),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'rewardRuleMinRequired'.tr;
                    }
                    if (int.tryParse(v.trim()) == null) {
                      return 'rewardRuleMinRequired'.tr;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _maxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _decoration(
                    'rewardRuleMaxPoints'.tr,
                    hint: 'rewardRuleMaxPointsHint'.tr,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final maxVal = int.tryParse(v.trim());
                    if (maxVal == null) return 'rewardRuleMaxLessMin'.tr;
                    final minVal = int.tryParse(_minCtrl.text.trim()) ?? 0;
                    if (maxVal < minVal) return 'rewardRuleMaxLessMin'.tr;
                    return null;
                  },
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _decoration('rewardRuleAmount'.tr),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'rewardRuleAmountRequired'.tr;
                    }
                    final n = double.tryParse(v.trim());
                    if (n == null || n < 0) {
                      return 'rewardRuleAmountRequired'.tr;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _statusLabelCtrl,
                  decoration: _decoration(
                    'rewardRuleStatusLabel'.tr,
                    hint: 'rewardRuleStatusLabelHint'.tr,
                  ),
                ),
                SizedBox(height: 10.h),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'rewardRuleStatusColor'.tr,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _palette.map((hex) {
                    final isSelected = _statusColor.toLowerCase() ==
                        hex.toLowerCase();
                    return InkWell(
                      onTap: () => setState(() => _statusColor = hex),
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          color: _parseHex(hex) ?? Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.black
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 6.h),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text('rewardRuleActive'.tr),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                SizedBox(height: 8.h),
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
                          onPressed: loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB45309),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
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
    final minVal = int.parse(_minCtrl.text.trim());
    final maxText = _maxCtrl.text.trim();
    final maxVal = maxText.isEmpty ? null : int.parse(maxText);
    final amount = double.parse(_amountCtrl.text.trim());
    final statusLabel = _statusLabelCtrl.text.trim();

    final isUpdate = widget.existingRule != null;
    bool ok;
    if (isUpdate) {
      ok = await widget.controller.updateRule(
        id: widget.existingRule!.id,
        minPoints: minVal,
        maxPoints: maxVal,
        clearMaxPoints: maxText.isEmpty,
        rewardAmount: amount,
        statusLabel: statusLabel,
        statusColor: _statusColor,
        isActive: _isActive,
      );
    } else {
      ok = await widget.controller.createRule(
        minPoints: minVal,
        maxPoints: maxVal,
        rewardAmount: amount,
        isActive: _isActive,
        statusLabel: statusLabel.isEmpty ? null : statusLabel,
        statusColor: _statusColor,
      );
    }
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
    );
  }
}

/// Parse a `#RRGGBB` (or `#AARRGGBB`) string into a [Color]. Returns null if
/// the input is empty/null or not a valid hex value.
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
