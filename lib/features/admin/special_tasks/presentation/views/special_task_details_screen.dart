import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/custom_chechbox.dart';
import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:doctorbike/core/utils/assets_manger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/audio_helper.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../../employee_section/domain/entities/employee_entity.dart';
import '../../../employee_tasks/presentation/widgets/audio_player.dart';
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
          if (userType == 'admin')
            IconButton(
              tooltip: 'convertToEmployeeTask'.tr,
              icon: Icon(
                Icons.swap_horiz_rounded,
                color: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
                size: 24.sp,
              ),
              onPressed: () => _showConvertToEmployeeSheet(context),
            ),
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
                  AudioPlayerWidget(url: data.audio),
                ],
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
                              Get.dialog(
                                Dialog(
                                  backgroundColor: ThemeService.isDark.value
                                      ? AppColors.darkColor
                                      : AppColors.whiteColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(15.w),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                'areYouSure'.tr,
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium!
                                                    .copyWith(
                                                      fontSize: 18.sp,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppColors
                                                          .primaryColor,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 20.h),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: AppButton(
                                                isSafeArea: false,
                                                isLoading: controller.isLoading,
                                                text: 'yes',
                                                onPressed: () {
                                                  controller
                                                      .makeSubsSpecialTaskCompleted(
                                                    context,
                                                    tasks.subTaskId.toString(),
                                                    data.taskId.toString(),
                                                  );
                                                },
                                              ),
                                            ),
                                            SizedBox(width: 10.w),
                                            Expanded(
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
                                                      fontWeight:
                                                          FontWeight.w700,
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
                            },
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
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
                                    imageUrl: tasks.adminImg.isNotEmpty
                                        ? tasks.adminImg.first
                                        : AssetsManager.noImageNet,
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
                                width: 60.w,
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
                              fadeInDuration: const Duration(milliseconds: 200),
                              fadeOutDuration:
                                  const Duration(milliseconds: 200),
                              placeholder: (context, url) => SizedBox(
                                width: 60.w,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
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

  void _showConvertToEmployeeSheet(BuildContext context) {
    final details = controller.specialTasksService.specialTaskDetails.value;
    if (details == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 18.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'convertToEmployeeTask'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'convertToEmployeeTaskHint'.tr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.customGreyColor5,
                      ),
                ),
                SizedBox(height: 12.h),
                FutureBuilder<List<EmployeeEntity>>(
                  future: controller.employeesForConversion(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final employees = snapshot.data ?? [];
                    if (employees.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        child: Text('noData'.tr, textAlign: TextAlign.center),
                      );
                    }
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 420.h),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: employees.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final employee = employees[index];
                          return Obx(
                            () => ListTile(
                              enabled: !controller.isConvertingTask.value,
                              leading: const Icon(Icons.person_outline),
                              title: Text(employee.employeeName),
                              trailing: controller.isConvertingTask.value
                                  ? SizedBox(
                                      width: 18.w,
                                      height: 18.w,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.chevron_left),
                              onTap: () {
                                controller.convertSpecialTaskToEmployee(
                                  specialTaskId: details.taskId.toString(),
                                  employeeId: employee.id,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
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
