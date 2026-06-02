import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
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
  final formKey = GlobalKey<FormState>();
  final messageController = TextEditingController();
  final daysController = TextEditingController(text: '0');
  String type = 'before_due';
  String triggerMode = 'at_time';
  TimeOfDay sendTime = const TimeOfDay(hour: 9, minute: 0);
  bool isActive = true;
  int? editingId;
  bool loading = false;
  List<Map<String, dynamic>> rules = [];

  bool get isBeforeDue => type == 'before_due';
  bool get showDaysField => isBeforeDue || triggerMode == 'at_time';

  String get daysLabelKey => isBeforeDue ? 'daysBeforeDue' : 'daysAfterAction';

  String get daysHintKey =>
      isBeforeDue ? 'daysBeforeDueHint' : 'daysAfterActionHint';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    messageController.dispose();
    daysController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final response = await api.get(EndPoints.checkNotificationRules);
    final raw = response.data['rules'];
    rules = raw is List
        ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : [];
    setState(() => loading = false);
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    final data = {
      'type': type,
      'days': showDaysField ? int.tryParse(daysController.text.trim()) ?? 0 : 0,
      'trigger_mode': triggerMode,
      'send_time': triggerMode == 'at_time'
          ? '${sendTime.hour.toString().padLeft(2, '0')}:${sendTime.minute.toString().padLeft(2, '0')}'
          : null,
      'message': messageController.text.trim(),
      'is_active': isActive,
    };
    if (editingId == null) {
      await api.post(EndPoints.checkNotificationRules, data: data);
    } else {
      await api.put(EndPoints.checkNotificationRule(editingId!), data: data);
    }
    _resetForm();
    await _load();
  }

  Future<void> _delete(int id) async {
    await api.delete(EndPoints.checkNotificationRule(id));
    await _load();
  }

  void _edit(Map<String, dynamic> rule) {
    editingId = int.tryParse(rule['id'].toString());
    type = rule['type']?.toString() ?? 'before_due';
    triggerMode = rule['trigger_mode']?.toString() ?? 'at_time';
    if (type == 'before_due') triggerMode = 'at_time';
    daysController.text = rule['days']?.toString() ?? '0';
    messageController.text = rule['message']?.toString() ?? '';
    isActive = rule['is_active'] == true || rule['is_active'] == 1;
    final time = rule['send_time']?.toString();
    if (time != null && time.contains(':')) {
      final parts = time.split(':');
      sendTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    setState(() {});
  }

  void _resetForm() {
    editingId = null;
    type = 'before_due';
    triggerMode = 'at_time';
    daysController.text = '0';
    messageController.clear();
    sendTime = const TimeOfDay(hour: 9, minute: 0);
    isActive = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'checkNotifications'.tr, action: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _form(context),
            SizedBox(height: 20.h),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else
              ...rules.map(_ruleCard),
          ],
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    return Form(
      key: formKey,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              editingId == null ? 'addCheckNotification'.tr : 'edit'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 12.h),
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: InputDecoration(labelText: 'notificationType'.tr),
              items: const ['before_due', 'cashed', 'returned']
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(('checkNotif_$item').tr),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  type = value ?? type;
                  if (type == 'before_due') {
                    triggerMode = 'at_time';
                  }
                });
              },
            ),
            SizedBox(height: 12.h),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'at_time',
                  label: Text('atSpecificTime'.tr),
                  icon: const Icon(Icons.schedule),
                ),
                if (!isBeforeDue)
                  ButtonSegment(
                    value: 'on_action',
                    label: Text('onActionImmediately'.tr),
                    icon: const Icon(Icons.flash_on),
                  ),
              ],
              selected: {triggerMode},
              onSelectionChanged: (value) {
                setState(() => triggerMode = value.first);
              },
            ),
            if (isBeforeDue) ...[
              SizedBox(height: 8.h),
              _HintText(text: 'beforeDueNeedsTime'.tr),
            ],
            if (showDaysField && triggerMode == 'at_time') ...[
              SizedBox(height: 12.h),
              _DaysAndTimeRow(
                daysLabelKey: daysLabelKey,
                daysHintKey: daysHintKey,
                daysController: daysController,
                sendTime: sendTime,
                onTimeTap: () => _pickSendTime(context),
              ),
            ] else if (showDaysField) ...[
              SizedBox(height: 12.h),
              SizedBox(
                width: 150.w,
                child: CustomTextField(
                  label: daysLabelKey,
                  hintText: daysHintKey,
                  controller: daysController,
                  keyboardType: TextInputType.number,
                  isRequired: true,
                ),
              ),
            ] else ...[
              SizedBox(height: 8.h),
              _HintText(text: 'immediateActionIgnoresDays'.tr),
            ],
            SizedBox(height: 12.h),
            CustomTextField(
              label: 'smsMessageText',
              hintText: 'smsMessageText',
              controller: messageController,
              keyboardType: TextInputType.multiline,
              minLines: 4,
              maxLines: 5,
              isRequired: true,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: isActive,
              title: Text('checkNotificationActive'.tr),
              onChanged: (value) => setState(() => isActive = value),
            ),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    isSafeArea: false,
                    text: 'save',
                    onPressed: _save,
                  ),
                ),
                if (editingId != null) ...[
                  SizedBox(width: 10.w),
                  Expanded(
                    child: AppButton(
                      isSafeArea: false,
                      color: Colors.grey,
                      text: 'cancel',
                      onPressed: _resetForm,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickSendTime(BuildContext context) async {
    final picked = await HorizontalTimePickerSheet.show(
      context,
      initial: sendTime,
    );
    if (picked != null) setState(() => sendTime = picked);
  }

  Widget _ruleCard(Map<String, dynamic> rule) {
    final active = rule['is_active'] == true || rule['is_active'] == 1;
    final ruleType = rule['type']?.toString() ?? 'before_due';
    final ruleTriggerMode = rule['trigger_mode']?.toString() ?? 'at_time';
    final ruleDaysLabel =
        ruleType == 'before_due' ? 'daysBeforeDue'.tr : 'daysAfterAction'.tr;
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ('checkNotif_${rule['type']}').tr,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _edit(rule),
                icon: const Icon(Icons.edit),
              ),
              IconButton(
                onPressed: () => _delete(int.parse(rule['id'].toString())),
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
          if (ruleType == 'before_due' || ruleTriggerMode == 'at_time')
            Text('$ruleDaysLabel: ${rule['days']}'),
          Text(
            ruleTriggerMode == 'on_action'
                ? 'onActionImmediately'.tr
                : '${'atSpecificTime'.tr}: ${rule['send_time'] ?? ''}',
          ),
          SizedBox(height: 8.h),
          Text(rule['message']?.toString() ?? ''),
          SizedBox(height: 8.h),
          _StatusPill(
            text: active ? 'checkNotificationActive'.tr : 'notActive'.tr,
            active: active,
          ),
        ],
      ),
    );
  }
}

