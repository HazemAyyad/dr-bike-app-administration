import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/helpers/proof_media_type.dart';
import '../controllers/create_task_controller.dart';
import 'proof_media_type_selector.dart';
import 'subtask_admin_media_picker.dart';

/// Operational subtask list with reorder, image requirement, and bonus points.
class InlineSubtaskBuilder extends GetView<CreateTaskController> {
  const InlineSubtaskBuilder({Key? key, this.isSpecialTask = false})
      : super(key: key);

  final bool isSpecialTask;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AddSubtaskRow(isSpecialTask: isSpecialTask),
          SizedBox(height: isSpecialTask ? 6.h : 12.h),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.subTasks.length,
            onReorder: controller.reorderSubTasks,
            itemBuilder: (context, index) {
              final task = controller.subTasks[index] as Map;
              if (isSpecialTask) {
                return _SimpleSubtaskCard(
                  key: ValueKey(_subtaskKey(task)),
                  index: index,
                  title: task['subTaskName']?.toString() ?? '',
                  description: task['subTaskdescription']?.toString() ?? '',
                  isCompleted: task['status'] == 'completed',
                  onEdit: () {
                    controller.startEditSubTask(index);
                    Get.bottomSheet(
                      _SpecialSubtaskEditorSheet(editIndex: index),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20.r)),
                      ),
                      isScrollControlled: true,
                    );
                  },
                  onDelete: () => controller.subTasks.removeAt(index),
                );
              }
              return _SubtaskCard(
                key: ValueKey('subtask_${index}_${task['subTaskId'] ?? index}'),
                index: index,
                title: task['subTaskName']?.toString() ?? '',
                proofMediaType: ProofMediaType.normalize(
                  task['proofMediaType']?.toString(),
                  required: task['imageIsRequired'] == true,
                ),
                bonusPoints: task['bonusPoints'] as int? ?? 0,
                defaultBonus: controller.defaultSubtaskBonusPoints,
                onEdit: () {
                  controller.startEditSubTask(index);
                  Get.bottomSheet(
                    _SubtaskEditorSheet(editIndex: index),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20.r)),
                    ),
                    isScrollControlled: true,
                  );
                },
                onDelete: () => controller.subTasks.removeAt(index),
                onProofMediaTypeChanged: (v) {
                  task['proofMediaType'] = v;
                  task['imageIsRequired'] = v != ProofMediaType.none;
                  controller.subTasks[index] = task;
                  controller.subTasks.refresh();
                },
                onBonusChanged: (enabled, points) {
                  task['bonusPoints'] = enabled ? points : 0;
                  controller.subTasks[index] = task;
                  controller.subTasks.refresh();
                },
                onBonusLongPress: () => _showBonusPointsDialog(
                  context,
                  initial: (task['bonusPoints'] as int? ?? 0) > 0
                      ? task['bonusPoints'] as int
                      : controller.defaultSubtaskBonusPoints,
                  onSave: (pts) {
                    task['bonusPoints'] = pts;
                    controller.subTasks[index] = task;
                    controller.subTasks.refresh();
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

String _subtaskKey(Map task) {
  return (task['subTaskId'] ?? task['clientKey'] ?? identityHashCode(task))
      .toString();
}

Future<void> _showBonusPointsDialog(
  BuildContext context, {
  required int initial,
  required void Function(int points) onSave,
}) async {
  final result = await showDialog<int>(
    context: context,
    barrierColor: const Color(0xFFD9D9D9).withValues(alpha: 0.55),
    builder: (ctx) => _BonusPointsDialog(initial: initial),
  );
  if (result != null && result > 0) {
    onSave(result);
  }
}

/// Owns [TextEditingController] lifecycle — avoids dispose-during-route-pop crashes.
class _BonusPointsDialog extends StatefulWidget {
  const _BonusPointsDialog({required this.initial});

  final int initial;

  @override
  State<_BonusPointsDialog> createState() => _BonusPointsDialogState();
}

class _BonusPointsDialogState extends State<_BonusPointsDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.initial}');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _close([int? value]) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(value);
  }

  void _save() {
    final v = int.tryParse(_ctrl.text.trim()) ?? 0;
    _close(v > 0 ? v : widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.whiteColor,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'bonusPointsValue'.tr,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.operationalNavy,
              ),
            ),
            SizedBox(height: 14.h),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.operationalNavy,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: '${widget.initial}',
                filled: true,
                fillColor: AppColors.operationalSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide:
                      BorderSide(color: AppColors.operationalCardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide:
                      BorderSide(color: AppColors.operationalCardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(
                    color: AppColors.operationalNavy,
                    width: 1.5,
                  ),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              ),
              onSubmitted: (_) => _save(),
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _close(),
                  child: Text(
                    'cancel'.tr,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _save,
                  child: Text(
                    'save'.tr,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.operationalNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddSubtaskRow extends StatefulWidget {
  const _AddSubtaskRow({this.isSpecialTask = false});

  final bool isSpecialTask;

  @override
  State<_AddSubtaskRow> createState() => _AddSubtaskRowState();
}

class _AddSubtaskRowState extends State<_AddSubtaskRow> {
  final _nameCtrl = TextEditingController();
  CreateTaskController get controller => Get.find<CreateTaskController>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      Get.snackbar(
        'info'.tr,
        'fillSubtaskNameFirst'.tr,
        backgroundColor: AppColors.customOrange3,
        colorText: AppColors.whiteColor,
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(12.w),
        duration: const Duration(seconds: 2),
      );
      return;
    }
    if (widget.isSpecialTask) {
      controller.prepareNewSubTask();
      controller.subTaskNameController.text = name;
      _nameCtrl.clear();
      Get.bottomSheet(
        const _SpecialSubtaskEditorSheet(),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        isScrollControlled: true,
      );
      return;
    }
    controller.prepareNewSubTask();
    controller.subTaskNameController.text = name;
    _nameCtrl.clear();
    Get.bottomSheet(
      const _SubtaskEditorSheet(),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      isScrollControlled: true,
    );
  }

  void _openEditor() => _submit();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.operationalCardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: 'addSubTaskPlaceholder'.tr,
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: AppColors.customGreyColor5,
                  fontSize: 14.sp,
                ),
              ),
              onSubmitted: (_) => _openEditor(),
            ),
          ),
          Material(
            color: AppColors.operationalPurple,
            borderRadius: BorderRadius.circular(12.r),
            child: InkWell(
              onTap: _openEditor,
              borderRadius: BorderRadius.circular(12.r),
              child: SizedBox(
                width: 44.w,
                height: 44.w,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtaskEditorSheet extends GetView<CreateTaskController> {
  const _SubtaskEditorSheet({this.editIndex});

  final int? editIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.w,
        16.h,
        16.w,
        16.h + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editIndex == null ? 'addSubTask'.tr : 'editSubTask'.tr,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.operationalNavy,
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: controller.subTaskNameController,
              decoration: InputDecoration(
                labelText: 'subTaskName'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            const SubtaskAdminMediaPicker(),
            SizedBox(height: 12.h),
            Obx(
              () => ProofMediaTypeSelector(
                value: controller.subTaskProofMediaType.value,
                onChanged: controller.setSubTaskProofMediaType,
              ),
            ),
            Obx(
              () => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('additionalPoints'.tr),
                value: controller.subtaskBonusEnabled.value,
                activeThumbColor: AppColors.operationalPurple,
                onChanged: (v) => controller.subtaskBonusEnabled.value = v,
              ),
            ),
            if (controller.subtaskBonusEnabled.value)
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'bonusPointsValue'.tr,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                onChanged: (v) =>
                    controller.subtaskBonusPoints.value = int.tryParse(v) ?? 0,
              ),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: () {
                controller.addSubTask();
                controller.clearSubTaskForm();
                Get.back();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.operationalPurple,
                minimumSize: Size(double.infinity, 48.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text('save'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubtaskCard extends StatelessWidget {
  const _SubtaskCard({
    Key? key,
    required this.index,
    required this.title,
    required this.proofMediaType,
    required this.bonusPoints,
    required this.onEdit,
    required this.onDelete,
    required this.onProofMediaTypeChanged,
    required this.onBonusChanged,
    required this.onBonusLongPress,
    required this.defaultBonus,
  }) : super(key: key);

  final int index;
  final String title;
  final String proofMediaType;
  final int bonusPoints;
  final int defaultBonus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onProofMediaTypeChanged;
  final void Function(bool enabled, int points) onBonusChanged;
  final VoidCallback onBonusLongPress;

  @override
  Widget build(BuildContext context) {
    final bonusEnabled = bonusPoints > 0;
    final requiresProof = proofMediaType != ProofMediaType.none;

    return Container(
      key: key,
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.operationalCardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.operationalNavy.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Icon(
              Icons.drag_handle,
              color: AppColors.customGreyColor5,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                    color: AppColors.operationalNavy,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 4.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: [
                    _MiniFlag(
                      icon: proofMediaType == ProofMediaType.video
                          ? Icons.videocam_outlined
                          : proofMediaType == ProofMediaType.both
                              ? Icons.perm_media_outlined
                              : Icons.photo_camera_outlined,
                      label: _proofLabel(proofMediaType),
                      enabled: requiresProof,
                      color: AppColors.operationalPurple,
                      onTap: () => onProofMediaTypeChanged(
                        _nextProofType(proofMediaType),
                      ),
                    ),
                    _MiniFlag(
                      icon: Icons.bolt,
                      label:
                          bonusEnabled ? '+$bonusPoints' : 'additionalPoints',
                      enabled: bonusEnabled,
                      color: AppColors.operationalPurple,
                      onTap: () => onBonusChanged(
                        !bonusEnabled,
                        !bonusEnabled
                            ? (bonusPoints > 0 ? bonusPoints : defaultBonus)
                            : 0,
                      ),
                      onLongPress: onBonusLongPress,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: onEdit,
            color: AppColors.operationalPurple,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: onDelete,
            color: Colors.red.shade400,
          ),
        ],
      ),
    );
  }

  static String _proofLabel(String value) {
    if (value == ProofMediaType.image) return 'proofMediaImage';
    if (value == ProofMediaType.video) return 'proofMediaVideo';
    if (value == ProofMediaType.both) return 'proofMediaEither';
    return 'proofMediaNone';
  }

  static String _nextProofType(String value) {
    if (value == ProofMediaType.none) return ProofMediaType.image;
    if (value == ProofMediaType.image) return ProofMediaType.video;
    if (value == ProofMediaType.video) return ProofMediaType.both;
    return ProofMediaType.none;
  }
}

class _SpecialSubtaskEditorSheet extends GetView<CreateTaskController> {
  const _SpecialSubtaskEditorSheet({this.editIndex});

  final int? editIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.w,
        16.h,
        16.w,
        16.h + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editIndex == null ? 'addSubTask'.tr : 'editSubTask'.tr,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.operationalNavy,
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: controller.subTaskNameController,
              decoration: InputDecoration(
                labelText: 'subTaskName'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: controller.subTaskDescriptionController,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'subTaskDescription'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
            Obx(() {
              final index = controller.editingSubTaskIndex.value;
              if (index == null ||
                  index < 0 ||
                  index >= controller.subTasks.length) {
                return const SizedBox.shrink();
              }
              final task = controller.subTasks[index] as Map;
              if (task['status'] != 'completed') return const SizedBox.shrink();
              return Container(
                margin: EdgeInsets.only(top: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.operationalPurple.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.operationalPurple.withValues(alpha: 0.24),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18.sp,
                      color: AppColors.operationalPurple,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'completed'.tr,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.operationalPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: () {
                controller.addSubTask();
                controller.clearSubTaskForm();
                Get.back();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.operationalPurple,
                minimumSize: Size(double.infinity, 48.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text('save'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleSubtaskCard extends StatelessWidget {
  const _SimpleSubtaskCard({
    Key? key,
    required this.index,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  final int index;
  final String title;
  final String description;
  final bool isCompleted;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      margin: EdgeInsets.only(bottom: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.operationalCardBorder),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Icon(
              Icons.drag_handle,
              color: AppColors.customGreyColor5,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.sp,
                          color: isCompleted
                              ? AppColors.customGreyColor5
                              : AppColors.operationalNavy,
                          height: 1.15,
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (isCompleted) ...[
                      SizedBox(width: 6.w),
                      Icon(
                        Icons.check_circle,
                        size: 16.sp,
                        color: AppColors.operationalPurple,
                      ),
                    ],
                  ],
                ),
                if (description.trim().isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.customGreyColor5,
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.w),
            icon: Icon(
              Icons.more_vert,
              size: 20.sp,
              color: AppColors.customGreyColor5,
            ),
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 18.sp,
                      color: AppColors.operationalPurple,
                    ),
                    SizedBox(width: 8.w),
                    Text('edit'.tr),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 18.sp,
                      color: Colors.red.shade400,
                    ),
                    SizedBox(width: 8.w),
                    Text('delete'.tr),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniFlag extends StatelessWidget {
  const _MiniFlag({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.color,
    required this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final bg =
        enabled ? color.withValues(alpha: 0.12) : AppColors.operationalSurface;
    final fg = enabled ? color : AppColors.customGreyColor5;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(10.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14.sp, color: fg),
              SizedBox(width: 4.w),
              Text(
                label.tr,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
