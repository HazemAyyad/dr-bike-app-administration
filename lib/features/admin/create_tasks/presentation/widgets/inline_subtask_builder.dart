import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../controllers/create_task_controller.dart';

/// Inline checklist builder replacing modal-only subtask flow.
class InlineSubtaskBuilder extends GetView<CreateTaskController> {
  const InlineSubtaskBuilder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'subTasks'.tr,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.operationalNavy,
            ),
          ),
          SizedBox(height: 8.h),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.subTasks.length,
            onReorder: controller.reorderSubTasks,
            itemBuilder: (context, index) {
              final task = controller.subTasks[index] as Map;
              return _SubtaskCard(
                key: ValueKey('subtask_${index}_${task['subTaskId'] ?? index}'),
                index: index,
                title: task['subTaskName']?.toString() ?? '',
                requiresImage: task['imageIsRequired'] == true,
                bonusPoints: task['bonusPoints'] as int? ?? 0,
                onEdit: () => controller.startEditSubTask(index),
                onDelete: () => controller.subTasks.removeAt(index),
              );
            },
          ),
          SizedBox(height: 12.h),
          OutlinedButton.icon(
            onPressed: () {
              controller.prepareNewSubTask();
              _showInlineEditor(context);
            },
            icon: const Icon(Icons.add, color: AppColors.operationalPurple),
            label: Text('addSubTask'.tr),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.operationalPurple,
              side: const BorderSide(color: AppColors.operationalPurple),
            ),
          ),
        ],
      ),
    );
  }

  void _showInlineEditor(BuildContext context) {
    Get.bottomSheet(
      Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller.subTaskNameController,
              decoration: InputDecoration(labelText: 'subTaskName'.tr),
            ),
            SizedBox(height: 8.h),
            Obx(
              () => SwitchListTile(
                title: Text('requireImage'.tr),
                value: controller.requireSubTasImage.value,
                activeColor: AppColors.operationalPurple,
                onChanged: (v) => controller.requireSubTasImage.value = v,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                controller.addSubTask();
                Get.back();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.operationalPurple,
              ),
              child: Text('save'.tr),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}

class _SubtaskCard extends StatelessWidget {
  const _SubtaskCard({
    Key? key,
    required this.index,
    required this.title,
    required this.requiresImage,
    required this.bonusPoints,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  final int index;
  final String title;
  final bool requiresImage;
  final int bonusPoints;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.operationalCardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.drag_handle, color: AppColors.customGreyColor5, size: 22.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    color: AppColors.operationalNavy,
                  ),
                ),
                if (requiresImage)
                  Text(
                    'requireImage'.tr,
                    style: TextStyle(fontSize: 11.sp, color: AppColors.operationalPurple),
                  ),
                if (bonusPoints > 0)
                  Text(
                    '+$bonusPoints XP',
                    style: TextStyle(fontSize: 11.sp, color: AppColors.customGreen1),
                  ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
        ],
      ),
    );
  }
}
