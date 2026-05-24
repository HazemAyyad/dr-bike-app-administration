import 'dart:io';

import 'package:doctorbike/core/helpers/custom_upload_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../employee/employee_dashbord/presentation/controllers/employee_dashbord_controller.dart';
import '../../data/models/task_details_model.dart';
import '../controllers/employee_tasks_controller.dart';
import 'task_media_thumbnail_row.dart';

class MarkTaskComplete extends GetView<EmployeeTasksController> {
  const MarkTaskComplete({Key? key, required this.data}) : super(key: key);

  final TaskDetailsModel data;

  @override
  Widget build(BuildContext context) {
    final TextStyle theme = Theme.of(context).textTheme.bodyMedium!;

    return Column(
      children: [
        ...data.subTasks.map(
          (tasks) => Container(
            margin: EdgeInsets.symmetric(vertical: 5.h),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: tasks.status == 'ongoing'
                  ? null
                  : ThemeService.isDark.value
                      ? AppColors.customGreyColor
                      : AppColors.customGreyColor6,
              borderRadius: BorderRadius.circular(11.r),
              border: Border.all(color: AppColors.customGreyColor6),
            ),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Flexible(
                        child: CustomCheckBox(
                          scale: 1.5,
                          shape: const CircleBorder(
                            side: BorderSide(
                              color: AppColors.primaryColor,
                            ),
                          ),
                          title:
                              '${tasks.name}${'\n'}${tasks.description}',
                          style: theme.copyWith(
                            decoration: tasks.status == 'ongoing'
                                ? TextDecoration.none
                                : TextDecoration.lineThrough,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                            color: ThemeService.isDark.value
                                ? AppColors.customGreyColor6
                                : AppColors.customGreyColor4,
                          ),
                          value: tasks.status == 'ongoing'
                              ? false.obs
                              : true.obs,
                          onChanged: userType == 'admin'
                              ? (value) {}
                              : tasks.status != 'ongoing'
                                  ? (value) {}
                                  : (value) async {
                                      _showCompleteSubTaskDialog(
                                        context,
                                        tasks as SubTaskModel,
                                      );
                                    },
                        ),
                      ),
                      if (tasks.employeeImg != null &&
                          tasks.employeeImg!.isNotEmpty) ...[
                        SizedBox(width: 10.w),
                        SizedBox(
                          width: 72.w,
                          child: TaskMediaThumbnailRow(
                            images: tasks.employeeImg ?? [],
                            videos: tasks.employeeVideos ?? [],
                            thumbHeight: 60,
                            thumbWidth: 60,
                          ),
                        ),
                      ],
                      if ((tasks.adminImg?.isNotEmpty ?? false) ||
                          (tasks.adminVideos?.isNotEmpty ?? false)) ...[
                        SizedBox(width: 10.w),
                        SizedBox(
                          width: 72.w,
                          child: TaskMediaThumbnailRow(
                            images: tasks.adminImg ?? [],
                            videos: tasks.adminVideos ?? [],
                            thumbHeight: 60,
                            thumbWidth: 60,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (userType != 'admin' &&
                    tasks.isForcedToUploadImg &&
                    tasks.status == 'ongoing' &&
                    (tasks.employeeImg == null ||
                        tasks.employeeImg!.isEmpty)) ...[
                  SizedBox(height: 8.h),
                  MediaUploadButton(
                    allowedType: MediaType.both,
                    height: 120,
                    title: 'uploadTaskProof'.tr,
                    onFilesChanged: (files) {
                      controller.subTaskPendingImages[tasks.id] = files;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCompleteSubTaskDialog(BuildContext context, SubTaskModel task) {
    Get.dialog(
      Dialog(
        backgroundColor: ThemeService.isDark.value
            ? AppColors.darkColor
            : AppColors.whiteColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 5.h),
              Text(
                'areYouSure'.tr,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Flexible(
                    child: AppButton(
                      isSafeArea: false,
                      isLoading: controller.isLoading,
                      width: double.infinity,
                      borderRadius: BorderRadius.all(
                        Radius.circular(8.r),
                      ),
                      text: 'yes'.tr,
                      textStyle: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                      onPressed: () async {
                        Get.back();
                        final String mainTaskId = Get.arguments['taskId'];
                        final args =
                            Get.arguments as Map<String, dynamic>?;
                        final EmployeeDashbordController dashboardController =
                            args!['EmployeeDashbordController'];

                        final pending =
                            controller.subTaskPendingImages[task.id] ??
                                <File>[];

                        if (!controller.canCompleteSubTask(task, pending)) {
                          Get.snackbar(
                            'error'.tr,
                            'employeeImageRequired'.tr,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          return;
                        }

                        if (pending.isNotEmpty) {
                          final uploaded = await controller.uploadTaskImage(
                            taskId: task.id.toString(),
                            isSubTask: true,
                            files: pending,
                          );
                          if (!uploaded) return;
                          controller.subTaskPendingImages.remove(task.id);
                        }

                        dashboardController.changeTaskToCompleted(
                          taskId: task.id,
                          isSubTask: true,
                          context: context,
                          mainTaskId: mainTaskId,
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Flexible(
                    child: AppButton(
                      isLoading: controller.isLoading,
                      isSafeArea: false,
                      color: Colors.red,
                      width: double.infinity,
                      borderRadius: BorderRadius.all(
                        Radius.circular(8.r),
                      ),
                      text: 'cancel'.tr,
                      textStyle: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                      onPressed: () {
                        Get.back();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
