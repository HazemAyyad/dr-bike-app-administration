import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/smart_home_api_service.dart';
import '../../data/tuya_device_capability_resolver.dart';
import '../controllers/smart_home_controller.dart';

class SmartScenesSection extends StatelessWidget {
  const SmartScenesSection({Key? key, required this.controller})
      : super(key: key);

  final SmartHomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final scenes = controller.visibleScenes;
      if (scenes.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'المشاهد',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: () => Get.to<void>(
                  () => SmartSceneEditorScreen(controller: controller),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة مشهد'),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ...scenes.map(
            (scene) => _SceneCard(controller: controller, scene: scene),
          ),
          SizedBox(height: 8.h),
        ],
      );
    });
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({required this.controller, required this.scene});

  final SmartHomeController controller;
  final SmartSceneModel scene;

  @override
  Widget build(BuildContext context) {
    final color = _hexColor(scene.color);
    final subtitle = scene.isManual
        ? '${scene.actions.length} أوامر • تشغيل يدوي'
        : '${scene.conditions.length} شروط • ${scene.actions.length} أوامر';
    final busy = controller.sceneBusyIds.contains(scene.id);
    return Card(
      margin: EdgeInsets.only(bottom: 9.h),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: scene.isManual && !busy
            ? () async {
                final ok = await controller.executeScene(scene);
                if (ok) Get.snackbar('تم', 'تم تشغيل المشهد بنجاح');
              }
            : null,
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  scene.isManual
                      ? Icons.play_arrow_rounded
                      : scene.triggerType == 'schedule'
                          ? Icons.schedule_rounded
                          : Icons.bolt_rounded,
                  color: color,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scene.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    SizedBox(height: 4.h),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (busy)
                SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              else if (scene.isManual)
                IconButton(
                  tooltip: 'تشغيل',
                  onPressed: () => controller.executeScene(scene),
                  icon: const Icon(Icons.play_circle_fill_rounded),
                  color: color,
                )
              else
                Switch.adaptive(
                  value: scene.enabled,
                  onChanged: (value) =>
                      controller.setSceneEnabled(scene, value),
                ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    await Get.to<void>(() => SmartSceneEditorScreen(
                          controller: controller,
                          existing: scene,
                        ));
                  } else if (value == 'delete') {
                    final confirmed = await Get.dialog<bool>(AlertDialog(
                      title: const Text('حذف المشهد؟'),
                      content: Text('سيتم حذف ${scene.name} من التطبيق وTuya.'),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(result: false),
                          child: const Text('إلغاء'),
                        ),
                        FilledButton(
                          onPressed: () => Get.back(result: true),
                          child: const Text('حذف'),
                        ),
                      ],
                    ));
                    if (confirmed == true) await controller.deleteScene(scene);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('تعديل')),
                  PopupMenuItem(value: 'delete', child: Text('حذف')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SmartSceneEditorScreen extends StatefulWidget {
  const SmartSceneEditorScreen({
    Key? key,
    required this.controller,
    this.existing,
  }) : super(key: key);

  final SmartHomeController controller;
  final SmartSceneModel? existing;

  @override
  State<SmartSceneEditorScreen> createState() => _SmartSceneEditorScreenState();
}

class _SmartSceneEditorScreenState extends State<SmartSceneEditorScreen> {
  late final TextEditingController nameController;
  late String triggerType;
  late String matchType;
  late bool enabled;
  late bool showOnHome;
  int? roomId;
  bool saving = false;
  late List<Map<String, dynamic>> conditions;
  late List<Map<String, dynamic>> actions;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    nameController = TextEditingController(text: existing?.name ?? '');
    triggerType = existing?.triggerType ?? 'manual';
    matchType = existing?.matchType ?? 'all';
    enabled = existing?.enabled ?? true;
    showOnHome = existing?.showOnHome ?? true;
    roomId = existing?.smartRoomId;
    conditions = existing?.conditions
            .map((item) => Map<String, dynamic>.from(item))
            .toList() ??
        [];
    actions = existing?.actions
            .map((item) => Map<String, dynamic>.from(item))
            .toList() ??
        [];
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'إضافة مشهد' : 'تعديل المشهد'),
      ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 14.h),
        child: FilledButton(
          onPressed: saving ? null : _save,
          child: saving
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('حفظ المشهد'),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(18.w),
        children: [
          TextField(
            controller: nameController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'اسم المشهد',
              hintText: 'مثال: إطفاء كل إضاءة المكتب',
              prefixIcon: Icon(Icons.auto_awesome_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 18.h),
          Text('كيف يتم تشغيل المشهد؟',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  )),
          SizedBox(height: 9.h),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'manual',
                icon: Icon(Icons.touch_app_rounded),
                label: Text('يدوي'),
              ),
              ButtonSegment(
                value: 'schedule',
                icon: Icon(Icons.schedule_rounded),
                label: Text('مؤقت'),
              ),
              ButtonSegment(
                value: 'device',
                icon: Icon(Icons.sensors_rounded),
                label: Text('جهاز'),
              ),
            ],
            selected: {triggerType},
            onSelectionChanged: (selection) {
              setState(() {
                triggerType = selection.first;
                conditions.clear();
              });
            },
          ),
          if (triggerType != 'manual') ...[
            SizedBox(height: 18.h),
            _EditorSection(
              title: 'إذا',
              subtitle: conditions.isEmpty
                  ? 'أضف شرط تشغيل المشهد'
                  : matchType == 'all'
                      ? 'عند تحقق كل الشروط'
                      : 'عند تحقق أي شرط',
              onAdd: _addCondition,
              children: [
                if (conditions.length > 1)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'all', label: Text('كل الشروط')),
                        ButtonSegment(value: 'any', label: Text('أي شرط')),
                      ],
                      selected: {matchType},
                      onSelectionChanged: (value) =>
                          setState(() => matchType = value.first),
                    ),
                  ),
                ...conditions.asMap().entries.map(
                      (entry) => _ConditionTile(
                        condition: entry.value,
                        onDelete: () =>
                            setState(() => conditions.removeAt(entry.key)),
                      ),
                    ),
              ],
            ),
          ],
          SizedBox(height: 18.h),
          _EditorSection(
            title: 'إذن',
            subtitle: 'الأجهزة والمفاتيح التي سيتم التحكم بها',
            onAdd: _addAction,
            children: actions
                .asMap()
                .entries
                .map(
                  (entry) => _ActionTile(
                    action: entry.value,
                    onDelete: () => setState(() => actions.removeAt(entry.key)),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 18.h),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('إظهار على الصفحة الرئيسية'),
            value: showOnHome,
            onChanged: (value) => setState(() => showOnHome = value),
          ),
          if (triggerType != 'manual')
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('تفعيل الأتمتة'),
              subtitle: const Text('يمكن إيقافها لاحقًا من الرئيسية'),
              value: enabled,
              onChanged: (value) => setState(() => enabled = value),
            ),
          DropdownButtonFormField<int?>(
            initialValue: roomId,
            decoration: const InputDecoration(
              labelText: 'عرض في الغرفة (اختياري)',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('بدون غرفة محددة'),
              ),
              ...widget.controller.rooms.map(
                (room) => DropdownMenuItem<int?>(
                  value: room.id,
                  child: Text(room.name),
                ),
              ),
            ],
            onChanged: (value) => setState(() => roomId = value),
          ),
        ],
      ),
    );
  }

  Future<void> _addCondition() async {
    if (triggerType == 'schedule') {
      final condition = await _pickSchedule(context);
      if (condition != null) setState(() => conditions.add(condition));
      return;
    }
    final condition = await _pickBoolTarget(
      context,
      controller: widget.controller,
      title: 'اختر حالة المفتاح',
      condition: true,
    );
    if (condition != null) setState(() => conditions.add(condition));
  }

  Future<void> _addAction() async {
    final action = await _pickBoolTarget(
      context,
      controller: widget.controller,
      title: 'أضف أمرًا للمشهد',
      condition: false,
    );
    if (action != null) setState(() => actions.add(action));
  }

  Future<void> _save() async {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar('اسم المشهد', 'اكتب اسمًا للمشهد');
      return;
    }
    if (actions.isEmpty) {
      Get.snackbar('أوامر المشهد', 'أضف أمرًا واحدًا على الأقل');
      return;
    }
    if (triggerType != 'manual' && conditions.isEmpty) {
      Get.snackbar('شروط المشهد', 'أضف شرط تشغيل واحدًا على الأقل');
      return;
    }
    setState(() => saving = true);
    final ok = await widget.controller.saveScene(
      existing: widget.existing,
      name: nameController.text,
      triggerType: triggerType,
      matchType: matchType,
      conditions: conditions,
      actions: actions,
      enabled: triggerType == 'manual' ? true : enabled,
      showOnHome: showOnHome,
      roomId: roomId,
    );
    if (!mounted) return;
    setState(() => saving = false);
    if (ok) {
      Get.back<void>();
      Get.snackbar('تم', 'تم حفظ المشهد بنجاح');
    } else {
      Get.snackbar('تعذر الحفظ', widget.controller.errorMessage.value);
    }
  }
}

