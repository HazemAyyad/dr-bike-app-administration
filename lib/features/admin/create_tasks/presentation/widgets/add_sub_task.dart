import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/create_task_controller.dart';
import 'build_sub_task_image.dart';
import 'sub_task_form_sheet.dart';

class AddSubTask extends GetView<CreateTaskController> {
  const AddSubTask({Key? key, required this.title}) : super(key: key);

  final String title;

  Color _listCardColor(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return isDark ? AppColors.customGreyColor4 : const Color(0xFFEBECF0);
  }

  Color _listBorderColor(BuildContext context, {required bool isEditing}) {
    if (isEditing) return AppColors.primaryColor;
    final isDark = ThemeService.isDark.value;
    return isDark ? Colors.white12 : const Color(0xFFD8DCE2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme.bodyMedium!;
    final listCardColor = _listCardColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          if (controller.subTasks.isEmpty) {
            return const SizedBox.shrink();
          }
          return ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: controller.subTasks.length,
            onReorder: controller.reorderSubTasks,
            itemBuilder: (context, index) {
              final task = controller.subTasks[index] as Map;
              final isEditing =
                  controller.editingSubTaskIndex.value == index;
              return Container(
                key: ValueKey(
                  'sub_${task['subTaskId'] ?? 'n'}_$index',
                ),
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: listCardColor,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: _listBorderColor(context, isEditing: isEditing),
                    width: isEditing ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Icon(
                          Icons.drag_indicator,
                          color: AppColors.primaryColor,
                          size: 24.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    buildSubTaskImage(context, task['subTaskImage']),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['subTaskName']?.toString() ?? '',
                            style: theme.copyWith(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          if ((task['subTaskdescription']?.toString() ?? '')
                              .isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 4.h),
                              child: Text(
                                task['subTaskdescription'].toString(),
                                style: theme.copyWith(
                                  fontSize: 13.sp,
                                  color: AppColors.customGreyColor5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 20.sp,
                            color: AppColors.primaryColor,
                          ),
                          onPressed: () => showSubTaskFormSheet(
                            context,
                            controller: controller,
                            title: title,
                            editIndex: index,
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.delete_outline,
                            size: 20.sp,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            if (controller.editingSubTaskIndex.value ==
                                index) {
                              controller.clearSubTaskForm();
                            }
                            controller.subTasks.removeAt(index);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        }),
        SizedBox(height: 8.h),
        InkWell(
          onTap: () => showSubTaskFormSheet(
            context,
            controller: controller,
            title: title,
          ),
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: listCardColor,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: _listBorderColor(context, isEditing: false),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primaryColor,
                  size: 22.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'addSubTask'.tr,
                  style: theme.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
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
