import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../employee/employee_dashbord/presentation/controllers/employee_dashbord_controller.dart';
import '../../data/models/task_details_model.dart';
import '../controllers/employee_tasks_controller.dart';

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
            height: 80.h,
            width: double.infinity,
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
                    title: '${tasks.name}${'\n'}${tasks.description}',
                    style: theme.copyWith(
                      decoration: tasks.status == 'ongoing'
                          ? TextDecoration.none
                          : TextDecoration.lineThrough,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: ThemeService.isDark.value
                          ? AppColors.customGreyColor6
                          : AppColors.customGreyColor4,
                    ),
                    value: tasks.status == 'ongoing' ? false.obs : true.obs,
                    onChanged: userType == 'admin'
                        ? (value) {}
                        : tasks.status != 'ongoing'
                            ? (value) {}
                            : (value) async {
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
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .copyWith(
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
                                                  isLoading:
                                                      controller.isLoading,
                                                  width: double.infinity,
                                                  borderRadius:
                                                      BorderRadius.all(
                                                    Radius.circular(8.r),
                                                  ),
                                                  text: 'yes'.tr,
                                                  textStyle: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium!
                                                      .copyWith(
                                                        color: Colors.white,
                                                        fontSize: 15.sp,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                  onPressed: () async {
                                                    Get.back();
                                                    final String mainTaskId =
                                                        Get.arguments['taskId'];
                                                    final args = Get.arguments
                                                        as Map<String,
                                                            dynamic>?;
                                                    final EmployeeDashbordController
                                                        controller1 = args?[
                                                            'EmployeeDashbordController'];
                                                    if (tasks
                                                        .isForcedToUploadImg) {
                                                      await controller
                                                          .uploadSubTaskImage(
                                                        taskId:
                                                            tasks.id.toString(),
                                                        context: context,
                                                      );
                                                    }
                                                    await controller
                                                        .uploadTaskImage(
                                                      taskId:
                                                          tasks.id.toString(),
                                                    );
                                                    controller1
                                                        .changeTaskToCompleted(
                                                      taskId: tasks.id,
                                                      isSubTask: true,
                                                      // ignore: use_build_context_synchronously
                                                      context: context,
                                                      mainTaskId: mainTaskId,
                                                    );
                                                  },
                                                ),
                                              ),
                                              SizedBox(width: 10.w),
                                              Flexible(
                                                child: AppButton(
                                                  isLoading:
                                                      controller.isLoading,
                                                  isSafeArea: false,
                                                  color: Colors.red,
                                                  width: double.infinity,
                                                  borderRadius:
                                                      BorderRadius.all(
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
                tasks.employeeImg!.isEmpty
                    ? const SizedBox()
                    : Column(
                        children: [
                          Text(
                            'employeeImage'.tr,
                            style: theme.copyWith(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                              color: ThemeService.isDark.value
                                  ? AppColors.customGreyColor6
                                  : AppColors.customGreyColor4,
                            ),
                          ),
                          Flexible(
                            child: ClipRRect(
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
                                        imageUrl: tasks.employeeImg!.first,
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
                                    height: double.infinity,
                                    width: 60.w,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.fill,
                                        filterQuality: FilterQuality.medium,
                                      ),
                                    ),
                                  ),
                                  imageUrl: tasks.employeeImg!.first,
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
                SizedBox(width: 10.w),
                tasks.adminImg!.isEmpty
                    ? const SizedBox()
                    : Column(
                        children: [
                          Text(
                            'adminImage'.tr,
                            style: theme.copyWith(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                              color: ThemeService.isDark.value
                                  ? AppColors.customGreyColor6
                                  : AppColors.customGreyColor4,
                            ),
                          ),
                          Flexible(
                            child: ClipRRect(
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
                                        imageUrl: tasks.adminImg!.first,
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
                                    height: double.infinity,
                                    width: 60.w,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.fill,
                                        filterQuality: FilterQuality.medium,
                                      ),
                                    ),
                                  ),
                                  imageUrl: tasks.adminImg!.first,
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}
