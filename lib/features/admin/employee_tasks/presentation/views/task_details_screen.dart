import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_upload_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/audio_helper.dart';
import '../../../../../core/helpers/task_nav_debug.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../employee/employee_dashbord/presentation/controllers/employee_dashbord_controller.dart';
import '../controllers/employee_tasks_controller.dart';
import '../widgets/audio_player.dart';
import '../widgets/mark_task_complete.dart';
import '../widgets/task_assignees_section.dart';
import '../widgets/task_media_thumbnail_row.dart';
import '../widgets/task_status_badge.dart';
import '../widgets/task_timeline_section.dart';

class TaskDetailsScreen extends GetView<EmployeeTasksController> {
  const TaskDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextStyle theme = Theme.of(context).textTheme.bodyMedium!;
    return Scaffold(
      appBar: CustomAppBar(
        title: 'employeeTaskDetails',
        action: false,
        actions: [
          userType == 'admin'
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      icon: Icon(
                        Icons.copy_all_outlined,
                        color: ThemeService.isDark.value
                            ? AppColors.primaryColor
                            : AppColors.secondaryColor,
                        size: 22.sp,
                      ),
                      onPressed: () {
                        TaskNavDebug.log(
                          'TaskDetailsScreen.cloneButton',
                          AppRoutes.CREATETASKSCREEN,
                          screen:
                              'CreateTaskEntryScreen -> CreateEmployeeTaskScreen',
                          extra: {
                            'title': 'createNewEmployeeTask',
                            'isEdit': false,
                            'cloneFromTask': true,
                          },
                        );
                        Get.toNamed(
                          AppRoutes.CREATETASKSCREEN,
                          arguments: {
                            'title': 'createNewEmployeeTask',
                            'isEdit': false,
                            'cloneFromTask': true,
                          },
                        );
                      },
                      label: Text(
                        'cloneTask'.tr,
                        style: theme.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: ThemeService.isDark.value
                              ? AppColors.primaryColor
                              : AppColors.secondaryColor,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      icon: Icon(
                        Icons.edit_calendar_outlined,
                        color: ThemeService.isDark.value
                            ? AppColors.primaryColor
                            : AppColors.secondaryColor,
                        size: 22.sp,
                      ),
                      onPressed: () {
                        TaskNavDebug.log(
                          'TaskDetailsScreen.editButton',
                          AppRoutes.CREATETASKSCREEN,
                          screen:
                              'CreateTaskEntryScreen -> CreateEmployeeTaskScreen',
                          extra: {'title': 'editEmployeeTask', 'isEdit': true},
                        );
                        Get.toNamed(
                          AppRoutes.CREATETASKSCREEN,
                          arguments: {
                            'title': 'editEmployeeTask',
                            'isEdit': true,
                          },
                        );
                      },
                      label: Text(
                        'edit'.tr,
                        style: theme.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: ThemeService.isDark.value
                              ? AppColors.primaryColor
                              : AppColors.secondaryColor,
                        ),
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ],
      ),
      body: Obx(
        () {
          if (controller.isTaskDetailsLoading.value ||
              controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = controller.employeeTaskService.taskDetails.value!;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TaskStatusBadge(status: data.status),
                    SizedBox(width: 8.w),
                    if (data.progress > 0)
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: LinearProgressIndicator(
                            value: data.progress / 100,
                            minHeight: 8.h,
                            color: AppColors.operationalPurple,
                            backgroundColor: AppColors.operationalSurface,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12.h),
                SupTextAndDiscr(
                  title: 'taskName'.tr,
                  discription: data.taskName,
                ),
                if (data.assignees.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text(
                    'taskAssignedTo'.tr,
                    style: theme.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TaskAssigneesSection(assignees: data.assignees),
                  SizedBox(height: 8.h),
                ] else
                  SupTextAndDiscr(
                    title: 'employeeName'.tr,
                    discription: data.employeeName,
                  ),
                SupTextAndDiscr(
                  title: 'numberOfPoints'.tr,
                  discription: data.points.toString(),
                ),
                if ((data.adminImg?.isNotEmpty ?? false) ||
                    (data.adminVideos?.isNotEmpty ?? false)) ...[
                  SizedBox(height: 10.h),
                  Text(
                    'adminAttachedMedia'.tr,
                    style: theme.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TaskMediaThumbnailRow(
                    images: data.adminImg ?? [],
                    videos: data.adminVideos ?? [],
                    thumbHeight: 100,
                    thumbWidth: 100,
                  ),
                ],
                if ((data.employeeImg?.isNotEmpty ?? false) ||
                    (data.employeeVideos?.isNotEmpty ?? false)) ...[
                  SizedBox(height: 10.h),
                  Text(
                    'employeeProofSection'.tr,
                    style: theme.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TaskMediaThumbnailRow(
                    images: data.employeeImg ?? [],
                    videos: data.employeeVideos ?? [],
                    thumbHeight: 100,
                    thumbWidth: 100,
                  ),
                ],
                if (userType != 'admin' &&
                    data.isForcedToUploadImg &&
                    data.status != 'completed') ...[
                  SizedBox(height: 10.h),
                  Text(
                    'uploadTaskProof'.tr,
                    style: theme.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: ThemeService.isDark.value
                          ? AppColors.customGreyColor6
                          : AppColors.customGreyColor4,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  MediaUploadButton(
                    allowedType: MediaType.both,
                    onFilesChanged: (files) {
                      controller.selectedFile
                        ..clear()
                        ..addAll(files);
                    },
                    title: 'employeeImage'.tr,
                  ),
                  if (controller.selectedFile.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    AppButton(
                      isLoading: controller.isLoading,
                      text: 'uploadPersonalIdImage',
                      onPressed: () async {
                        await controller.uploadTaskImage(
                          taskId: data.taskId.toString(),
                        );
                      },
                    ),
                  ],
                ],
                if (hasPlayableAudio(data.audio)) ...[
                  SizedBox(height: 10.h),
                  Text(
                    'recordAudio'.tr,
                    style: theme.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: ThemeService.isDark.value
                          ? AppColors.customGreyColor6
                          : AppColors.customGreyColor4,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  AudioPlayerWidget(url: data.audio!),
                ],
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     Flexible(
                //       child:
                //     ),
                //     SizedBox(width: 10.w),
                //     Flexible(
                //       child: Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           Text(
                //             'employeeImage'.tr,
                //             style: theme.copyWith(
                //               fontSize: 14.sp,
                //               fontWeight: FontWeight.w700,
                //               color: ThemeService.isDark.value
                //                   ? AppColors.customGreyColor6
                //                   : AppColors.customGreyColor4,
                //             ),
                //           ),
                //           SizedBox(height: 5.h),
                //           ClipRRect(
                //             borderRadius: BorderRadius.circular(5.r),
                //             child: CachedNetworkImage(
                //               imageUrl: data.employeeImg!,
                //               placeholder: (context, url) => Center(
                //                 child: const CircularProgressIndicator(),
                //               ),
                //               errorWidget: (context, url, error) =>
                //                   const Icon(Icons.error),
                //               fit: BoxFit.fill,
                //               width: 250.w,
                //               height: 200.h,
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ],
                // ),
                if (data.taskDescription.isNotEmpty)
                  SupTextAndDiscr(
                    title: 'taskDescription',
                    discription: data.taskDescription,
                  ),
                if (data.notes.isNotEmpty)
                  SupTextAndDiscr(
                    title: 'notes',
                    discription: data.notes,
                  ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'subTasks'.tr,
                        style: theme.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      Container(
                        color: AppColors.primaryColor,
                        width: double.infinity,
                        height: 1.h,
                      ),
                    ],
                  ),
                ),
                data.subTasks.isEmpty
                    ? Center(
                        child: Text(
                          'لا يوجد مهام فرعية'.tr,
                          style: theme.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.customGreyColor4,
                          ),
                        ),
                      )
                    : MarkTaskComplete(data: data),
                SizedBox(height: 15.h),
                TaskTimelineSection(events: data.timeline),
                SizedBox(height: 15.h),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11.r),
                    border: Border.all(color: AppColors.customGreyColor6),
                  ),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SupTextAndDiscr(
                        noSized: true,
                        title: 'taskRepeat'.tr,
                        discription: data.taskRecurrence.tr,
                      ),
                      if (data.taskRecurrence != 'noRepeat')
                        SupTextAndDiscr(
                          title: 'taskRepeatDate'.tr,
                          discription: data.taskRecurrenceTime
                              .map((e) => e.tr)
                              .join(' ,'),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 15.h),
                if (userType == 'admin' && controller.currentTab.value != 1)
                  AppButton(
                    isLoading: controller.isLoading,
                    text: 'cancelTask',
                    onPressed: () {
                      controller.cancelEmployeeTask(
                        taskId: data.taskId.toString(),
                        cancelWithRepetition: false,
                        isCompleted: true,
                      );
                    },
                  ),
                if (userType != 'admin' &&
                    data.status != 'completed' &&
                    data.status != 'waiting_review' &&
                    data.subTasks.isEmpty) ...[
                  AppButton(
                    isLoading: controller.isLoading,
                    text: 'completeTask',
                    onPressed: () async {
                      final args = Get.arguments as Map<String, dynamic>?;
                      final EmployeeDashbordController? dashboardController =
                          args?['EmployeeDashbordController'];
                      if (dashboardController == null) return;

                      if (!controller.canCompleteTask(data)) {
                        Get.snackbar(
                          'error'.tr,
                          'employeeImageRequired'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }

                      if (controller.selectedFile.isNotEmpty) {
                        final uploaded = await controller.uploadTaskImage(
                          taskId: data.taskId.toString(),
                        );
                        if (!uploaded) return;
                      }

                      dashboardController.changeTaskToCompleted(
                        taskId: data.taskId,
                        isSubTask: false,
                        context: context,
                      );
                      Get.back();
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class SupTextAndDiscr extends StatelessWidget {
  const SupTextAndDiscr({
    Key? key,
    required this.title,
    this.titleColor,
    required this.discription,
    this.noSized = false,
    this.discriptionColor,
  }) : super(key: key);

  final String title;
  final String discription;
  final bool noSized;
  final Color? titleColor;
  final Color? discriptionColor;
  @override
  Widget build(BuildContext context) {
    final TextStyle theme = Theme.of(context).textTheme.bodyMedium!;
    return Column(
      children: [
        SizedBox(height: noSized ? 0 : 15.h),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: "${title.tr}: ",
                style: theme.copyWith(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: titleColor ??
                      (ThemeService.isDark.value
                          ? AppColors.customGreyColor6
                          : AppColors.customGreyColor4),
                ),
              ),
              TextSpan(
                text: discription.tr,
                style: theme.copyWith(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w400,
                  color: discriptionColor ??
                      (ThemeService.isDark.value
                          ? AppColors.customGreyColor6
                          : AppColors.customGreyColor4),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
