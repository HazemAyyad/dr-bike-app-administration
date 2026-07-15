import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:doctorbike/core/services/theme_service.dart';
import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:doctorbike/features/employee_suggestions/data/employee_suggestions_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class _SuggestionPalette {
  static const page = Color(0xffeef0f2);
  static const sheet = Color(0xffe9ecef);
  static const card = Color(0xfff1f3f5);
  static const chip = Color(0xffe2e6ea);
  static const selected = Color(0xffd7dce1);
  static const border = Color(0xffccd2d8);
  static const action = Color(0xff4b5560);
  static const actionText = Color(0xffeef0f2);
  static const ink = Color(0xff252a31);
  static const muted = Color(0xff66717d);
  static const darkCard = Color(0xff303030);
}

class EmployeeSuggestionsScreen extends StatefulWidget {
  final bool isAdmin;

  const EmployeeSuggestionsScreen({Key? key, required this.isAdmin})
      : super(key: key);

  @override
  State<EmployeeSuggestionsScreen> createState() =>
      _EmployeeSuggestionsScreenState();
}

class _EmployeeSuggestionsScreenState extends State<EmployeeSuggestionsScreen> {
  late final EmployeeSuggestionsService service;
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final messageController = TextEditingController();
  final adminNoteController = TextEditingController();
  final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  List<EmployeeSuggestionItem> suggestions = [];
  bool loading = true;
  bool saving = false;
  bool deleting = false;
  bool isAnonymous = false;
  String category = 'suggestion';
  String statusFilter = 'all';
  int? editingSuggestionId;

  static const categories = [
    'suggestion',
    'problem',
    'criticism',
    'improvement',
    'other',
  ];

  static const statuses = ['all', 'new', 'reviewed', 'closed'];

  @override
  void initState() {
    super.initState();
    service = EmployeeSuggestionsService(api: Get.find<DioConsumer>());
    _load();
  }

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    adminNoteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      suggestions = await service.getSuggestions(
        isAdmin: widget.isAdmin,
        status: statusFilter == 'all' ? null : statusFilter,
      );
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _submit([StateSetter? setSheetState]) async {
    if (saving) return;
    if (!(formKey.currentState?.validate() ?? false)) {
      _message('suggestionMessageRequired'.tr);
      return;
    }
    _setSaving(true, setSheetState);
    try {
      final wasEditing = editingSuggestionId != null;
      if (editingSuggestionId == null) {
        await service.createSuggestion(
          category: category,
          title: titleController.text.trim(),
          message: messageController.text.trim(),
          isAnonymous: isAnonymous,
        );
      } else {
        await service.updateMySuggestion(
          id: editingSuggestionId!,
          category: category,
          title: titleController.text.trim(),
          message: messageController.text.trim(),
          isAnonymous: isAnonymous,
        );
      }
      titleController.clear();
      messageController.clear();
      isAnonymous = false;
      category = 'suggestion';
      editingSuggestionId = null;
      await _load();
      if (mounted) Navigator.pop(context);
      _message((wasEditing ? 'suggestionUpdated' : 'suggestionSent').tr);
    } catch (e) {
      _message(e.toString());
    } finally {
      _setSaving(false, setSheetState);
    }
  }

  void _setSaving(bool value, [StateSetter? setSheetState]) {
    if (!mounted) return;
    setState(() => saving = value);
    setSheetState?.call(() {});
  }

