import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/employee_task_model.dart';
import '../controllers/employee_tasks_controller.dart';
import 'operational_task_card.dart';

class EmployeeTasksLists extends StatelessWidget {
  const EmployeeTasksLists({
    Key? key,
    required this.controller,
    required this.order,
    required this.index,
  }) : super(key: key);

  final EmployeeTasksController controller;
  final EmployeeTaskModel order;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme.bodyMedium!;

    return Column(
      children: [
        GestureDetector(
          onLongPress: () {
            if (controller.currentTab.value == controller.archiveTabIndex) {
              return;
            }
            if (controller.isCompletedTab) {
              _showReopenDialog(context, theme);
            } else {
              _showDeleteDialog(context, theme);
            }
          },
          onTap: () => controller.openTaskDetails(order),
          child: OperationalTaskCard(task: order),
        ),
      ],
    );
  }

  void _showReopenDialog(BuildContext context, TextStyle theme) {
    final notesController = TextEditingController();
    Get.dialog(
      Dialog(
        backgroundColor: ThemeService.isDark.value
            ? AppColors.darkColor
            : AppColors.whiteColor,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Obx(
            () => controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'reopenTask'.tr,
                        style: theme.copyWith(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'reopenTaskConfirm'.tr,
                        style: theme.copyWith(fontSize: 14.sp),
                      ),
                      SizedBox(height: 12.h),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'reopenTaskNotesHint'.tr,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: Get.back,
                              child: Text('cancel'.tr),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: AppButton(
                              isSafeArea: false,
                              text: 'reopenTask',
                              onPressed: () => controller.reopenCompletedTask(
                                taskId: order.taskId.toString(),
                                occurrenceId: order.occurrenceId,
                                notes: notesController.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    ).then((_) => notesController.dispose());
  }

  void _showDeleteDialog(BuildContext context, TextStyle theme) {
    controller.deleteTask.value = false;
    controller.deleteTasDuplicate.value = false;
    Get.dialog(
      Dialog(
        backgroundColor: ThemeService.isDark.value
            ? AppColors.darkColor
            : AppColors.whiteColor,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Obx(
            () => controller.isLoading.value
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        heightFactor: 3.7.h,
                        child: const CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomCheckBox(
                        title: 'deleteTask',
                        value: controller.deleteTask,
                        onChanged: (value) {
                          controller.deleteTask.value = value!;
                          controller.deleteTasDuplicate.value = false;
                        },
                        style: theme.copyWith(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: ThemeService.isDark.value
                              ? Colors.white
                              : AppColors.secondaryColor,
                        ),
                      ),
                      CustomCheckBox(
                        title: 'deleteRepeatedTask',
                        value: controller.deleteTasDuplicate,
                        onChanged: (value) {
                          controller.deleteTasDuplicate.value = value!;
                          controller.deleteTask.value = false;
                        },
                        style: theme.copyWith(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: ThemeService.isDark.value
                              ? Colors.white
                              : AppColors.secondaryColor,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      AppButton(
                        isSafeArea: false,
                        text: 'save',
                        onPressed: () =>
                            controller.deleteTask.value == false &&
                                    controller.deleteTasDuplicate.value == false
                                ? null
                                : controller.cancelEmployeeTask(
                                    taskId: order.taskId.toString(),
                                    occurrenceId: order.occurrenceId,
                                    cancelWithRepetition:
                                        controller.deleteTasDuplicate.value,
                                  ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
