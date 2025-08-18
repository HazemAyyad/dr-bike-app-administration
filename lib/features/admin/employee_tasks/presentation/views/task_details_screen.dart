import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_chechbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/employee_tasks_controller.dart';

class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String title = Get.arguments['title'];
    final EmployeeTasksController controller = Get.arguments['controller'];

    final TextStyle theme = Theme.of(context).textTheme.bodyMedium!;
    return Scaffold(
      appBar: CustomAppBar(
        title: title,
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
                arguments: 'createNewEmployeeTask',
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
          final testt = controller.employeeTaskService.taskDetails.value!;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SizedBox(height: 10.h),
                // Text(
                //   " 1 مارس الى 3 مارس",
                //   style:theme.copyWith(
                //         fontSize: 15.sp,
                //         fontWeight: FontWeight.w700,
                //         color: ThemeService.isDark.value
                //             ? AppColors.customGreyColor6
                //             : AppColors.customGreyColor4,
                //       ),
                // ),
                SupTextAndDis(
                  title: 'taskName'.tr,
                  discription: testt.taskName,
                ),
                title == 'employeeTaskDetails'
                    ? SupTextAndDis(
                        title: 'employeeName'.tr,
                        discription: testt.taskName,
                      )
                    : const SizedBox.shrink(),
                title == 'employeeTaskDetails'
                    ? SupTextAndDis(
                        title: 'numberOfPoints'.tr,
                        discription: testt.points.toString(),
                      )
                    : const SizedBox.shrink(),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5.r),
                            child: CachedNetworkImage(
                              imageUrl: testt.adminImg!,
                              placeholder: (context, url) => Center(
                                child: const CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                              fit: BoxFit.fill,
                              width: 250.w,
                              height: 200.h,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Flexible(
                      child: Column(
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5.r),
                            child: CachedNetworkImage(
                              imageUrl: controller
                                  .employeeTaskService
                                  .subtaskAdminImgPath
                                  .value!
                                  .subtaskAdminImgPath,
                              placeholder: (context, url) => Center(
                                child: const CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                              fit: BoxFit.fill,
                              width: 250.w,
                              height: 200.h,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SupTextAndDis(
                  title: 'taskDescription',
                  discription: testt.taskDescription,
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
                ...testt.subTasks.map(
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
                      border: Border.all(color: AppColors.customGreyColor6),
                    ),
                    height: 70.h,
                    width: double.infinity,
                    child: Row(
                      children: [
                        Flexible(
                          child: CustomCheckBox(
                            scale: 1.5,
                            shape: CircleBorder(
                              side: BorderSide(color: AppColors.primaryColor),
                            ),
                            title: '${tasks.name}${'\n'}${tasks.description}',
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: CachedNetworkImage(
                            imageUrl:
                                '${EndPoints.baserUrlForImage}public/AdminEmployeeTasksImages/${tasks.adminImg!.split('/')[3]}',
                            placeholder: (context, url) => Center(
                              child: const CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                            fit: BoxFit.fill,
                            width: 55.w,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                        discription: testt.taskRecurrence.tr,
                      ),
                      SupTextAndDis(
                        title: 'taskRepeatDate'.tr,
                        discription: testt.taskRecurrenceTime
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
                    taskId: testt.taskId.toString(),
                    cancelWithRepetition: false,
                  ),
                ),
                SizedBox(height: 20.h),
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
