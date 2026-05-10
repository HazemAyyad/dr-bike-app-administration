import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/employee_points_log_model.dart';
import '../controllers/employee_point_categories_controller.dart';

class EmployeePointCategoriesScreen
    extends GetView<EmployeePointCategoriesController> {
  const EmployeePointCategoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final pageBg = isDark ? AppColors.darkColor : const Color(0xFFF5F6F8);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: CustomAppBar(
        title: 'pointCategoriesTitle',
        action: false,
        backgroundColor: pageBg,
        actions: [
          IconButton(
            tooltip: 'addPointCategory'.tr,
            icon: Icon(
              Icons.add_circle_rounded,
              size: 28.sp,
              color: isDark ? AppColors.primaryColor : AppColors.secondaryColor,
            ),
            onPressed: () => _openEditor(context),
          ),
          IconButton(
            tooltip: 'refresh'.tr,
            icon: Icon(
              Icons.refresh_rounded,
              size: 24.sp,
              color: isDark ? AppColors.primaryColor : AppColors.secondaryColor,
            ),
            onPressed: controller.loadCategories,
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(isDark: isDark),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.categories.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.categories.isEmpty) {
                return RefreshIndicator(
                  onRefresh: controller.loadCategories,
                  child: ListView(
                    children: [
                      SizedBox(height: 80.h),
                      Icon(Icons.list_alt_outlined,
                          size: 56.sp, color: AppColors.primaryColor),
                      SizedBox(height: 12.h),
                      Center(
                        child: Text(
                          'pointCategoriesEmpty'.tr,
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
                          onPressed: () => _openEditor(context),
                          icon: const Icon(Icons.add),
                          label: Text('addPointCategory'.tr),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final positives = controller.positiveCategories;
              final negatives = controller.negativeCategories;
              return RefreshIndicator(
                onRefresh: controller.loadCategories,
                child: ListView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  children: [
                    if (positives.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'positiveCategoriesGroup'.tr,
                        accent: const Color(0xFF16A34A),
                        isDark: isDark,
                      ),
                      SizedBox(height: 10.h),
                      ...positives.map(
                        (cat) => _CategoryCard(
                          category: cat,
                          isDark: isDark,
                          onEdit: () => _openEditor(context, category: cat),
                          onToggle: () => controller.toggleActive(cat),
                          onDelete: () => _confirmDelete(context, cat.id),
                        ),
                      ),
                      SizedBox(height: 14.h),
                    ],
                    if (negatives.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'negativeCategoriesGroup'.tr,
                        accent: const Color(0xFFDC2626),
                        isDark: isDark,
                      ),
                      SizedBox(height: 10.h),
                      ...negatives.map(
                        (cat) => _CategoryCard(
                          category: cat,
                          isDark: isDark,
                          onEdit: () => _openEditor(context, category: cat),
                          onToggle: () => controller.toggleActive(cat),
                          onDelete: () => _confirmDelete(context, cat.id),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor(BuildContext context,
      {EmployeePointCategoryModel? category}) async {
    await showDialog<bool>(
      context: context,
      builder: (ctx) => _PointCategoryEditorDialog(
        controller: controller,
        existing: category,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, int id) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('pointCategoriesTitle'.tr),
        content: Text('pointCategoryDeleteConfirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
    if (result == true) {
      await controller.deleteCategory(id);
    }
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EmployeePointCategoriesController>();

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
      child: Obx(() {
        final current = controller.filterOperationType.value;
        return Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _FilterChip(
              label: 'pointCategoryFilterAll'.tr,
              selected: current == null,
              onTap: () => controller.setOperationFilter(null),
              isDark: isDark,
            ),
            _FilterChip(
              label: 'pointCategoryFilterAdd'.tr,
              selected: current == 'add',
              onTap: () => controller.setOperationFilter('add'),
              isDark: isDark,
              accent: const Color(0xFF16A34A),
            ),
            _FilterChip(
              label: 'pointCategoryFilterDeduct'.tr,
              selected: current == 'deduct',
              onTap: () => controller.setOperationFilter('deduct'),
              isDark: isDark,
              accent: const Color(0xFFDC2626),
            ),
          ],
        );
      }),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
    this.accent,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final base = accent ?? AppColors.primaryColor;
    final bg = selected
        ? base.withValues(alpha: 0.16)
        : (isDark ? Colors.white12 : const Color(0xFFEEF0F3));
    final fg = selected
        ? base
        : (isDark ? Colors.white70 : const Color(0xFF374151));
    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.accent,
    required this.isDark,
  });

  final String title;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8.w,
          height: 18.h,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.isDark,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final EmployeePointCategoryModel category;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent =
        category.isAdd ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final cardColor = isDark ? AppColors.customGreyColor : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE5E7EB);
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              category.isAdd ? Icons.add_rounded : Icons.remove_rounded,
              color: accent,
              size: 22.sp,
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
                        category.nameAr,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: (category.isActive
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF9CA3AF))
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        category.isActive
                            ? 'pointCategoryActive'.tr
                            : 'pointCategoryInactive'.tr,
                        style: TextStyle(
                          color: category.isActive
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF6B7280),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (category.nameEn != null && category.nameEn!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text(
                      category.nameEn!,
                      style: TextStyle(fontSize: 12.sp, color: subColor),
                    ),
                  ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    _Pill(
                      icon: Icons.tag,
                      text: category.code,
                      isDark: isDark,
                    ),
                    SizedBox(width: 6.w),
                    _Pill(
                      icon: category.isAdd
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      text: '${category.defaultPoints}',
                      color: accent,
                      isDark: isDark,
                    ),
                  ],
                ),
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
                        category.isActive
                            ? Icons.toggle_on_rounded
                            : Icons.toggle_off_rounded,
                        size: 22,
                        color: accent,
                      ),
                      label: Text(category.isActive
                          ? 'pointCategoryInactive'.tr
                          : 'pointCategoryActive'.tr),
                      onPressed: onToggle,
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Color(0xFFDC2626)),
                      label: Text('delete'.tr,
                          style: const TextStyle(color: Color(0xFFDC2626))),
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

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.text,
    required this.isDark,
    this.color,
  });

  final IconData icon;
  final String text;
  final bool isDark;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = color ?? (isDark ? Colors.white70 : const Color(0xFF6B7280));
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: base),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              color: base,
              fontWeight: FontWeight.w700,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _PointCategoryEditorDialog extends StatefulWidget {
  const _PointCategoryEditorDialog({
    required this.controller,
    this.existing,
  });

  final EmployeePointCategoriesController controller;
  final EmployeePointCategoryModel? existing;

  @override
  State<_PointCategoryEditorDialog> createState() =>
      _PointCategoryEditorDialogState();
}

class _PointCategoryEditorDialogState
    extends State<_PointCategoryEditorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameArCtrl;
  late final TextEditingController _nameEnCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _pointsCtrl;
  late final TextEditingController _sortCtrl;
  late String _operationType;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _nameArCtrl = TextEditingController(text: c?.nameAr ?? '');
    _nameEnCtrl = TextEditingController(text: c?.nameEn ?? '');
    _codeCtrl = TextEditingController(text: c?.code ?? '');
    _pointsCtrl =
        TextEditingController(text: c?.defaultPoints.toString() ?? '');
    _sortCtrl = TextEditingController(text: c?.sortOrder.toString() ?? '0');
    _operationType = c?.operationType ?? 'add';
    _isActive = c?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameArCtrl.dispose();
    _nameEnCtrl.dispose();
    _codeCtrl.dispose();
    _pointsCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUpdate = widget.existing != null;
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
                      isUpdate ? Icons.edit_outlined : Icons.add_circle_outline,
                      color: AppColors.primaryColor,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        isUpdate
                            ? 'editPointCategory'.tr
                            : 'addPointCategory'.tr,
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
                  controller: _nameArCtrl,
                  decoration: _decoration('pointCategoryNameAr'.tr),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'pointCategoryNameRequired'.tr
                      : null,
                ),
                SizedBox(height: 10.h),
                TextFormField(
                  controller: _nameEnCtrl,
                  decoration: _decoration('pointCategoryNameEn'.tr),
                ),
                SizedBox(height: 10.h),
                TextFormField(
                  controller: _codeCtrl,
                  decoration: _decoration(
                    'pointCategoryCode'.tr,
                    hint: 'pointCategoryCodeHint'.tr,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'pointCategoryCodeRequired'.tr
                      : null,
                ),
                SizedBox(height: 10.h),
                DropdownButtonFormField<String>(
                  initialValue: _operationType,
                  decoration:
                      _decoration('pointCategoryOperationType'.tr),
                  items: [
                    DropdownMenuItem(
                      value: 'add',
                      child: Text('pointCategoryOpAdd'.tr),
                    ),
                    DropdownMenuItem(
                      value: 'deduct',
                      child: Text('pointCategoryOpDeduct'.tr),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _operationType = v ?? 'add'),
                ),
                SizedBox(height: 10.h),
                TextFormField(
                  controller: _pointsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('pointCategoryDefaultPoints'.tr),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'pointCategoryPointsRequired'.tr;
                    }
                    final n = int.tryParse(v.trim());
                    if (n == null || n < 1) {
                      return 'pointCategoryPointsRequired'.tr;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10.h),
                TextFormField(
                  controller: _sortCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('pointCategorySortOrder'.tr),
                ),
                SizedBox(height: 6.h),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text('pointCategoryActive'.tr),
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
                            backgroundColor: AppColors.primaryColor,
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

    final nameAr = _nameArCtrl.text.trim();
    final nameEn = _nameEnCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    final points = int.parse(_pointsCtrl.text.trim());
    final sort = int.tryParse(_sortCtrl.text.trim()) ?? 0;

    final isUpdate = widget.existing != null;
    bool ok;
    if (isUpdate) {
      ok = await widget.controller.updateCategory(
        id: widget.existing!.id,
        nameAr: nameAr,
        nameEn: nameEn.isEmpty ? null : nameEn,
        code: code,
        operationType: _operationType,
        defaultPoints: points,
        isActive: _isActive,
        sortOrder: sort,
      );
    } else {
      ok = await widget.controller.createCategory(
        nameAr: nameAr,
        nameEn: nameEn.isEmpty ? null : nameEn,
        code: code,
        operationType: _operationType,
        defaultPoints: points,
        isActive: _isActive,
        sortOrder: sort,
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