class _EditorSection extends StatelessWidget {
  const _EditorSection({
    required this.title,
    required this.subtitle,
    required this.onAdd,
    required this.children,
  });

  final String title;
  final String subtitle;
  final VoidCallback onAdd;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900)),
                      Text(subtitle,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ConditionTile extends StatelessWidget {
  const _ConditionTile({required this.condition, required this.onDelete});
  final Map<String, dynamic> condition;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheduled = condition['type'] == 'schedule';
    final days = (condition['repeat_days'] as List?)?.length ?? 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(scheduled ? Icons.schedule_rounded : Icons.sensors_rounded),
      title: Text(scheduled
          ? 'الساعة ${condition['time']}'
          : '${condition['device_name']} • ${condition['function_name']}'),
      subtitle: Text(scheduled
          ? (days == 0 ? 'مرة واحدة' : 'يتكرر في $days أيام')
          : (condition['value'] == true ? 'عند التشغيل' : 'عند الإطفاء')),
      trailing: IconButton(
        onPressed: onDelete,
        icon: const Icon(Icons.close_rounded),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action, required this.onDelete});
  final Map<String, dynamic> action;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        action['value'] == true
            ? Icons.lightbulb_rounded
            : Icons.lightbulb_outline_rounded,
      ),
      title: Text('${action['device_name']} • ${action['function_name']}'),
      subtitle: Text(action['value'] == true ? 'تشغيل' : 'إطفاء'),
      trailing: IconButton(
        onPressed: onDelete,
        icon: const Icon(Icons.close_rounded),
      ),
    );
  }
}

