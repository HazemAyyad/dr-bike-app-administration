import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/smart_home_api_service.dart';
import '../../data/tuya_device_capability_resolver.dart';
import '../controllers/smart_home_controller.dart';
import '../smart_home_theme.dart';

class SmartScenesSection extends StatelessWidget {
  const SmartScenesSection({Key? key, required this.controller})
      : super(key: key);

  final SmartHomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final scenes = controller.visibleScenes;
      final totalScenes = controller.scenes.length;
      if (totalScenes == 0) return const SizedBox.shrink();
      final featured = scenes.take(2).toList(growable: false);
      return Container(
        padding: EdgeInsets.all(11.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: smartHomeBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 34.r,
                  height: 34.r,
                  decoration: BoxDecoration(
                    color: smartHomeAccentSoft,
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: smartHomeAccent,
                    size: 19,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'المشاهد الرئيسية',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: smartHomeInk,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                if (totalScenes > featured.length)
                  TextButton(
                    onPressed: () => Get.to<void>(
                      () => _AllScenesScreen(controller: controller),
                    ),
                    child: Text('عرض الكل ($totalScenes)'),
                  ),
                IconButton(
                  tooltip: 'إضافة مشهد',
                  onPressed: () => Get.to<void>(
                    () => SmartSceneEditorScreen(controller: controller),
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  color: smartHomeAccent,
                ),
              ],
            ),
            SizedBox(height: 8.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: featured.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.w,
                childAspectRatio: .98,
              ),
              itemBuilder: (context, index) => _FeaturedSceneCard(
                controller: controller,
                scene: featured[index],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _AllScenesScreen extends StatelessWidget {
  const _AllScenesScreen({required this.controller});

  final SmartHomeController controller;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: smartHomeTheme(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('كل المشاهد'),
          actions: [
            IconButton(
              tooltip: 'إضافة مشهد',
              onPressed: () => Get.to<void>(
                () => SmartSceneEditorScreen(controller: controller),
              ),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        body: Obx(
          () => ListView.builder(
            padding: EdgeInsets.all(14.w),
            itemCount: controller.scenes.length,
            itemBuilder: (context, index) => _SceneCard(
              controller: controller,
              scene: controller.scenes[index],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedSceneCard extends StatelessWidget {
  const _FeaturedSceneCard({required this.controller, required this.scene});

  final SmartHomeController controller;
  final SmartSceneModel scene;

  @override
  Widget build(BuildContext context) {
    final busy = controller.sceneBusyIds.contains(scene.id);
    final accent = scene.triggerType == 'schedule'
        ? const Color(0xFF176B87)
        : smartHomeAccent;
    final subtitle = scene.isManual
        ? '${scene.actions.length} أوامر'
        : '${scene.conditions.length} شروط • ${scene.actions.length} أوامر';
    return Material(
      color: smartHomeSurface,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: scene.isManual && !busy
            ? () => controller.executeScene(scene)
            : null,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(9.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34.r,
                    height: 34.r,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(9.r),
                    ),
                    child: Icon(
                      scene.isManual
                          ? Icons.play_arrow_rounded
                          : scene.triggerType == 'schedule'
                              ? Icons.schedule_rounded
                              : Icons.bolt_rounded,
                      color: accent,
                      size: 19.r,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      fixedSize: Size(28.r, 28.r),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onSelected: (value) =>
                        _handleSceneMenu(controller, scene, value),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('تعديل')),
                      PopupMenuItem(value: 'delete', child: Text('حذف')),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                scene.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: smartHomeInk,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              SizedBox(height: 3.h),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: smartHomeMuted,
                      fontSize: 9.5.sp,
                    ),
              ),
              SizedBox(height: 4.h),
              _SceneExecutionLine(
                controller: controller,
                scene: scene,
                compact: true,
              ),
              const Spacer(),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: busy
                    ? SizedBox.square(
                        dimension: 24.r,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : scene.isManual
                        ? Icon(
                            Icons.play_circle_fill_rounded,
                            color: accent,
                            size: 29.r,
                          )
                        : Transform.scale(
                            scale: .82,
                            child: Switch.adaptive(
                              value: scene.enabled,
                              onChanged: (value) =>
                                  controller.setSceneEnabled(scene, value),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _handleSceneMenu(
  SmartHomeController controller,
  SmartSceneModel scene,
  String value,
) async {
  if (value == 'edit') {
    await Get.to<void>(() => SmartSceneEditorScreen(
          controller: controller,
          existing: scene,
        ));
    return;
  }
  if (value != 'delete') return;
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

class _SceneCard extends StatelessWidget {
  const _SceneCard({required this.controller, required this.scene});

  final SmartHomeController controller;
  final SmartSceneModel scene;

  @override
  Widget build(BuildContext context) {
    final color = scene.triggerType == 'schedule'
        ? const Color(0xFF176B87)
        : smartHomeAccent;
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
                if (ok) {
                  Get.snackbar(
                    'تم إرسال الأمر',
                    'سيظهر تأكيد التنفيذ من سجل Tuya على بطاقة المشهد',
                  );
                }
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
                    SizedBox(height: 5.h),
                    _SceneExecutionLine(
                      controller: controller,
                      scene: scene,
                    ),
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
                onSelected: (value) =>
                    _handleSceneMenu(controller, scene, value),
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

class _SceneExecutionLine extends StatelessWidget {
  const _SceneExecutionLine({
    required this.controller,
    required this.scene,
    this.compact = false,
  });

  final SmartHomeController controller;
  final SmartSceneModel scene;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final nativeLog = controller.executionLogForScene(scene);
      final storedAt = scene.lastExecutedAt;
      final nativeAt = nativeLog?.executedAt;
      final storedIsNewer =
          storedAt != null && (nativeAt == null || storedAt.isAfter(nativeAt));
      final status = storedIsNewer
          ? scene.lastExecutionStatus
          : (nativeLog?.status ?? scene.lastExecutionStatus);
      final executedAt = storedIsNewer ? storedAt : (nativeAt ?? storedAt);
      final visual = _sceneExecutionVisual(status, executedAt);
      return Tooltip(
        message: nativeLog?.failureCause.isNotEmpty == true
            ? nativeLog!.failureCause
            : visual.label,
        child: Row(
          mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(visual.icon, size: compact ? 12.r : 15.r, color: visual.color),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                visual.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: visual.color,
                      fontSize: compact ? 8.5.sp : 10.sp,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

_SceneExecutionVisual _sceneExecutionVisual(
  String rawStatus,
  DateTime? executedAt,
) {
  final status = rawStatus.trim().toLowerCase();
  final time =
      executedAt == null ? '' : ' • ${_sceneExecutionTime(executedAt)}';
  switch (status) {
    case 'success':
      return _SceneExecutionVisual(
        label: 'نُفّذ بنجاح$time',
        icon: Icons.check_circle_rounded,
        color: smartHomeAccent,
      );
    case 'failed':
      return _SceneExecutionVisual(
        label: 'فشل التنفيذ$time',
        icon: Icons.error_rounded,
        color: const Color(0xFFB42318),
      );
    case 'partial':
      return _SceneExecutionVisual(
        label: 'أُرسل، بانتظار التأكيد$time',
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFF9A6700),
      );
    case 'running':
      return _SceneExecutionVisual(
        label: 'جاري التنفيذ$time',
        icon: Icons.sync_rounded,
        color: const Color(0xFF176B87),
      );
    default:
      return const _SceneExecutionVisual(
        label: 'لم يُنفذ حتى الآن',
        icon: Icons.history_rounded,
        color: smartHomeMuted,
      );
  }
}

String _sceneExecutionTime(DateTime value) {
  final now = DateTime.now();
  String two(int number) => number.toString().padLeft(2, '0');
  final clock = '${two(value.hour)}:${two(value.minute)}';
  final today = value.year == now.year &&
      value.month == now.month &&
      value.day == now.day;
  return today ? clock : '${value.day}/${value.month} $clock';
}

class _SceneExecutionVisual {
  const _SceneExecutionVisual({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
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
    return Theme(
      data: smartHomeTheme(context),
      child: Scaffold(
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
                          controller: widget.controller,
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
                      controller: widget.controller,
                      action: entry.value,
                      onDelete: () =>
                          setState(() => actions.removeAt(entry.key)),
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
      ),
    );
  }

  Future<void> _addCondition() async {
    if (triggerType == 'schedule') {
      final condition = await _pickSchedule(context);
      if (condition != null) setState(() => conditions.add(condition));
      return;
    }
    final selected = await _pickBoolTargets(
      context,
      controller: widget.controller,
      title: 'اختر حالة المفتاح',
      condition: true,
    );
    if (selected.isNotEmpty) setState(() => conditions.add(selected.first));
  }

  Future<void> _addAction() async {
    final selected = await _pickBoolTargets(
      context,
      controller: widget.controller,
      title: 'أضف أوامر للمشهد',
      condition: false,
    );
    if (selected.isEmpty) return;
    setState(() {
      for (final action in selected) {
        final index = actions.indexWhere(
          (item) =>
              item['device_id'] == action['device_id'] &&
              item['dp_id']?.toString() == action['dp_id']?.toString(),
        );
        if (index == -1) {
          actions.add(action);
        } else {
          actions[index] = action;
        }
      }
    });
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
  const _ConditionTile({
    required this.controller,
    required this.condition,
    required this.onDelete,
  });
  final SmartHomeController controller;
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
          : '${_sceneTargetDeviceName(controller, condition)} • ${_sceneTargetFunctionName(controller, condition)}'),
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
  const _ActionTile({
    required this.controller,
    required this.action,
    required this.onDelete,
  });
  final SmartHomeController controller;
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
      title: Text(
        '${_sceneTargetDeviceName(controller, action)} • ${_sceneTargetFunctionName(controller, action)}',
      ),
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

Future<List<Map<String, dynamic>>> _pickBoolTargets(
  BuildContext context, {
  required SmartHomeController controller,
  required String title,
  required bool condition,
}) async {
  final selectedKeys = <String>{};
  final searchController = TextEditingController();
  String query = '';
  bool value = true;

  final targets = <_SceneBoolTarget>[];
  final seen = <String>{};
  for (final device in controller.devices) {
    final functions = DeviceCapabilityResolver.writableFunctions(device)
        .where((item) => item.isBool);
    for (final function in functions) {
      final key = '${device.id}:${function.dpId}';
      if (seen.add(key)) {
        targets.add(_SceneBoolTarget(device: device, function: function));
      }
    }
  }

  final result = await showDialog<List<Map<String, dynamic>>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        final mediaQuery = MediaQuery.of(context);
        final dialogContentHeight =
            (mediaQuery.size.height - mediaQuery.viewInsets.bottom - 250.h)
                .clamp(190.h, 470.h)
                .toDouble();
        final normalizedQuery = query.trim().toLowerCase();
        final filteredTargets = targets.where((target) {
          if (normalizedQuery.isEmpty) return true;
          final searchable = [
            target.device.name,
            _sceneFunctionLabel(target.device, target.function),
            target.device.roomName,
          ].join(' ').toLowerCase();
          return searchable.contains(normalizedQuery);
        }).toList(growable: false);
        final allFilteredSelected = filteredTargets.isNotEmpty &&
            filteredTargets.every((target) => selectedKeys
                .contains('${target.device.id}:${target.function.dpId}'));
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            height: dialogContentHeight,
            child: Column(
              children: [
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
                SizedBox(height: 12.h),
                TextField(
                  controller: searchController,
                  onChanged: (value) => setState(() => query = value),
                  decoration: const InputDecoration(
                    hintText: 'ابحث باسم المفتاح أو الجهاز أو الغرفة',
                    prefixIcon: Icon(Icons.search_rounded),
                    isDense: true,
                  ),
                ),
                if (!condition && targets.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: filteredTargets.isEmpty
                            ? null
                            : () => setState(() {
                                  for (final target in filteredTargets) {
                                    final key =
                                        '${target.device.id}:${target.function.dpId}';
                                    allFilteredSelected
                                        ? selectedKeys.remove(key)
                                        : selectedKeys.add(key);
                                  }
                                }),
                        icon: Icon(allFilteredSelected
                            ? Icons.deselect_rounded
                            : Icons.select_all_rounded),
                        label: Text(allFilteredSelected
                            ? 'إلغاء تحديد الظاهر'
                            : 'تحديد الكل'),
                      ),
                      const Spacer(),
                      Text(
                        '${selectedKeys.length} محدد',
                        style: const TextStyle(
                          color: smartHomeMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 6.h),
                Expanded(
                  child: targets.isEmpty
                      ? const Center(
                          child: Text('لا توجد مفاتيح قابلة للتحكم'),
                        )
                      : filteredTargets.isEmpty
                          ? const Center(
                              child: Text('لا توجد نتائج مطابقة'),
                            )
                          : ListView.separated(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              itemCount: filteredTargets.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final target = filteredTargets[index];
                                final key =
                                    '${target.device.id}:${target.function.dpId}';
                                final selected = selectedKeys.contains(key);
                                void change(bool next) => setState(() {
                                      if (condition) selectedKeys.clear();
                                      next
                                          ? selectedKeys.add(key)
                                          : selectedKeys.remove(key);
                                    });
                                return CheckboxListTile(
                                  value: selected,
                                  onChanged: (next) => change(next == true),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(_sceneFunctionLabel(
                                    target.device,
                                    target.function,
                                  )),
                                  subtitle: Text(target.device.name),
                                  secondary: Icon(
                                    value
                                        ? Icons.lightbulb_rounded
                                        : Icons.lightbulb_outline_rounded,
                                  ),
                                );
                              },
                            ),
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
              onPressed: selectedKeys.isEmpty
                  ? null
                  : () => Navigator.pop(
                        context,
                        targets
                            .where((target) {
                              final key =
                                  '${target.device.id}:${target.function.dpId}';
                              return selectedKeys.contains(key);
                            })
                            .map((target) => <String, dynamic>{
                                  if (condition) 'type': 'device',
                                  'device_id': target.device.id,
                                  'dp_id': target.function.dpId,
                                  'value': value,
                                  'device_name': target.device.name,
                                  'function_name': _sceneFunctionLabel(
                                    target.device,
                                    target.function,
                                  ),
                                })
                            .toList(growable: false),
                      ),
              child: Text(condition ? 'اختيار' : 'إضافة المحدد'),
            ),
          ],
        );
      },
    ),
  );
  searchController.dispose();
  return result ?? const <Map<String, dynamic>>[];
}

class _SceneBoolTarget {
  const _SceneBoolTarget({required this.device, required this.function});

  final SmartDeviceModel device;
  final TuyaDeviceFunction function;
}

String _sceneTargetDeviceName(
  SmartHomeController controller,
  Map<String, dynamic> target,
) {
  final id = int.tryParse(target['device_id']?.toString() ?? '');
  final device = controller.devices.firstWhereOrNull((item) => item.id == id);
  return device?.name.trim().isNotEmpty == true
      ? device!.name.trim()
      : target['device_name']?.toString() ?? 'جهاز';
}

String _sceneTargetFunctionName(
  SmartHomeController controller,
  Map<String, dynamic> target,
) {
  final id = int.tryParse(target['device_id']?.toString() ?? '');
  final dpId = target['dp_id']?.toString() ?? '';
  final device = controller.devices.firstWhereOrNull((item) => item.id == id);
  if (device != null) {
    final function =
        DeviceCapabilityResolver.functions(device).firstWhereOrNull(
      (item) => item.dpId == dpId,
    );
    if (function != null) return _sceneFunctionLabel(device, function);

    final metadata = device.functions.firstWhereOrNull(
      (item) => item.dpId == dpId,
    );
    final renamed = metadata?.displayName.trim() ?? '';
    if (renamed.isNotEmpty) return renamed;
  }
  final stored = target['function_name']?.toString().trim() ?? '';
  return stored.isNotEmpty && !_containsCjkText(stored) ? stored : 'مفتاح';
}

String _sceneFunctionLabel(
  SmartDeviceModel device,
  TuyaDeviceFunction function,
) {
  final metadata = device.functions.firstWhereOrNull(
    (item) =>
        item.code == function.code ||
        (item.dpId.isNotEmpty && item.dpId == function.dpId),
  );
  final renamed = metadata?.displayName.trim() ?? '';
  if (renamed.isNotEmpty) return renamed;

  final original = function.name.trim();
  if (original.isNotEmpty && !_containsCjkText(original)) return original;
  final code = function.code.toLowerCase();
  final switchNumber = RegExp(r'^switch_(\d+)$').firstMatch(code)?.group(1);
  if (switchNumber != null) return 'مفتاح $switchNumber';
  if (code == 'switch' || code == 'switch_led') return 'مفتاح التشغيل';
  final friendly = function.code.replaceAll('_', ' ').trim();
  return friendly.isEmpty ? 'مفتاح' : friendly;
}

bool _containsCjkText(String value) => RegExp(
      r'[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF]',
    ).hasMatch(value);
