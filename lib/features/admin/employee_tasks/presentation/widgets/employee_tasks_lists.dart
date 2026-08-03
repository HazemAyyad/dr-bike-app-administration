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
            _showTaskActions(context, theme);
          },
          onTap: () => controller.openTaskDetails(order),
          child: OperationalTaskCard(
            task: order,
            searchQuery: controller.employeeNameController.text,
          ),
        ),
      ],
    );
  }

  void _showTaskActions(BuildContext context, TextStyle theme) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value ? AppColors.darkColor : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                order.taskName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 10.h),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('إرسال تذكير'),
                subtitle: Text(order.displayAssigneeLabel),
                onTap: () {
                  Get.back();
                  _showReminderDialog(context, theme);
                },
              ),
              if (controller.isCompletedTab)
                ListTile(
                  leading: const Icon(Icons.restore_outlined),
                  title: Text('reopenTask'.tr),
                  onTap: () {
                    Get.back();
                    _showReopenDialog(context, theme);
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text('deleteTask'.tr),
                  onTap: () {
                    Get.back();
                    _showDeleteDialog(context, theme);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReminderDialog(BuildContext context, TextStyle theme) {
    Get.dialog(
      _TaskReminderDialog(
        controller: controller,
        order: order,
        theme: theme,
      ),
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
                        onPressed: () => controller.deleteTask.value == false &&
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

class _TaskReminderDialog extends StatefulWidget {
  const _TaskReminderDialog({
    required this.controller,
    required this.order,
    required this.theme,
  });

  final EmployeeTasksController controller;
  final EmployeeTaskModel order;
  final TextStyle theme;

  @override
  State<_TaskReminderDialog> createState() => _TaskReminderDialogState();
}

class _TaskReminderDialogState extends State<_TaskReminderDialog> {
  final TextEditingController _noteController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _sendReminder() async {
    if (_isSending) return;
    setState(() => _isSending = true);
    await widget.controller.sendTaskReminder(
      task: widget.order,
      note: _noteController.text,
    );
    if (mounted) {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: _isSending
            ? const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'إرسال تذكير',
                    style: widget.theme.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    widget.order.taskName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: widget.theme.copyWith(fontSize: 14.sp),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'سيصل التذكير إلى: ${widget.order.displayAssigneeLabel}',
                    style: widget.theme.copyWith(fontSize: 12.sp),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _noteController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'ملاحظة اختيارية',
                      border: OutlineInputBorder(),
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
                          text: 'send',
                          onPressed: _sendReminder,
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