class _DaysAndTimeRow extends StatelessWidget {
  const _DaysAndTimeRow({
    required this.daysLabelKey,
    required this.daysHintKey,
    required this.daysController,
    required this.sendTime,
    required this.onTimeTap,
  });

  final String daysLabelKey;
  final String daysHintKey;
  final TextEditingController daysController;
  final TimeOfDay sendTime;
  final VoidCallback onTimeTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 142.w,
          child: CustomTextField(
            label: daysLabelKey,
            hintText: daysHintKey,
            controller: daysController,
            keyboardType: TextInputType.number,
            isRequired: true,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _TimePickerTile(
            label: 'time'.tr,
            value: _formatTime(sendTime),
            onTap: onTimeTap,
          ),
        ),
      ],
    );
  }

  static String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'morning'.tr : 'evening'.tr;
    return '${hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')} $period';
  }
}

class _TimePickerTile extends StatelessWidget {
  const _TimePickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.customGreyColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        Material(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(8.r),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 18.sp,
                    color: AppColors.primaryColor,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HintText extends StatelessWidget {
  const _HintText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey.shade700,
        fontSize: 12.5.sp,
        height: 1.4,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.active});

  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF166534) : Colors.grey.shade700;
    final background = active ? const Color(0xFFEAF7EF) : Colors.grey.shade100;
    final border = active ? const Color(0xFFBBE7C8) : Colors.grey.shade300;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
