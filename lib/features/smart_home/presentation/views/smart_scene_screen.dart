import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/smart_home_api_service.dart';
import '../../data/tuya_device_capability_resolver.dart';
import '../controllers/smart_home_controller.dart';
import '../smart_home_theme.dart';

class SmartScenesSection extends StatelessWidget {
  const SmartScenesSection({
    Key? key,
    required this.controller,
    this.showAll = false,
    this.showHeader = true,
  }) : super(key: key);

  final SmartHomeController controller;
  final bool showAll;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final scenes = controller.visibleScenes;
      final totalScenes = controller.scenes.length;
      if (totalScenes == 0 && !showAll) return const SizedBox.shrink();
      final featured =
          showAll ? scenes : scenes.take(2).toList(growable: false);
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
            if (showHeader) ...[
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
                      showAll ? 'المشاهد' : 'المشاهد الرئيسية',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: smartHomeInk,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  if (!showAll && totalScenes > featured.length)
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
            ],
            if (featured.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 28.h),
                child: Column(
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 42.r,
                      color: smartHomeMuted,
                    ),
                    SizedBox(height: 8.h),
                    const Text('لا توجد مشاهد في هذا النطاق'),
                    SizedBox(height: 10.h),
                    FilledButton.icon(
                      onPressed: () => Get.to<void>(
                        () => SmartSceneEditorScreen(controller: controller),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('إنشاء أول مشهد'),
                    ),
                  ],
                ),
              )
            else if (showAll)
              ...featured.map(
                (scene) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: _SceneCard(controller: controller, scene: scene),
                ),
              )
            else
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
  late final Map<String, List<Map<String, dynamic>>> conditionsByTrigger;
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
    final loadedConditions = existing?.conditions
            .map((item) => Map<String, dynamic>.from(item))
            .toList() ??
        [];
    conditionsByTrigger = {
      'schedule': loadedConditions
          .where((item) => item['type'] == 'schedule')
          .toList(growable: true),
      'device': loadedConditions
          .where((item) => item['type'] == 'device')
          .toList(growable: true),
    };
    conditions = conditionsByTrigger[triggerType] ?? <Map<String, dynamic>>[];
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
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: smartHomeAccent.withOpacity(.07),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: smartHomeAccent.withOpacity(.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44.r,
                    height: 44.r,
                    decoration: const BoxDecoration(
                      color: smartHomeAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 11.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.existing == null
                              ? 'ابنِ خطوات المشهد'
                              : nameController.text,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const Text(
                          'اختر طريقة التشغيل ثم أضف أمرًا أو أكثر. سيُطلب الاسم عند الحفظ.',
                        ),
                      ],
                    ),
                  ),
                ],
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
                final nextType = selection.first;
                if (nextType == triggerType) return;
                setState(() {
                  if (triggerType != 'manual') {
                    conditionsByTrigger[triggerType] = conditions;
                  }
                  triggerType = nextType;
                  conditions =
                      conditionsByTrigger[nextType] ?? <Map<String, dynamic>>[];
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
                          onEdit: entry.value['type'] == 'schedule'
                              ? () => _editScheduleCondition(entry.key)
                              : null,
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
              addItemLabel: 'إضافة مهمة',
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

  Future<void> _editScheduleCondition(int index) async {
    final condition = await _pickSchedule(
      context,
      initial: conditions[index],
    );
    if (condition != null && mounted) {
      setState(() => conditions[index] = condition);
    }
  }

  Future<void> _addAction() async {
    final selected = await _pickSceneActionTargets(
      context,
      controller: widget.controller,
      existingActions: actions,
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
    if (actions.isEmpty) {
      Get.snackbar('أوامر المشهد', 'أضف أمرًا واحدًا على الأقل');
      return;
    }
    if (triggerType != 'manual' && conditions.isEmpty) {
      Get.snackbar('شروط المشهد', 'أضف شرط تشغيل واحدًا على الأقل');
      return;
    }
    final name = await Get.dialog<String>(
      _SceneNameDialog(initialValue: nameController.text),
    );
    if (name == null || !mounted) return;
    nameController.text = name;
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

class _SceneNameDialog extends StatefulWidget {
  const _SceneNameDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_SceneNameDialog> createState() => _SceneNameDialogState();
}

class _SceneNameDialogState extends State<_SceneNameDialog> {
  late final TextEditingController controller;
  String error = '';

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
  }

  void _submit() {
    final name = controller.text.trim();
    if (name.isEmpty) {
      setState(() => error = 'اكتب اسمًا واضحًا للمشهد');
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.auto_awesome_rounded, color: smartHomeAccent),
      title: const Text('اسم المشهد'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 191,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: 'مثال: إطفاء إضاءة المعرض',
          errorText: error.isEmpty ? null : error,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_rounded),
          label: const Text('حفظ المشهد'),
        ),
      ],
    );
  }
}

