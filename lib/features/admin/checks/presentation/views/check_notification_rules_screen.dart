import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/errors/expentions.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:doctorbike/core/services/theme_service.dart';
import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:doctorbike/features/admin/create_tasks/presentation/widgets/horizontal_time_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class CheckNotificationRulesScreen extends StatefulWidget {
  const CheckNotificationRulesScreen({Key? key}) : super(key: key);

  @override
  State<CheckNotificationRulesScreen> createState() =>
      _CheckNotificationRulesScreenState();
}

class _CheckNotificationRulesScreenState
    extends State<CheckNotificationRulesScreen> {
  final api = Get.find<DioConsumer>();
  bool loading = false;
  List<Map<String, dynamic>> rules = [];

  Color get _accentColor => ThemeService.isDark.value
      ? AppColors.primaryColor
      : AppColors.secondaryColor;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final response = await api.get(EndPoints.checkNotificationRules);
      final raw = response.data['rules'];
      rules = raw is List
          ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : [];
    } on ServerException catch (e) {
      Get.snackbar(
        'error'.tr,
        e.errorModel.errorMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _delete(int id) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('confirmDelete'.tr),
        content: Text('confirmDeleteCheckNotification'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'delete'.tr,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await api.delete(EndPoints.checkNotificationRule(id));
      await _load();
      Get.snackbar(
        'success'.tr,
        'settingsUpdated'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } on ServerException catch (e) {
      Get.snackbar(
        'error'.tr,
        e.errorModel.errorMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _openFormModal({Map<String, dynamic>? rule}) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: _CheckNotificationRuleSheet(
          accentColor: _accentColor,
          initialRule: rule,
          onSaved: _load,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'checkNotifications'.tr,
        action: false,
        actions: [
          IconButton(
            tooltip: 'addCheckNotification'.tr,
            onPressed: () => _openFormModal(),
            icon: Icon(
              Icons.add_circle_outline,
              color: _accentColor,
              size: 26.sp,
            ),
          ),
          SizedBox(width: 6.w),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openFormModal(),
        backgroundColor: _accentColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'addCheckNotification'.tr,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : rules.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Text(
                      'noCheckNotificationsYet'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 88.h),
                  itemCount: rules.length + 1,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (_, index) {
                    if (index == 0) {
                      return Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _accentColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          'checkNotificationChannelHint'.tr,
                          style: TextStyle(
                            fontSize: 12.sp,
                            height: 1.45,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      );
                    }

                    final rule = rules[index - 1];
                    return _RuleCard(
                      rule: rule,
                      onEdit: () => _openFormModal(rule: rule),
                      onDelete: () =>
                          _delete(int.parse(rule['id'].toString())),
                    );
                  },
                ),
    );
  }
}

class _CheckNotificationRuleSheet extends StatefulWidget {
  const _CheckNotificationRuleSheet({
    required this.accentColor,
    required this.onSaved,
    this.initialRule,
  });

  final Color accentColor;
  final Map<String, dynamic>? initialRule;
  final Future<void> Function() onSaved;

  @override
  State<_CheckNotificationRuleSheet> createState() =>
      _CheckNotificationRuleSheetState();
}

class _CheckNotificationRuleSheetState extends State<_CheckNotificationRuleSheet> {
  final api = Get.find<DioConsumer>();
  final formKey = GlobalKey<FormState>();
  late final TextEditingController messageController;
  late final TextEditingController daysController;
  late String type;
  late String triggerMode;
  late TimeOfDay sendTime;
  late bool isActive;
  int? editingId;
  bool saving = false;

  bool get isBeforeDue => type == 'before_due';
  bool get showDaysField => isBeforeDue || triggerMode == 'at_time';
  bool get showTriggerMode => !isBeforeDue;
  bool get isEdit => editingId != null;

  @override
  void initState() {
    super.initState();
    final rule = widget.initialRule;
    editingId = rule != null ? int.tryParse(rule['id'].toString()) : null;
    type = rule?['type']?.toString() ?? 'before_due';
    triggerMode = rule?['trigger_mode']?.toString() ?? 'at_time';
    if (type == 'before_due') triggerMode = 'at_time';
    daysController = TextEditingController(text: rule?['days']?.toString() ?? '0');
    messageController =
        TextEditingController(text: rule?['message']?.toString() ?? '');
    isActive = rule == null ||
        rule['is_active'] == true ||
        rule['is_active'] == 1;
    sendTime = const TimeOfDay(hour: 9, minute: 0);
    final time = rule?['send_time']?.toString();
    if (time != null && time.contains(':')) {
      final parts = time.split(':');
      sendTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    daysController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => saving = true);
    try {
      final data = {
        'type': type,
        'days':
            showDaysField ? int.tryParse(daysController.text.trim()) ?? 0 : 0,
        'trigger_mode': isBeforeDue ? 'at_time' : triggerMode,
        'send_time': (isBeforeDue || triggerMode == 'at_time')
            ? '${sendTime.hour.toString().padLeft(2, '0')}:${sendTime.minute.toString().padLeft(2, '0')}'
            : null,
        'message': messageController.text.trim(),
        'is_active': isActive,
      };

      final response = editingId == null
          ? await api.post(EndPoints.checkNotificationRules, data: data)
          : await api.put(
              EndPoints.checkNotificationRule(editingId!),
              data: data,
            );

      final body = response.data;
      if (body is Map && body['status']?.toString() == 'error') {
        final message = body['message']?.toString() ?? 'error'.tr;
        Get.snackbar('error'.tr, message, snackPosition: SnackPosition.BOTTOM);
        return;
      }

      final message = body is Map && body['message'] != null
          ? body['message'].toString()
          : 'checkNotificationSavedHint'.tr;

      await widget.onSaved();
      if (mounted) Navigator.of(context).pop(true);
      Get.snackbar('success'.tr, message, snackPosition: SnackPosition.BOTTOM);
    } on ServerException catch (e) {
      Get.snackbar(
        'error'.tr,
        e.errorModel.errorMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  InputDecoration _compactInput(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 13.sp),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Future<void> _pickSendTime() async {
    final picked = await HorizontalTimePickerSheet.show(
      context,
      initial: sendTime,
    );
    if (picked != null) setState(() => sendTime = picked);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'morning'.tr : 'evening'.tr;
    return '${hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 8.w, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isEdit ? 'edit'.tr : 'addCheckNotification'.tr,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: saving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Flexible(
            child: Form(
              key: formKey,
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                children: [
                    DropdownButtonFormField<String>(
                      value: type,
                      isExpanded: true,
                      decoration: _compactInput('notificationType'.tr),
                      items: const ['before_due', 'cashed', 'returned']
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(
                                ('checkNotif_$item').tr,
                                style: TextStyle(fontSize: 13.sp),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          type = value ?? type;
                          if (type == 'before_due') triggerMode = 'at_time';
                        });
                      },
                    ),
                    if (showTriggerMode) ...[
                      SizedBox(height: 10.h),
                      DropdownButtonFormField<String>(
                        value: triggerMode,
                        isExpanded: true,
                        decoration: _compactInput('notificationTiming'.tr),
                        items: [
                          DropdownMenuItem(
                            value: 'at_time',
                            child: Text(
                              'atSpecificTime'.tr,
                              style: TextStyle(fontSize: 13.sp),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'on_action',
                            child: Text(
                              'onActionImmediately'.tr,
                              style: TextStyle(fontSize: 13.sp),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => triggerMode = value ?? triggerMode);
                        },
                      ),
                    ],
                    if (showDaysField && triggerMode == 'at_time') ...[
                      SizedBox(height: 10.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 96.w,
                            child: CustomTextField(
                              label: 'daysCount',
                              hintText: 'daysCountHint',
                              controller: daysController,
                              keyboardType: TextInputType.number,
                              isRequired: true,
                              sizedBox: false,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: _CompactTimeTile(
                              value: _formatTime(sendTime),
                              onTap: _pickSendTime,
                            ),
                          ),
                        ],
                      ),
                    ] else if (showDaysField) ...[
                      SizedBox(height: 10.h),
                      SizedBox(
                        width: 96.w,
                        child: CustomTextField(
                          label: 'daysCount',
                          hintText: 'daysCountHint',
                          controller: daysController,
                          keyboardType: TextInputType.number,
                          isRequired: true,
                          sizedBox: false,
                        ),
                      ),
                    ],
                    SizedBox(height: 10.h),
                    CustomTextField(
                      label: 'smsMessageText',
                      hintText: 'checkNotificationMessageHint',
                      controller: messageController,
                      keyboardType: TextInputType.multiline,
                      minLines: 2,
                      maxLines: 4,
                      isRequired: true,
                      sizedBox: false,
                    ),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      value: isActive,
                      title: Text(
                        'checkNotificationActive'.tr,
                        style: TextStyle(fontSize: 13.sp),
                      ),
                      onChanged: (value) => setState(() => isActive = value),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: FilledButton.icon(
                    onPressed: saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: saving
                        ? SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.save, size: 20.sp),
                    label: Text(
                      'save'.tr,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
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
    required this.onDelete,
  });

  final Map<String, dynamic> rule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final active = rule['is_active'] == true || rule['is_active'] == 1;
    final ruleTriggerMode = rule['trigger_mode']?.toString() ?? 'at_time';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ('checkNotif_${rule['type']}').tr,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  ruleTriggerMode == 'on_action'
                      ? 'onActionImmediately'.tr
                      : '${rule['days']} ${'daysCount'.tr} · ${rule['send_time'] ?? ''}',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  rule['message']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  active ? 'checkNotificationActive'.tr : 'notActive'.tr,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: active ? const Color(0xFF166534) : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onEdit,
            icon: Icon(Icons.edit, size: 18.sp),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, size: 18.sp, color: Colors.red),
          ),
        ],
      ),
    );
  }
}

class _CompactTimeTile extends StatelessWidget {
  const _CompactTimeTile({
    required this.value,
    required this.onTap,
  });

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'time'.tr,
          style: TextStyle(
            color: AppColors.customGreyColor,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6.h),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 11.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              color: AppColors.whiteColor,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16.sp,
                  color: AppColors.primaryColor,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
