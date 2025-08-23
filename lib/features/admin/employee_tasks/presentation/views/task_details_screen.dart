import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_chechbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/employee_tasks_controller.dart';

class TaskDetailsScreen extends GetView<EmployeeTasksController> {
  const TaskDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextStyle theme = Theme.of(context).textTheme.bodyMedium!;
    return Scaffold(
      appBar: CustomAppBar(
        title: 'employeeTaskDetails',
        actions: [
          TextButton.icon(
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
                arguments: {'title': 'createNewEmployeeTask', 'isEdit': true},
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
          ),
        ],
      ),
      body: Obx(
        () {
          if (controller.isTaskDetailsLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = controller.employeeTaskService.taskDetails.value!;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SupTextAndDis(
                  title: 'taskName'.tr,
                  discription: data.taskName,
                ),
                SupTextAndDis(
                  title: 'employeeName'.tr,
                  discription: data.taskName,
                ),
                SupTextAndDis(
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
                    SizedBox(height: 5.h),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...data.employeeImg!.map(
                            (e) => Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5.w),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5.r),
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
                        ],
                      ),
                    ),
                  ],
                ),
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
                SupTextAndDis(
                  title: 'taskDescription',
                  discription: data.taskDescription,
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
                    ? SizedBox.shrink()
                    : Column(
                        children: [
                          ...data.subTasks.map(
                            (tasks) => Container(
                              margin: EdgeInsets.symmetric(vertical: 5.h),
                              padding: EdgeInsets.all(6),
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
                                      shape: CircleBorder(
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
                                      onChanged: (value) {},
                                    ),
                                  ),
                                  tasks.adminImg!.isEmpty
                                      ? const SizedBox()
                                      : ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10.r),
                                          child: CachedNetworkImage(
                                            imageUrl: tasks.adminImg!
                                                .map((e) => e)
                                                .toList()[0],
                                            placeholder: (context, url) =>
                                                Center(
                                              child:
                                                  const CircularProgressIndicator(),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(Icons.error),
                                            fit: BoxFit.fill,
                                            height: double.infinity,
                                            width: 60.w,
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
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11.r),
                    border: Border.all(color: AppColors.customGreyColor6),
                  ),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SupTextAndDis(
                        noSized: true,
                        title: 'taskRepeat'.tr,
                        discription: data.taskRecurrence.tr,
                      ),
                      if (data.taskRecurrence != 'noRepeat')
                        SupTextAndDis(
                          title: 'taskRepeatDate'.tr,
                          discription: data.taskRecurrenceTime
                              .map((e) => e.tr)
                              .join(' ,'),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 15.h),
                AppButton(
                  text: 'cancelTask',
                  onPressed: () => controller.cancelEmployeeTask(
                    context: context,
                    taskId: data.taskId.toString(),
                    cancelWithRepetition: false,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SupTextAndDis extends StatelessWidget {
  const SupTextAndDis({
    Key? key,
    required this.title,
    required this.discription,
    this.noSized = false,
  }) : super(key: key);

  final String title;
  final String discription;
  final bool noSized;
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
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor6
                      : AppColors.customGreyColor4,
                ),
              ),
              TextSpan(
                text: discription,
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