  Future<void> _deleteSuggestion(EmployeeSuggestionItem item) async {
    if (deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _SuggestionPalette.sheet,
        title: Text('deleteSuggestionTitle'.tr),
        content: Text('deleteSuggestionMessage'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'delete'.tr,
              style: const TextStyle(color: _SuggestionPalette.ink),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => deleting = true);
    try {
      await service.deleteMySuggestion(item.id);
      await _load();
      _message('suggestionDeleted'.tr);
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }

  Future<void> _updateStatus(EmployeeSuggestionItem item, String status) async {
    try {
      await service.updateSuggestion(
        id: item.id,
        status: status,
        adminNote: adminNoteController.text.trim(),
      );
      adminNoteController.clear();
      await _load();
      if (mounted) Navigator.pop(context);
      _message('suggestionUpdated'.tr);
    } catch (e) {
      _message(e.toString());
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _openCreateSheet({EmployeeSuggestionItem? item}) {
    editingSuggestionId = item?.id;
    titleController.text = item?.title ?? '';
    messageController.text = item?.message ?? '';
    category = item?.category ?? 'suggestion';
    isAnonymous = item?.isAnonymous ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: ThemeService.isDark.value
                    ? AppColors.darkColor
                    : _SuggestionPalette.sheet,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        (editingSuggestionId == null
                                ? 'newSuggestion'
                                : 'editSuggestionTitle')
                            .tr,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondaryColor,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 6.h,
                        children: categories.map((value) {
                          final selected = category == value;
                          return ChoiceChip(
                            label: Text(('suggestionCategory_$value').tr),
                            selected: selected,
                            selectedColor: _SuggestionPalette.selected,
                            backgroundColor: _SuggestionPalette.chip,
                            side: const BorderSide(
                              color: _SuggestionPalette.border,
                            ),
                            labelStyle: const TextStyle(
                              color: _SuggestionPalette.ink,
                              fontWeight: FontWeight.w700,
                            ),
                            onSelected: (_) {
                              setState(() => category = value);
                              setSheet(() {});
                            },
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 10.h),
                      CustomTextField(
                        label: 'suggestionTitle',
                        hintText: 'suggestionTitleHint',
                        controller: titleController,
                        validator: (_) => null,
                      ),
                      SizedBox(height: 8.h),
                      CustomTextField(
                        isRequired: true,
                        label: 'suggestionMessage',
                        hintText: 'suggestionMessageHint',
                        controller: messageController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'suggestionMessageRequired'.tr;
                          }
                          return null;
                        },
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        minLines: 5,
                        maxLines: 10,
                      ),
                      SwitchListTile.adaptive(
                        value: isAnonymous,
                        onChanged: (value) {
                          setState(() => isAnonymous = value);
                          setSheet(() {});
                        },
                        title: Text('hideMyName'.tr),
                        subtitle: Text('hideMyNameHint'.tr),
                      ),
                      SizedBox(height: 8.h),
                      _GreyActionButton(
                        label: (editingSuggestionId == null
                                ? 'sendSuggestion'
                                : 'saveSuggestion')
                            .tr,
                        loading: saving,
                        icon: editingSuggestionId == null
                            ? Icons.send_rounded
                            : Icons.save_rounded,
                        onTap: saving ? null : () => _submit(setSheet),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openAdminSheet(EmployeeSuggestionItem item) {
    adminNoteController.text = item.adminNote;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: _SuggestionPalette.sheet,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.title.isEmpty ? 'suggestionBox'.tr : item.title,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondaryColor,
                ),
              ),
              SizedBox(height: 8.h),
              Text(item.message),
              SizedBox(height: 12.h),
              CustomTextField(
                label: 'adminNote',
                hintText: 'adminNoteHint',
                controller: adminNoteController,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 3,
                maxLines: 6,
                validator: (_) => null,
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: _StatusButton(
                      label: 'suggestionStatus_reviewed'.tr,
                      color: _SuggestionPalette.selected,
                      onTap: () => _updateStatus(item, 'reviewed'),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _StatusButton(
                      label: 'suggestionStatus_closed'.tr,
                      color: _SuggestionPalette.chip,
                      onTap: () => _updateStatus(item, 'closed'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : _SuggestionPalette.page,
      appBar: CustomAppBar(
        title: 'suggestionBox'.tr,
        action: false,
        backgroundColor: ThemeService.isDark.value
            ? AppColors.darkColor
            : _SuggestionPalette.page,
        surfaceTintColor: ThemeService.isDark.value
            ? AppColors.darkColor
            : _SuggestionPalette.page,
      ),
      floatingActionButton: widget.isAdmin
          ? null
          : FloatingActionButton.small(
              onPressed: _openCreateSheet,
              backgroundColor: _SuggestionPalette.action,
              foregroundColor: _SuggestionPalette.actionText,
              child: const Icon(Icons.add),
            ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 80.h),
          children: [
            if (widget.isAdmin)
              SizedBox(
                height: 32.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: statuses.length,
                  separatorBuilder: (_, __) => SizedBox(width: 6.w),
                  itemBuilder: (context, index) {
                    final value = statuses[index];
                    return _FilterPill(
                      label: ('suggestionStatus_$value').tr,
                      selected: statusFilter == value,
                      onTap: () {
                        setState(() => statusFilter = value);
                        _load();
                      },
                    );
                  },
                ),
              ),
            if (widget.isAdmin) SizedBox(height: 8.h),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (suggestions.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 80.h),
                child: Center(child: Text('suggestionsEmpty'.tr)),
              )
            else
              ...suggestions.map(
                (item) => _SuggestionCard(
                  item: item,
                  isAdmin: widget.isAdmin,
                  dateLabel: item.createdAt == null
                      ? ''
                      : dateFormat.format(item.createdAt!),
                  onTap: widget.isAdmin ? () => _openAdminSheet(item) : null,
                  onEdit: widget.isAdmin
                      ? null
                      : () => _openCreateSheet(item: item),
                  onDelete:
                      widget.isAdmin ? null : () => _deleteSuggestion(item),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.item,
    required this.isAdmin,
    required this.dateLabel,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final EmployeeSuggestionItem item;
  final bool isAdmin;
  final String dateLabel;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final title = item.title.isEmpty
        ? ('suggestionCategory_${item.category}').tr
        : item.title;
    final statusColor = _statusColor(item.status);

    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      decoration: BoxDecoration(
        color: isDark ? _SuggestionPalette.darkCard : _SuggestionPalette.card,
        borderRadius: BorderRadius.circular(7.r),
        border: Border.all(
          color:
              isDark ? AppColors.customGreyColor4 : _SuggestionPalette.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        color: isDark
                            ? AppColors.customGreyColor7
                            : _SuggestionPalette.ink,
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  _Chip(
                    label: ('suggestionStatus_${item.status}').tr,
                    color: statusColor,
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              Text(
                item.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5.sp,
                  height: 1.25,
                  color: isDark
                      ? AppColors.customGreyColor7
                      : _SuggestionPalette.muted,
                ),
              ),
              SizedBox(height: 5.h),
              Wrap(
                spacing: 4.w,
                runSpacing: 3.h,
                children: [
                  _Chip(
                    label: ('suggestionCategory_${item.category}').tr,
                    icon: Icons.label_outline,
                  ),
                  if (isAdmin)
                    _Chip(
                      label: item.employeeName.isEmpty
                          ? 'anonymousEmployee'.tr
                          : item.employeeName,
                      icon: item.isAnonymous
                          ? Icons.visibility_off_outlined
                          : Icons.person_outline,
                    ),
                  if (dateLabel.isNotEmpty)
                    _Chip(label: dateLabel, icon: Icons.access_time),
                ],
              ),
              if (item.adminNote.isNotEmpty) ...[
                SizedBox(height: 5.h),
                Text(
                  '${'adminNote'.tr}: ${item.adminNote}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    height: 1.2,
                    color: AppColors.customGreyColor5,
                  ),
                ),
              ],
              if (!isAdmin) ...[
                SizedBox(height: 6.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _CardAction(
                      label: 'editSuggestion'.tr,
                      icon: Icons.edit_outlined,
                      onTap: onEdit,
                    ),
                    SizedBox(width: 6.w),
                    _CardAction(
                      label: 'deleteSuggestion'.tr,
                      icon: Icons.delete_outline,
                      onTap: onDelete,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'closed':
        return const Color(0xff58616b);
      case 'reviewed':
        return const Color(0xff4b5560);
      default:
        return const Color(0xff343a40);
    }
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: _SuggestionPalette.chip,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: _SuggestionPalette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12.sp, color: _SuggestionPalette.muted),
            SizedBox(width: 3.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: _SuggestionPalette.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.icon, this.color});

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.customGreyColor5;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: _SuggestionPalette.chip,
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(color: _SuggestionPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10.sp, color: effectiveColor),
            SizedBox(width: 2.w),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5.sp,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? _SuggestionPalette.selected : _SuggestionPalette.chip;
    final textColor = _SuggestionPalette.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color:
                selected ? _SuggestionPalette.muted : _SuggestionPalette.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(color: _SuggestionPalette.ink),
      ),
    );
  }
}

class _GreyActionButton extends StatelessWidget {
  const _GreyActionButton({
    required this.label,
    required this.loading,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool loading;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: loading ? null : onTap,
      child: Container(
        height: 42.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: loading ? _SuggestionPalette.muted : _SuggestionPalette.action,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: _SuggestionPalette.ink),
        ),
        child: loading
            ? SizedBox(
                width: 18.w,
                height: 18.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _SuggestionPalette.actionText,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 16.sp,
                      color: _SuggestionPalette.actionText,
                    ),
                    SizedBox(width: 6.w),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: _SuggestionPalette.actionText,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
