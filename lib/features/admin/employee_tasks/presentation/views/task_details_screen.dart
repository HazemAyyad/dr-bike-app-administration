import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_chechbox.dart';
import 'package:doctorbike/core/helpers/custom_upload_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../employee/employee_dashbord/presentation/controllers/employee_dashbord_controller.dart';
import '../controllers/employee_tasks_controller.dart';
import '../widgets/audio_player.dart';

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
              ? TextButton.icon(
                  icon: Icon(
                    Icons.edit_calendar_outlined,
                    color: ThemeService.isDark.value
                        ? AppColors.primaryColor
                        : AppColors.secondaryColor,
                    size: 25.sp,
                  ),
                  onPressed: () {
                    Get.toNamed(
                      AppRoutes.CREATETASKSCREEN,
                      arguments: {'title': 'editEmployeeTask', 'isEdit': true},
                    );
                  },
                  label: Text(
                    'edit'.tr,
                    style: theme.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: ThemeService.isDark.value
                          ? AppColors.primaryColor
                          : AppColors.secondaryColor,
                    ),
                  ),
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
                SupTextAndDiscr(
                  title: 'taskName'.tr,
                  discription: data.taskName,
                ),
                SupTextAndDiscr(
                  title: 'employeeName'.tr,
                  discription: data.employeeName,
                ),
                SupTextAndDiscr(
                  title: 'numberOfPoints'.tr,
                  discription: data.points.toString(),
                ),
                SizedBox(height: 10.h),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'adminImage'.tr,
                      style: theme.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: ThemeService.isDark.value
                            ? AppColors.customGreyColor6
                            : AppColors.customGreyColor4,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...data.adminImg!.map(
                            (e) => Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5.w),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5.r),
                                child: GestureDetector(
                                  onTap: () {
                                    showGeneralDialog(
                                      context: context,
                                      barrierDismissible: true,
                                      barrierLabel: 'Dismiss',
                                      barrierColor: Colors.black.withAlpha(128),
                                      transitionDuration:
                                          const Duration(milliseconds: 300),
                                      pageBuilder: (context, anim1, anim2) {
                                        return FullScreenZoomImage(
                                          imageUrl: e,
                                        );
                                      },
                                    );
                                  },
                                  child: CachedNetworkImage(
                                    imageUrl: e,
                                    height: 200.h,
                                    width: 200.w,
                                    fit: BoxFit.fill,
                                    fadeInDuration:
                                        const Duration(milliseconds: 200),
                                    fadeOutDuration:
                                        const Duration(milliseconds: 200),
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.error),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'employeeImage'.tr,
                      style: theme.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: ThemeService.isDark.value
                            ? AppColors.customGreyColor6
                            : AppColors.customGreyColor4,
                      ),
                    ),
                    userType != 'admin'
                        ? Column(
                            children: [
                              SizedBox(height: 10.h),
                              MediaUploadButton(
                                allowedType: MediaType.image,
                                onFilesChanged: (files) {
                                  controller.selectedFile = files;
                                },
                                title: 'employeeImage'.tr,
                              ),
                            ],
                          )
                        : const SizedBox(),
                    SizedBox(height: 10.h),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...data.employeeImg!.map(
                            (e) => Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5.w),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5.r),
                                child: GestureDetector(
                                  onTap: () {
                                    showGeneralDialog(
                                      context: context,
                                      barrierDismissible: true,
                                      barrierLabel: 'Dismiss',
                                      barrierColor: Colors.black.withAlpha(128),
                                      transitionDuration:
                                          const Duration(milliseconds: 300),
                                      pageBuilder: (context, anim1, anim2) {
                                        return FullScreenZoomImage(
                                          imageUrl: e,
                                        );
                                      },
                                    );
                                  },
                                  child: CachedNetworkImage(
                                    imageUrl: e,
                                    height: 200.h,
                                    width: 200.w,
                                    fit: BoxFit.fill,
                                    fadeInDuration:
                                        const Duration(milliseconds: 200),
                                    fadeOutDuration:
                                        const Duration(milliseconds: 200),
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.error),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                data.audio!.isNotEmpty &&
                        data.audio != null &&
                        data.audio!.contains('.aac')
                    ? AudioPlayerWidget(url: data.audio!)
                    : const SizedBox.shrink(),
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
                    : Column(
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
                                border: Border.all(
                                    color: AppColors.customGreyColor6),
                              ),
                              height: 70.h,
                              width: double.infinity,
                              child: Row(
                                children: [
                                  Flexible(
                                    child: CustomCheckBox(
                                      scale: 1.5,
                                      shape: const CircleBorder(
                                        side: BorderSide(
                                            color: AppColors.primaryColor),
                                      ),
                                      title:
                                          '${tasks.name}${'\n'}${tasks.description}',
                                      style: theme.copyWith(
                                        decoration: tasks.status == 'ongoing'
                                            ? TextDecoration.none
                                            : TextDecoration.lineThrough,
                                        fontSize: 14.sp,
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
                                              : (value) {
                                                  final String mainTaskId =
                                                      Get.arguments['taskId'];

                                                  final args = Get.arguments
                                                      as Map<String, dynamic>?;
                                                  final EmployeeDashbordController
                                                      controller1 = args?[
                                                          'EmployeeDashbordController'];

                                                  controller.uploadTaskImage(
                                                    taskId: tasks.id.toString(),
                                                  );
                                                  controller1
                                                      .changeTaskToCompleted(
                                                    taskId: tasks.id,
                                                    isSubTask: true,
                                                    context: context,
                                                    mainTaskId: mainTaskId,
                                                  );
                                                },
                                    ),
                                  ),
                                  tasks.adminImg!.isEmpty
                                      ? const SizedBox()
                                      : ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10.r),
                                          child: GestureDetector(
                                            onTap: () {
                                              showGeneralDialog(
                                                context: context,
                                                barrierDismissible: true,
                                                barrierLabel: 'Dismiss',
                                                barrierColor:
                                                    Colors.black.withAlpha(128),
                                                transitionDuration:
                                                    const Duration(
                                                        milliseconds: 300),
                                                pageBuilder:
                                                    (context, anim1, anim2) {
                                                  return FullScreenZoomImage(
                                                    imageUrl:
                                                        tasks.adminImg!.first,
                                                  );
                                                },
                                              );
                                            },
                                            child: CachedNetworkImage(
                                              imageUrl: tasks.adminImg!.first,
                                              placeholder: (context, url) =>
                                                  const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(Icons.error),
                                              fit: BoxFit.fill,
                                              height: double.infinity,
                                              width: 60.w,
                                            ),
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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
                // userType == 'admin'
                // ?
                AppButton(
                  isLoading: controller.isLoading,
                  text: 'cancelTask',
                  onPressed: userType == 'admin'
                      ? () {
                          controller.cancelEmployeeTask(
                            taskId: data.taskId.toString(),
                            cancelWithRepetition: false,
                            isCompleted: true,
                          );
                        }
                      : () {
                          final args = Get.arguments as Map<String, dynamic>?;
                          final EmployeeDashbordController controller1 =
                              args?['EmployeeDashbordController'];
                          controller.uploadTaskImage(
                            taskId: data.taskId.toString(),
                          );
                          controller1.changeTaskToCompleted(
                            taskId: data.taskId,
                            isSubTask: false,
                            context: context,
                          );
                          Get.back();
                        },
                )
                // : SizedBox.shrink(),
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
  }) : super(key: key);

  final String title;
  final String discription;
  final bool noSized;
  final Color? titleColor;
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
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor6
                      : AppColors.customGreyColor4,
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
