import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/custom_chechbox.dart';
import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:doctorbike/core/utils/assets_manger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/special_tasks_controller.dart';

class SpecialTaskDetailsScreen extends GetView<SpecialTasksController> {
  const SpecialTaskDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextStyle theme = Theme.of(context).textTheme.bodyMedium!;
    return Scaffold(
      appBar: CustomAppBar(
        title: 'privateTaskDetails',
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
                      arguments: {
                        'title': 'editSpecialTask',
                        'isEdit': true,
                      },
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
          if (controller.isGetLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.specialTasksService.specialTaskDetails.value == null) {
            return const ShowNoData();
          }
          final data = controller.specialTasksService.specialTaskDetails.value!;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SupTextAndDis(title: 'taskName'.tr, discription: data.taskName),
                SizedBox(height: 10.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...data.adminImg.map(
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
                                cacheManager: CacheManager(
                                  Config(
                                    'imagesCache',
                                    stalePeriod: const Duration(days: 7),
                                    maxNrOfCacheObjects: 100,
                                  ),
                                ),
                                imageBuilder: (context, imageProvider) =>
                                    Container(
                                  height: 200.h,
                                  width: 200.w,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.fill,
                                      filterQuality: FilterQuality.medium,
                                    ),
                                  ),
                                ),
                                imageUrl: e,
                                fadeInDuration:
                                    const Duration(milliseconds: 200),
                                fadeOutDuration:
                                    const Duration(milliseconds: 200),
                                placeholder: (context, url) => SizedBox(
                                  height: 200.h,
                                  width: 200.w,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
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
                if (data.taskDescription.isNotEmpty)
                  SupTextAndDis(
                    title: 'taskDescription',
                    discription: data.taskDescription,
                  ),
                if (data.notes.isNotEmpty)
                  SupTextAndDis(
                    title: 'taskNotes',
                    discription: data.notes,
                  ),
                if (data.subTasks.isNotEmpty)
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
                    height: 55.h,
                    width: double.infinity,
                    child: Row(
                      children: [
                        Flexible(
                          child: CustomCheckBox(
                            scale: 1.5,
                            shape: const CircleBorder(
                              side: BorderSide(color: AppColors.primaryColor),
                            ),
                            title:
                                '${tasks.subTaskName}${'\n'}${tasks.subTaskDescription}',
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
                            value: (tasks.status != 'ongoing').obs,
                            onChanged: (value) {
                              if (tasks.status != 'ongoing') return;
                              controller.makeSubsSpecialTaskCompleted(
                                context,
                                tasks.subTaskId.toString(),
                                data.taskId.toString(),
                              );
                            },
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: CachedNetworkImage(
                            cacheManager: CacheManager(
                              Config(
                                'imagesCache',
                                stalePeriod: const Duration(days: 7),
                                maxNrOfCacheObjects: 100,
                              ),
                            ),
                            imageBuilder: (context, imageProvider) => Container(
                              width: 55.w,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.fill,
                                  filterQuality: FilterQuality.medium,
                                ),
                              ),
                            ),
                            imageUrl: tasks.adminImg.isNotEmpty
                                ? tasks.adminImg.first
                                : AssetsManager.noImageNet,
                            placeholder: (context, url) => SizedBox(
                              width: 55.w,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      SupTextAndDis(
                        noSized: true,
                        title: 'taskRepeat',
                        discription: data.taskRecurrence.tr,
                      ),
                      data.taskRecurrence == 'noRepeat'
                          ? const SizedBox.shrink()
                          : SupTextAndDis(
                              title: 'taskRepeatDate',
                              discription: data.taskRecurrenceTime
                                  .map((e) => e.tr)
                                  .join(' ,'),
                            ),
                    ],
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