Future<List<Map<String, dynamic>>> _pickSceneActionTargets(
  BuildContext context, {
  required SmartHomeController controller,
  required List<Map<String, dynamic>> existingActions,
}) async {
  final taskType = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 22.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'إضافة مهمة',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            SizedBox(height: 16.h),
            _SceneTaskTypeTile(
              icon: Icons.lightbulb_rounded,
              iconColor: const Color(0xFFF2B84B),
              title: 'الجهاز',
              subtitle: 'تشغيل أو إطفاء مفتاح، فتح أو إغلاق بوابة وستارة',
              onTap: () => Navigator.pop(sheetContext, 'device'),
            ),
            _SceneTaskTypeTile(
              icon: Icons.check_box_rounded,
              iconColor: const Color(0xFF55B7E8),
              title: 'حدد المشاهد الذكية',
              subtitle: 'تشغيل مشهد آخر بعد تحقق الشرط',
              enabled: false,
            ),
            _SceneTaskTypeTile(
              icon: Icons.timer_outlined,
              iconColor: const Color(0xFFF2B84B),
              title: 'تأخير الإجراء',
              subtitle: 'تنفيذ المهمة التالية بعد مدة محددة',
              enabled: false,
            ),
            _SceneTaskTypeTile(
              icon: Icons.notifications_none_rounded,
              iconColor: const Color(0xFF8ED8A5),
              title: 'إرسال إشعار',
              subtitle: 'غير متاح حاليًا',
              enabled: false,
            ),
          ],
        ),
      ),
    ),
  );
  if (taskType != 'device' || !context.mounted) return const [];

  final multiple = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'الجهاز',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            SizedBox(height: 18.h),
            _SceneDeviceModeTile(
              title: 'اختيار عدة أجهزة',
              icon: Icons.devices_other_rounded,
              onTap: () => Navigator.pop(sheetContext, true),
            ),
            SizedBox(height: 10.h),
            _SceneDeviceModeTile(
              title: 'اختيار جهاز واحد',
              icon: Icons.smart_button_rounded,
              onTap: () => Navigator.pop(sheetContext, false),
            ),
          ],
        ),
      ),
    ),
  );
  if (multiple == null || !context.mounted) return const [];

  final targets = <_SceneBoolTarget>[];
  final seen = <String>{};
  for (final device in controller.devices) {
    final functions = <TuyaDeviceFunction>[
      ...DeviceCapabilityResolver.boolSwitches(device),
      ...DeviceCapabilityResolver.writableFunctions(device)
          .where((function) => function.isEnum),
    ];
    for (final function in functions) {
      final key = '${device.id}:${function.dpId}';
      if (seen.add(key) &&
          _SceneSemanticAction.values.any(
            (action) => _semanticSceneValue(function, action: action) != null,
          )) {
        targets.add(_SceneBoolTarget(device: device, function: function));
      }
    }
  }
  if (targets.isEmpty) {
    Get.snackbar('أوامر المشهد', 'لا توجد قدرات قابلة للتحكم');
    return const [];
  }

  final result = await showModalBottomSheet<List<Map<String, dynamic>>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => _SceneActionPickerSheet(
      devices: controller.devices.toList(growable: false),
      targets: targets,
      multiple: multiple,
      existingActions: existingActions,
    ),
  );
  return result ?? const <Map<String, dynamic>>[];
}

class _SceneTaskTypeTile extends StatelessWidget {
  const _SceneTaskTypeTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .42,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 5.h),
        leading: Container(
          width: 42.r,
          height: 42.r,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(.14),
            borderRadius: BorderRadius.circular(11.r),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: enabled ? const Icon(Icons.chevron_left_rounded) : null,
        onTap: enabled ? onTap : null,
      ),
    );
  }
}