Future<Map<String, dynamic>?> _pickSchedule(BuildContext context) async {
  final now = DateTime.now();
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 5))),
  );
  if (time == null || !context.mounted) return null;
  final selectedDays = <String>{};
  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        const days = {
          'sun': 'الأحد',
          'mon': 'الإثنين',
          'tue': 'الثلاثاء',
          'wed': 'الأربعاء',
          'thu': 'الخميس',
          'fri': 'الجمعة',
          'sat': 'السبت',
        };
        return AlertDialog(
          title: const Text('التكرار'),
          content: Wrap(
            spacing: 7,
            children: days.entries
                .map((day) => FilterChip(
                      label: Text(day.value),
                      selected: selectedDays.contains(day.key),
                      onSelected: (selected) => setState(() {
                        selected
                            ? selectedDays.add(day.key)
                            : selectedDays.remove(day.key);
                      }),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تأكيد'),
            ),
          ],
        );
      },
    ),
  );
  if (accepted != true) return null;
  var date = DateTime(now.year, now.month, now.day, time.hour, time.minute);
  if (!date.isAfter(now)) date = date.add(const Duration(days: 1));
  String two(int value) => value.toString().padLeft(2, '0');
  return {
    'type': 'schedule',
    'time': '${two(time.hour)}:${two(time.minute)}',
    'date': '${date.year}-${two(date.month)}-${two(date.day)}',
    'repeat_days': selectedDays.toList(growable: false),
    'timezone': 'Asia/Jerusalem',
  };
}

Future<Map<String, dynamic>?> _pickBoolTarget(
  BuildContext context, {
  required SmartHomeController controller,
  required String title,
  required bool condition,
}) async {
  SmartDeviceModel? selectedDevice =
      controller.devices.isEmpty ? null : controller.devices.first;
  TuyaDeviceFunction? selectedFunction;
  bool value = true;

  List<TuyaDeviceFunction> functions(SmartDeviceModel? device) => device == null
      ? const []
      : DeviceCapabilityResolver.writableFunctions(device)
          .where((item) => item.isBool)
          .toList(growable: false);

  final initialFunctions = functions(selectedDevice);
  selectedFunction = initialFunctions.isEmpty ? null : initialFunctions.first;
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        final availableFunctions = functions(selectedDevice);
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<SmartDeviceModel>(
                  initialValue: selectedDevice,
                  decoration: const InputDecoration(labelText: 'الجهاز'),
                  items: controller.devices
                      .map((device) => DropdownMenuItem(
                            value: device,
                            child: Text(device.name),
                          ))
                      .toList(),
                  onChanged: (device) => setState(() {
                    selectedDevice = device;
                    final nextFunctions = functions(device);
                    selectedFunction =
                        nextFunctions.isEmpty ? null : nextFunctions.first;
                  }),
                ),
                SizedBox(height: 12.h),
                DropdownButtonFormField<TuyaDeviceFunction>(
                  initialValue: availableFunctions.contains(selectedFunction)
                      ? selectedFunction
                      : null,
                  decoration: const InputDecoration(labelText: 'المفتاح'),
                  items: availableFunctions
                      .map((function) => DropdownMenuItem(
                            value: function,
                            child: Text(function.name.isNotEmpty
                                ? function.name
                                : function.code),
                          ))
                      .toList(),
                  onChanged: (function) =>
                      setState(() => selectedFunction = function),
                ),
                SizedBox(height: 12.h),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: true,
                      label: Text(condition ? 'يصبح شغال' : 'تشغيل'),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text(condition ? 'يصبح مطفأ' : 'إطفاء'),
                    ),
                  ],
                  selected: {value},
                  onSelectionChanged: (selection) =>
                      setState(() => value = selection.first),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: selectedDevice == null || selectedFunction == null
                  ? null
                  : () => Navigator.pop(context, {
                        if (condition) 'type': 'device',
                        'device_id': selectedDevice!.id,
                        'dp_id': selectedFunction!.dpId,
                        'value': value,
                        'device_name': selectedDevice!.name,
                        'function_name': selectedFunction!.name.isNotEmpty
                            ? selectedFunction!.name
                            : selectedFunction!.code,
                      }),
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    ),
  );
}

Color _hexColor(String raw) {
  final clean = raw.replaceAll('#', '');
  final value = int.tryParse(clean, radix: 16);
  return value == null ? const Color(0xFF2563EB) : Color(0xFF000000 | value);
}