class _SceneDeviceModeTile extends StatelessWidget {
  const _SceneDeviceModeTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: smartHomeAccent.withOpacity(.055),
      borderRadius: BorderRadius.circular(15.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 22.h),
          child: Row(
            children: [
              Icon(icon, color: smartHomeAccent),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              const Icon(Icons.chevron_left_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SceneSemanticAction { activate, deactivate, stop }

class _SceneActionPickerSheet extends StatefulWidget {
  const _SceneActionPickerSheet({
    Key? key,
    required this.devices,
    required this.targets,
    required this.multiple,
    required this.existingActions,
  }) : super(key: key);

  final List<SmartDeviceModel> devices;
  final List<_SceneBoolTarget> targets;
  final bool multiple;
  final List<Map<String, dynamic>> existingActions;

  @override
  State<_SceneActionPickerSheet> createState() =>
      _SceneActionPickerSheetState();
}

class _SceneActionPickerSheetState extends State<_SceneActionPickerSheet> {
  late final TextEditingController searchController;
  final selectedKeys = <String>{};
  late _SceneSemanticAction action;
  String query = '';

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    action = _availableActions.contains(_SceneSemanticAction.activate)
        ? _SceneSemanticAction.activate
        : _availableActions.first;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<_SceneSemanticAction> get _availableActions => _SceneSemanticAction
      .values
      .where((candidate) => widget.targets.any(
            (target) =>
                _semanticSceneValue(target.function, action: candidate) != null,
          ))
      .toList(growable: false);

  Set<String> get _existingKeys => widget.existingActions
      .map((item) => '${item['device_id']}:${item['dp_id']}')
      .toSet();

  List<_SceneBoolTarget> _targetsForDevice(SmartDeviceModel device) =>
      widget.targets
          .where((target) => target.device.id == device.id)
          .toList(growable: false);

  bool _supports(_SceneBoolTarget target) =>
      _semanticSceneValue(target.function, action: action) != null;

  bool _matchesDevice(SmartDeviceModel device) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return true;
    final searchable = [
      device.name,
      device.roomName,
      device.productName,
      device.category,
      ..._targetsForDevice(device)
          .map((target) => _sceneFunctionLabel(device, target.function)),
    ].join(' ').toLowerCase();
    return searchable.contains(clean);
  }

  List<_SceneBoolTarget> get _visibleTargets {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return widget.targets;
    return widget.targets.where((target) {
      final searchable = [
        target.device.name,
        target.device.roomName,
        target.device.productName,
        target.device.category,
        _sceneFunctionLabel(target.device, target.function),
      ].join(' ').toLowerCase();
      return searchable.contains(clean);
    }).toList(growable: false);
  }

  Set<String> get _visibleSupportedKeys =>
      _visibleTargets.where(_supports).map(_sceneTargetKey).toSet();

  int get _unsupportedSelectedCount => widget.targets
      .where((target) =>
          selectedKeys.contains(_sceneTargetKey(target)) && !_supports(target))
      .length;

  void _toggleTarget(_SceneBoolTarget target) {
    final key = _sceneTargetKey(target);
    final selected = selectedKeys.contains(key);
    if (!selected && !_supports(target)) return;
    setState(() {
      if (selected) {
        selectedKeys.remove(key);
      } else if (widget.multiple) {
        selectedKeys.add(key);
      } else {
        selectedKeys
          ..clear()
          ..add(key);
      }
    });
  }

  void _toggleVisible() {
    final visible = _visibleSupportedKeys;
    if (visible.isEmpty) return;
    final allSelected = visible.every(selectedKeys.contains);
    setState(() {
      if (allSelected) {
        selectedKeys.removeAll(visible);
      } else {
        selectedKeys.addAll(visible);
      }
    });
  }

  void _removeUnsupportedSelections() {
    setState(() {
      selectedKeys.removeWhere((key) {
        final target = widget.targets
            .firstWhereOrNull((item) => _sceneTargetKey(item) == key);
        return target == null || !_supports(target);
      });
    });
  }

  void _confirm() {
    if (selectedKeys.isEmpty || _unsupportedSelectedCount > 0) return;
    final result = widget.targets
        .where((target) => selectedKeys.contains(_sceneTargetKey(target)))
        .map((target) => <String, dynamic>{
              'device_id': target.device.id,
              'dp_id': target.function.dpId,
              'value': _semanticSceneValue(target.function, action: action),
              'device_name': target.device.name,
              'function_name':
                  _sceneFunctionLabel(target.device, target.function),
            })
        .toList(growable: false);
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final visibleDevices =
        widget.devices.where(_matchesDevice).toList(growable: false);
    final supportedVisible = _visibleSupportedKeys;
    final allVisibleSelected = supportedVisible.isNotEmpty &&
        supportedVisible.every(selectedKeys.contains);
    final unsupportedSelected = _unsupportedSelectedCount;

    return FractionallySizedBox(
      heightFactor: .94,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: smartHomeBorder,
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              widget.multiple ? 'اختيار عدة أجهزة' : 'اختيار جهاز واحد',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: smartHomeAccent.withOpacity(.055),
                borderRadius: BorderRadius.circular(15.r),
                border: Border.all(color: smartHomeAccent.withOpacity(.13)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'الأمر المطلوب',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: _availableActions
                        .map((candidate) => Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 3.w),
                                child: _SceneCommandChoice(
                                  action: candidate,
                                  selected: action == candidate,
                                  onTap: () =>
                                      setState(() => action = candidate),
                                ),
                              ),
                            ))
                        .toList(growable: false),
                  ),
                  SizedBox(height: 7.h),
                  const Text(
                    'تبقى الأجهزة ثابتة، ويتغير الأمر المناسب لكل مفتاح فقط.',
                    style: TextStyle(color: smartHomeMuted),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: searchController,
              onChanged: (value) => setState(() => query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ابحث باسم الجهاز أو الغرفة أو المفتاح',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'مسح البحث',
                        onPressed: () {
                          searchController.clear();
                          setState(() => query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13.r),
                  borderSide: const BorderSide(color: smartHomeBorder),
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                if (widget.multiple)
                  TextButton.icon(
                    onPressed: supportedVisible.isEmpty ? null : _toggleVisible,
                    icon: Icon(allVisibleSelected
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded),
                    label: Text(allVisibleSelected
                        ? 'إلغاء تحديد النتائج'
                        : 'تحديد النتائج'),
                  ),
                const Spacer(),
                Text(
                  '${selectedKeys.length} أوامر محددة',
                  style: const TextStyle(
                    color: smartHomeMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (unsupportedSelected > 0)
              Container(
                margin: EdgeInsets.only(bottom: 7.h),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFFB76A00)),
                    SizedBox(width: 7.w),
                    Expanded(
                      child: Text(
                        '$unsupportedSelected من اختياراتك لا تدعم الأمر الجديد',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: _removeUnsupportedSelections,
                      child: const Text('إلغاءها'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: visibleDevices.isEmpty
                  ? const Center(child: Text('لا توجد نتائج مطابقة'))
                  : ListView.separated(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: visibleDevices.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8.h),
                      itemBuilder: (context, index) => _deviceCard(
                        context,
                        visibleDevices[index],
                      ),
                    ),
            ),
            SizedBox(height: 9.h),
            FilledButton.icon(
              onPressed: selectedKeys.isEmpty || unsupportedSelected > 0
                  ? null
                  : _confirm,
              icon: const Icon(Icons.add_task_rounded),
              label: Text('إضافة ${selectedKeys.length} أوامر'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deviceCard(BuildContext context, SmartDeviceModel device) {
    final clean = query.trim().toLowerCase();
    final deviceMatches = clean.isEmpty ||
        [device.name, device.roomName, device.productName, device.category]
            .join(' ')
            .toLowerCase()
            .contains(clean);
    final allTargets = _targetsForDevice(device);
    final targets = deviceMatches
        ? allTargets
        : allTargets
            .where((target) => _sceneFunctionLabel(device, target.function)
                .toLowerCase()
                .contains(clean))
            .toList(growable: false);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: smartHomeBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(11.w, 10.h, 11.w, 8.h),
            child: Row(
              children: [
                Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                    color: smartHomeAccent.withOpacity(.08),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child:
                      const Icon(Icons.devices_rounded, color: smartHomeAccent),
                ),
                SizedBox(width: 9.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        [
                          if (device.roomName.isNotEmpty) device.roomName,
                          device.online ? 'متصل' : 'غير متصل الآن',
                        ].join(' • '),
                        style: TextStyle(
                          color: device.online
                              ? const Color(0xFF1B8F63)
                              : const Color(0xFFB76A00),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (targets.isEmpty)
            const Padding(
              padding: EdgeInsets.all(13),
              child: Row(
                children: [
                  Icon(Icons.block_rounded, color: smartHomeMuted),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'لا توجد مفاتيح قابلة للتحكم في هذا الجهاز',
                      style: TextStyle(color: smartHomeMuted),
                    ),
                  ),
                ],
              ),
            )
          else
            ...targets.map((target) => _targetTile(target)),
        ],
      ),
    );
  }

  Widget _targetTile(_SceneBoolTarget target) {
    final key = _sceneTargetKey(target);
    final selected = selectedKeys.contains(key);
    final value = _semanticSceneValue(target.function, action: action);
    final supported = value != null;
    final alreadyAdded = _existingKeys.contains(key);
    final label = _sceneFunctionLabel(target.device, target.function);
    final outcome = supported
        ? _semanticOutcomeLabel(target.function, value, action)
        : 'هذا الأمر غير مدعوم';

    return InkWell(
      onTap: selected || supported ? () => _toggleTarget(target) : null,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              onChanged:
                  selected || supported ? (_) => _toggleTarget(target) : null,
            ),
            Icon(
              target.function.isBool
                  ? Icons.toggle_on_outlined
                  : Icons.curtains_rounded,
              color: supported ? smartHomeAccent : smartHomeMuted,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 2,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: supported ? null : smartHomeMuted,
                    ),
                  ),
                  Text(
                    [
                      outcome,
                      if (alreadyAdded) 'مضاف للمشهد وسيتم تحديثه',
                    ].join(' • '),
                    style: TextStyle(
                      color:
                          supported ? smartHomeMuted : const Color(0xFFB76A00),
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

class _SceneCommandChoice extends StatelessWidget {
  const _SceneCommandChoice({
    required this.action,
    required this.selected,
    required this.onTap,
  });

  final _SceneSemanticAction action;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = action == _SceneSemanticAction.activate
        ? 'تشغيل / فتح'
        : action == _SceneSemanticAction.deactivate
            ? 'إطفاء / إغلاق'
            : 'توقف';
    final icon = action == _SceneSemanticAction.activate
        ? Icons.power_settings_new_rounded
        : action == _SceneSemanticAction.deactivate
            ? Icons.power_off_rounded
            : Icons.stop_circle_outlined;
    return Material(
      color: selected ? smartHomeAccent : Colors.white,
      borderRadius: BorderRadius.circular(11.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 9.h),
          child: Column(
            children: [
              Icon(icon,
                  size: 20.r, color: selected ? Colors.white : smartHomeAccent),
              SizedBox(height: 3.h),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : smartHomeInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _sceneTargetKey(_SceneBoolTarget target) =>
    '${target.device.id}:${target.function.dpId}';

dynamic _semanticSceneValue(
  TuyaDeviceFunction function, {
  required _SceneSemanticAction action,
}) {
  if (function.isBool) {
    if (action == _SceneSemanticAction.activate) return true;
    if (action == _SceneSemanticAction.deactivate) return false;
    return null;
  }
  if (!function.isEnum) return null;
  final rawRange = function.values['range'];
  final options = rawRange is List
      ? rawRange.map((item) => item.toString()).toList(growable: false)
      : const <String>[];
  final preferred = action == _SceneSemanticAction.activate
      ? const ['open', 'on', 'start']
      : action == _SceneSemanticAction.deactivate
          ? const ['close', 'off', 'end']
          : const ['stop', 'pause'];
  for (final wanted in preferred) {
    for (final option in options) {
      if (option.toLowerCase() == wanted) return option;
    }
  }
  return null;
}

String _semanticOutcomeLabel(
  TuyaDeviceFunction function,
  dynamic value,
  _SceneSemanticAction action,
) {
  if (function.isBool) {
    return action == _SceneSemanticAction.activate
        ? 'سيتم التشغيل'
        : 'سيتم الإطفاء';
  }
  return 'سيتم: ${_friendlySceneEnumValue(value?.toString() ?? '')}';
}

String _friendlySceneEnumValue(String value) {
  switch (value.toLowerCase()) {
    case 'open':
      return 'فتح';
    case 'close':
      return 'إغلاق';
    case 'stop':
      return 'إيقاف';
    case 'continue':
      return 'متابعة';
    case 'start':
      return 'بدء';
    case 'end':
      return 'إنهاء';
    case 'pause':
      return 'إيقاف مؤقت';
    case 'on':
      return 'تشغيل';
    case 'off':
      return 'إطفاء';
    default:
      return value;
  }
}

class _EditorSection extends StatelessWidget {
  const _EditorSection({
    required this.title,
    required this.subtitle,
    required this.onAdd,
    required this.children,
    this.addItemLabel,
  });

  final String title;
  final String subtitle;
  final VoidCallback onAdd;
  final List<Widget> children;
  final String? addItemLabel;

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
            if (addItemLabel != null) ...[
              if (children.isNotEmpty) SizedBox(height: 6.h),
              Material(
                color: smartHomeAccent.withOpacity(.06),
                borderRadius: BorderRadius.circular(12.r),
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(12.r),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
                    child: Row(
                      children: [
                        Container(
                          width: 34.r,
                          height: 34.r,
                          decoration: BoxDecoration(
                            color: smartHomeAccent.withOpacity(.13),
                            borderRadius: BorderRadius.circular(9.r),
                          ),
                          child: const Icon(
                            Icons.add_task_rounded,
                            color: smartHomeAccent,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            addItemLabel!,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const Icon(Icons.chevron_left_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
    this.onEdit,
    required this.onDelete,
  });
  final SmartHomeController controller;
  final Map<String, dynamic> condition;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheduled = condition['type'] == 'schedule';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(scheduled ? Icons.schedule_rounded : Icons.sensors_rounded),
      title: Text(scheduled
          ? 'الساعة ${condition['time']}'
          : '${_sceneTargetDeviceName(controller, condition)} • ${_sceneTargetFunctionName(controller, condition)}'),
      subtitle: Text(
        scheduled
            ? _sceneScheduleSummary(condition)
            : (condition['value'] == true ? 'عند التشغيل' : 'عند الإطفاء'),
      ),
      onTap: onEdit,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onEdit != null)
            IconButton(
              tooltip: 'تعديل المؤقت',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          IconButton(
            tooltip: 'حذف الشرط',
            onPressed: onDelete,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
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
    final rawValue = action['value'];
    final valueLabel = rawValue is bool
        ? rawValue
            ? 'تشغيل'
            : 'إطفاء'
        : _friendlySceneEnumValue(rawValue?.toString() ?? '');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        rawValue == true
            ? Icons.lightbulb_rounded
            : rawValue == false
                ? Icons.lightbulb_outline_rounded
                : Icons.tune_rounded,
      ),
      title: Text(
        '${_sceneTargetDeviceName(controller, action)} • ${_sceneTargetFunctionName(controller, action)}',
      ),
      subtitle: Text(valueLabel),
      trailing: IconButton(
        onPressed: onDelete,
        icon: const Icon(Icons.close_rounded),
      ),
    );
  }
}

Future<Map<String, dynamic>?> _pickSchedule(
  BuildContext context, {
  Map<String, dynamic>? initial,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SceneSchedulePickerSheet(initial: initial),
  );
}

class _SceneSchedulePickerSheet extends StatefulWidget {
  const _SceneSchedulePickerSheet({this.initial});

  final Map<String, dynamic>? initial;

  @override
  State<_SceneSchedulePickerSheet> createState() =>
      _SceneSchedulePickerSheetState();
}

class _SceneSchedulePickerSheetState extends State<_SceneSchedulePickerSheet> {
  static const _repeatTypes = <String>[
    'once',
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ];
  static const _weekdays = <_SceneWeekday>[
    _SceneWeekday('sat', 'س', 'السبت'),
    _SceneWeekday('sun', 'ح', 'الأحد'),
    _SceneWeekday('mon', 'ن', 'الإثنين'),
    _SceneWeekday('tue', 'ث', 'الثلاثاء'),
    _SceneWeekday('wed', 'ر', 'الأربعاء'),
    _SceneWeekday('thu', 'خ', 'الخميس'),
    _SceneWeekday('fri', 'ج', 'الجمعة'),
  ];
  static const _monthNames = <String>[
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  late TimeOfDay time;
  late String repeatType;
  final selectedDays = <String>{};
  late String monthlyMode;
  late int monthDay;
  final customMonthDays = <int>{};
  late int yearlyMonth;
  late int yearlyDay;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial ?? const <String, dynamic>{};
    final initialTime = initial['time']?.toString().split(':') ?? const [];
    final now = DateTime.now().add(const Duration(minutes: 5));
    final parsedHour =
        initialTime.isNotEmpty ? int.tryParse(initialTime.first) : null;
    final parsedMinute =
        initialTime.length > 1 ? int.tryParse(initialTime[1]) : null;
    time = TimeOfDay(
      hour: (parsedHour ?? now.hour).clamp(0, 23),
      minute: (parsedMinute ?? now.minute).clamp(0, 59),
    );
    final initialRepeat = initial['repeat_type']?.toString() ?? 'once';
    repeatType = _repeatTypes.contains(initialRepeat) ? initialRepeat : 'once';
    final rawDays = initial['repeat_days'];
    if (rawDays is List) {
      selectedDays.addAll(rawDays.map((item) => item.toString()));
    }
    final config = _sceneRecurrenceConfig(initial);
    monthlyMode = config['monthly_mode']?.toString() == 'custom_dates'
        ? 'custom_dates'
        : 'day_of_month';
    monthDay = _sceneInt(config['month_day'], fallback: now.day).clamp(1, 31);
    final rawMonthDays = config['custom_month_days'];
    if (rawMonthDays is List) {
      customMonthDays.addAll(rawMonthDays
          .map((item) => int.tryParse(item.toString()))
          .whereType<int>()
          .where((day) => day >= 1 && day <= 31));
    }
    yearlyMonth =
        _sceneInt(config['yearly_month'], fallback: now.month).clamp(1, 12);
    yearlyDay = _sceneInt(config['yearly_day'], fallback: now.day)
        .clamp(1, _daysInMonth(now.year, yearlyMonth));
  }

  bool get _valid {
    if (repeatType == 'weekly' && selectedDays.isEmpty) return false;
    if (repeatType == 'monthly' &&
        monthlyMode == 'custom_dates' &&
        customMonthDays.isEmpty) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final preview = _buildCondition();
    return FractionallySizedBox(
      heightFactor: .95,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 7.h),
            child: Column(
              children: [
                Container(
                  width: 42.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: smartHomeBorder,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
                SizedBox(height: 9.h),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'إغلاق',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    Expanded(
                      child: Text(
                        widget.initial == null ? 'إضافة مؤقت' : 'تعديل المؤقت',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    SizedBox(width: 48.w),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 18.h),
              children: [
                _sectionTitle('وقت التنفيذ'),
                _card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12.r),
                    onTap: _pickTime,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 12.h),
                      child: Row(
                        children: [
                          Container(
                            width: 40.r,
                            height: 40.r,
                            decoration: BoxDecoration(
                              color: smartHomeAccent.withOpacity(.1),
                              borderRadius: BorderRadius.circular(11.r),
                            ),
                            child: const Icon(
                              Icons.schedule_rounded,
                              color: smartHomeAccent,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'الساعة',
                                  style: TextStyle(color: smartHomeMuted),
                                ),
                                Text(
                                  time.format(context),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_left_rounded),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                _sectionTitle('نمط التكرار'),
                _card(
                  child: Padding(
                    padding: EdgeInsets.all(8.w),
                    child: Column(
                      children: [
                        Row(
                          children: _repeatTypes
                              .take(3)
                              .map(_repeatTypeChoice)
                              .toList(growable: false),
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          children: _repeatTypes
                              .skip(3)
                              .map(_repeatTypeChoice)
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                ),
                if (repeatType == 'weekly') ...[
                  SizedBox(height: 10.h),
                  _sectionTitle('أيام التكرار'),
                  _card(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 7.w, vertical: 12.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _weekdays.map(_weekdayChoice).toList(),
                      ),
                    ),
                  ),
                ],
                if (repeatType == 'monthly') ...[
                  SizedBox(height: 10.h),
                  _sectionTitle('التكرار الشهري'),
                  _monthlySection(),
                ],
                if (repeatType == 'yearly') ...[
                  SizedBox(height: 10.h),
                  _sectionTitle('موعد التكرار السنوي'),
                  _yearlySection(),
                ],
                if (repeatType != 'once') ...[
                  SizedBox(height: 10.h),
                  _sectionTitle('مدة التكرار'),
                  _card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 11.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.radio_button_checked_rounded,
                            color: smartHomeAccent,
                          ),
                          SizedBox(width: 9.w),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'دائمًا',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  'يستمر حسب النمط إلى أن توقف الأتمتة. Tuya لا يضمن الإيقاف بعد عدد مرات من داخل المشهد.',
                                  style: TextStyle(color: smartHomeMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 10.h),
                _sectionTitle('الملخص'),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
                  decoration: BoxDecoration(
                    color: smartHomeAccent.withOpacity(.07),
                    borderRadius: BorderRadius.circular(13.r),
                    border: Border.all(
                      color: smartHomeAccent.withOpacity(.14),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_repeat_rounded,
                          color: smartHomeAccent),
                      SizedBox(width: 9.w),
                      Expanded(
                        child: Text(
                          _sceneScheduleSummary(preview),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(14.w, 9.h, 14.w, 12.h),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: smartHomeBorder)),
            ),
            child: FilledButton.icon(
              onPressed: _valid ? () => Navigator.pop(context, preview) : null,
              icon: const Icon(Icons.check_rounded),
              label:
                  Text(widget.initial == null ? 'إضافة المؤقت' : 'حفظ التعديل'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: EdgeInsets.only(bottom: 6.h, right: 2.w),
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      );

  Widget _card({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: smartHomeBorder),
        ),
        child: child,
      );

  Widget _repeatTypeChoice(String type) {
    final selected = repeatType == type;
    final label = type == 'once'
        ? 'مرة واحدة'
        : type == 'daily'
            ? 'يومي'
            : type == 'weekly'
                ? 'أسبوعي'
                : type == 'monthly'
                    ? 'شهري'
                    : 'سنوي';
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        child: Material(
          color: selected ? smartHomeAccent : smartHomeSurface,
          borderRadius: BorderRadius.circular(10.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(10.r),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => repeatType = type);
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 9.h),
              child: Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : smartHomeInk,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _weekdayChoice(_SceneWeekday day) {
    final selected = selectedDays.contains(day.key);
    return Semantics(
      selected: selected,
      button: true,
      label: day.fullLabel,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            selected ? selectedDays.remove(day.key) : selectedDays.add(day.key);
          });
        },
        borderRadius: BorderRadius.circular(30.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 35.r,
          height: 35.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? smartHomeAccent : smartHomeSurface,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? smartHomeAccent : smartHomeBorder,
            ),
          ),
          child: Text(
            day.shortLabel,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: selected ? Colors.white : smartHomeInk,
            ),
          ),
        ),
      ),
    );
  }

  Widget _monthlySection() => _card(
        child: Padding(
          padding: EdgeInsets.all(11.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _monthlyModeTile(
                value: 'day_of_month',
                title: 'في يوم محدد من كل شهر',
              ),
              if (monthlyMode == 'day_of_month') ...[
                SizedBox(height: 6.h),
                _numberStepper(
                  label: 'اليوم من الشهر',
                  value: monthDay,
                  max: 31,
                  onChanged: (value) => setState(() => monthDay = value),
                ),
                SizedBox(height: 5.h),
                const Text(
                  'إذا لم يوجد هذا اليوم في شهر معين، يتجاوزه Tuya إلى الشهر التالي.',
                  style: TextStyle(color: smartHomeMuted),
                ),
              ],
              const Divider(height: 22),
              _monthlyModeTile(
                value: 'custom_dates',
                title: 'عدة أيام محددة من كل شهر',
              ),
              if (monthlyMode == 'custom_dates') ...[
                SizedBox(height: 9.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: List.generate(31, (index) {
                    final day = index + 1;
                    final selected = customMonthDays.contains(day);
                    return InkWell(
                      borderRadius: BorderRadius.circular(8.r),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => selected
                            ? customMonthDays.remove(day)
                            : customMonthDays.add(day));
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        width: 34.r,
                        height: 34.r,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? smartHomeAccent : smartHomeSurface,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: selected ? smartHomeAccent : smartHomeBorder,
                          ),
                        ),
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: selected ? Colors.white : smartHomeInk,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                if (customMonthDays.isEmpty) ...[
                  SizedBox(height: 7.h),
                  const Text(
                    'اختر يومًا واحدًا على الأقل',
                    style: TextStyle(
                      color: Color(0xFFB76A00),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
              const Divider(height: 22),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: smartHomeMuted),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'نمط «أول/آخر يوم أسبوع من الشهر» غير متاح مباشرة في محرك Tuya، لذلك لم نعرض خيارًا لن يعمل فعليًا.',
                      style: TextStyle(color: smartHomeMuted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _monthlyModeTile({required String value, required String title}) {
    final selected = monthlyMode == value;
    return InkWell(
      borderRadius: BorderRadius.circular(9.r),
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => monthlyMode = value);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? smartHomeAccent : smartHomeMuted,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _yearlySection() => _card(
        child: Padding(
          padding: EdgeInsets.all(11.w),
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                initialValue: yearlyMonth,
                decoration: InputDecoration(
                  labelText: 'الشهر',
                  filled: true,
                  fillColor: smartHomeSurface,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: List.generate(
                  12,
                  (index) => DropdownMenuItem<int>(
                    value: index + 1,
                    child: Text(_monthNames[index]),
                  ),
                ),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    yearlyMonth = value;
                    yearlyDay = yearlyDay.clamp(
                      1,
                      _daysInMonth(DateTime.now().year, yearlyMonth),
                    );
                  });
                },
              ),
              SizedBox(height: 10.h),
              _numberStepper(
                label: 'اليوم من الشهر',
                value: yearlyDay,
                max: _daysInMonth(DateTime.now().year, yearlyMonth),
                onChanged: (value) => setState(() => yearlyDay = value),
              ),
            ],
          ),
        ),
      );

  Widget _numberStepper({
    required String label,
    required int value,
    required int max,
    required ValueChanged<int> onChanged,
  }) =>
      Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: smartHomeSurface,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            IconButton(
              tooltip: 'إنقاص',
              onPressed: value <= 1 ? null : () => onChanged(value - 1),
              icon: const Icon(Icons.remove_circle_outline_rounded),
              color: smartHomeAccent,
            ),
            SizedBox(
              width: 34.w,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
            ),
            IconButton(
              tooltip: 'زيادة',
              onPressed: value >= max ? null : () => onChanged(value + 1),
              icon: const Icon(Icons.add_circle_outline_rounded),
              color: smartHomeAccent,
            ),
          ],
        ),
      );

  Future<void> _pickTime() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await showTimePicker(
      context: context,
      initialTime: time,
    );
    if (selected != null && mounted) setState(() => time = selected);
  }

  Map<String, dynamic> _buildCondition() {
    final days = repeatType == 'daily'
        ? <String>['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat']
        : repeatType == 'weekly'
            ? selectedDays.toList()
            : <String>[];
    days.sort(_weekdaySort);
    final sortedMonthDays = customMonthDays.toList(growable: false)..sort();
    final config = <String, dynamic>{
      if (repeatType == 'monthly') 'monthly_mode': monthlyMode,
      if (repeatType == 'monthly') 'month_day': monthDay,
      if (repeatType == 'monthly') 'custom_month_days': sortedMonthDays,
      if (repeatType == 'yearly') 'yearly_month': yearlyMonth,
      if (repeatType == 'yearly') 'yearly_day': yearlyDay,
      'duration_type': 'forever',
    };
    final next = _nextSceneScheduleDate(
      time: time,
      repeatType: repeatType,
      repeatDays: days,
      config: config,
    );
    return <String, dynamic>{
      'type': 'schedule',
      'time': '${_two(time.hour)}:${_two(time.minute)}',
      'date': '${next.year}-${_two(next.month)}-${_two(next.day)}',
      'repeat_days': days,
      'repeat_type': repeatType,
      'recurrence_config': config,
      'timezone': 'Asia/Jerusalem',
    };
  }
}

class _SceneWeekday {
  const _SceneWeekday(this.key, this.shortLabel, this.fullLabel);

  final String key;
  final String shortLabel;
  final String fullLabel;
}

Map<String, dynamic> _sceneRecurrenceConfig(Map<String, dynamic> condition) {
  final raw = condition['recurrence_config'];
  return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
}

int _sceneInt(dynamic value, {required int fallback}) =>
    int.tryParse(value?.toString() ?? '') ?? fallback;

String _two(int value) => value.toString().padLeft(2, '0');

int _weekdaySort(String left, String right) {
  const order = <String>['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
  return order.indexOf(left).compareTo(order.indexOf(right));
}

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

String _weekdayKey(int weekday) {
  const keys = <int, String>{
    DateTime.monday: 'mon',
    DateTime.tuesday: 'tue',
    DateTime.wednesday: 'wed',
    DateTime.thursday: 'thu',
    DateTime.friday: 'fri',
    DateTime.saturday: 'sat',
    DateTime.sunday: 'sun',
  };
  return keys[weekday] ?? '';
}

DateTime _nextSceneScheduleDate({
  required TimeOfDay time,
  required String repeatType,
  required List<String> repeatDays,
  required Map<String, dynamic> config,
}) {
  final now = DateTime.now();
  final selectedWeekdays = repeatDays.toSet();
  final monthlyMode = config['monthly_mode']?.toString();
  final monthDays = monthlyMode == 'custom_dates'
      ? ((config['custom_month_days'] as List?) ?? const [])
          .map((item) => int.tryParse(item.toString()))
          .whereType<int>()
          .toSet()
      : <int>{_sceneInt(config['month_day'], fallback: now.day)};
  final yearlyMonth = _sceneInt(config['yearly_month'], fallback: now.month);
  final yearlyDay = _sceneInt(config['yearly_day'], fallback: now.day);

  for (var offset = 0; offset <= 1461; offset++) {
    final date = DateTime(now.year, now.month, now.day + offset);
    final candidate =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (!candidate.isAfter(now)) continue;
    if (repeatType == 'weekly' &&
        !selectedWeekdays.contains(_weekdayKey(candidate.weekday))) {
      continue;
    }
    if (repeatType == 'monthly' && !monthDays.contains(candidate.day)) {
      continue;
    }
    if (repeatType == 'yearly' &&
        (candidate.month != yearlyMonth || candidate.day != yearlyDay)) {
      continue;
    }
    return candidate;
  }
  return DateTime(now.year, now.month, now.day + 1, time.hour, time.minute);
}

String _sceneScheduleSummary(Map<String, dynamic> condition) {
  final repeatType = condition['repeat_type']?.toString() ?? 'once';
  final config = _sceneRecurrenceConfig(condition);
  if (repeatType == 'daily') return 'يتكرر يوميًا';
  if (repeatType == 'weekly') {
    const labels = <String, String>{
      'sun': 'الأحد',
      'mon': 'الإثنين',
      'tue': 'الثلاثاء',
      'wed': 'الأربعاء',
      'thu': 'الخميس',
      'fri': 'الجمعة',
      'sat': 'السبت',
    };
    final rawDays = condition['repeat_days'];
    final days = rawDays is List
        ? rawDays.map((item) => item.toString()).toList(growable: false)
        : <String>[];
    days.sort(_weekdaySort);
    return days.isEmpty
        ? 'أسبوعيًا — اختر الأيام'
        : 'أسبوعيًا: ${days.map((day) => labels[day] ?? day).join('، ')}';
  }
  if (repeatType == 'monthly') {
    final mode = config['monthly_mode']?.toString();
    if (mode == 'custom_dates') {
      final rawDays = config['custom_month_days'];
      final days = rawDays is List
          ? rawDays.map((item) => item.toString()).join('، ')
          : '';
      return days.isEmpty ? 'شهريًا — اختر الأيام' : 'شهريًا في الأيام: $days';
    }
    return 'شهريًا في اليوم ${_sceneInt(config['month_day'], fallback: 1)}';
  }
  if (repeatType == 'yearly') {
    const months = <String>[
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    final month = _sceneInt(config['yearly_month'], fallback: 1).clamp(1, 12);
    final day = _sceneInt(config['yearly_day'], fallback: 1);
    return 'سنويًا في $day ${months[month - 1]}';
  }
  final date = condition['date']?.toString();
  return date == null || date.isEmpty ? 'مرة واحدة' : 'مرة واحدة بتاريخ $date';
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
