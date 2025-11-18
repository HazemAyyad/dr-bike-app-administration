import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../../employee_tasks/presentation/views/task_details_screen.dart';
import '../controllers/employee_section_controller.dart';

class EmployeeDetailsScreen extends GetView<EmployeeSectionController> {
  const EmployeeDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextStyle theme = Theme.of(context).textTheme.bodyMedium!;
    final String points = Get.arguments;
    return Scaffold(
      appBar: CustomAppBar(
        title: 'employeeDetails',
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
                AppRoutes.ADDNEWEMPLOYEESCREEN,
                arguments: {'AddNewEmployeeScreen': 'editEmployee'},
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
          if (controller.employeeService.employeeDetails.value == null) {
            Center(
              child: Text(
                'noData'.tr,
                style: theme.copyWith(
                  color: AppColors.customGreyColor,
                ),
              ),
            );
          }
          return controller.isDialogLoading.value
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10.h, width: double.infinity),
                      SupTextAndDiscr(
                        title: 'employeeName',
                        discription: controller
                            .employeeService.employeeDetails.value!.name,
                      ),
                      SizedBox(height: 15.h),
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
                            ...controller.employeeService.employeeDetails.value!
                                .employeeImg
                                .map(
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
                                        barrierColor:
                                            Colors.black.withAlpha(128),
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
                                      fadeInDuration:
                                          const Duration(milliseconds: 200),
                                      fadeOutDuration:
                                          const Duration(milliseconds: 200),
                                      placeholder: (context, url) =>
                                          const Center(
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

                      SizedBox(width: 10.w),
                      Text(
                        'documentsImages'.tr,
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
                            ...controller.employeeService.employeeDetails.value!
                                .documentImg
                                .map(
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
                                        barrierColor:
                                            Colors.black.withAlpha(128),
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
                                      fadeInDuration:
                                          const Duration(milliseconds: 200),
                                      fadeOutDuration:
                                          const Duration(milliseconds: 200),
                                      placeholder: (context, url) =>
                                          const Center(
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
                      SizedBox(height: 5.h),
                      Row(
                        children: [
                          Flexible(
                            child: SupTextAndDiscr(
                              title: 'email',
                              discription: controller
                                  .employeeService.employeeDetails.value!.email,
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              // نسخ النص إلى الكليب بورد
                              await Clipboard.setData(ClipboardData(
                                  text: controller.employeeService
                                      .employeeDetails.value!.email));
                              // عرض رسالة تأكيد
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '✅ تم نسخ النص: "${controller.employeeService.employeeDetails.value!.email}"'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      SupTextAndDiscr(
                        title: 'phoneNumber',
                        discription: controller
                            .employeeService.employeeDetails.value!.phone
                            .replaceAll(' ', ''),
                      ),
                      SizedBox(height: 10.h),
                      SupTextAndDiscr(
                        title: 'alternatePhone',
                        discription: controller
                            .employeeService.employeeDetails.value!.subPhone
                            .replaceAll(' ', ''),
                      ),
                      // SizedBox(height: 10.h),
                      // SupTextAndDis(
                      //   title: 'employeeJobTitle',
                      //   discription: arguments.,
                      // ),
                      SizedBox(height: 10.h),
                      SupTextAndDiscr(
                        title: 'hourlyRate',
                        discription:
                            '${controller.employeeService.employeeDetails.value!.hourWorkPrice.toString()} ${'currency'.tr}',
                      ),
                      SizedBox(height: 10.h),
                      SupTextAndDiscr(
                        title: 'overTimeRate',
                        discription:
                            '${controller.employeeService.employeeDetails.value!.overtimeWorkPrice} ${'currency'.tr}',
                      ),
                      SizedBox(height: 10.h),
                      SupTextAndDiscr(
                        title: 'workHoursOfDay',
                        discription: int.parse(controller.employeeService
                                    .employeeDetails.value!.numberOfWorkHours) >
                                10
                            ? '${controller.employeeService.employeeDetails.value!.numberOfWorkHours} ${'hour'.tr}'
                            : '${controller.employeeService.employeeDetails.value!.numberOfWorkHours} ${'hours'.tr}',
                      ),
                      SizedBox(height: 10.h),
                      SupTextAndDiscr(
                        title: 'regularWorkingHours',
                        discription:
                            "${'from'.tr} ${formatTimeTo12Hour(controller.employeeService.employeeDetails.value!.startWorkTime)} ${'to'.tr} ${formatTimeTo12Hour(controller.employeeService.employeeDetails.value!.endWorkTime)}",
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: SupTextAndDiscr(
                              title: 'points',
                              discription: points,
                            ),
                          ),
                          Flexible(
                            child: IconButton(
                              onPressed: () {
                                Get.dialog(
                                  Dialog(
                                    backgroundColor: ThemeService.isDark.value
                                        ? AppColors.darkColor
                                        : AppColors.whiteColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'pointsHistory'.tr,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .copyWith(
                                                  fontSize: 20.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primaryColor,
                                                ),
                                          ),
                                          SizedBox(height: 10.h),
                                          ...controller
                                              .employeeService
                                              .employeeDetails
                                              .value!
                                              .rewardPunishment
                                              .map(
                                            (e) => Padding(
                                              padding: const EdgeInsets.all(5),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: [
                                                      Flexible(
                                                        child: Row(
                                                          children: [
                                                            Text(
                                                              e.type.tr,
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodyMedium!
                                                                  .copyWith(
                                                                    fontSize:
                                                                        17.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    color: AppColors
                                                                        .primaryColor,
                                                                  ),
                                                            ),
                                                            Text(
                                                              ' : ${e.points} ${'point'.tr}',
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodyMedium!
                                                                  .copyWith(
                                                                      fontSize:
                                                                          17.sp),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Flexible(
                                                        child: SupTextAndDiscr(
                                                          noSized: true,
                                                          title: 'notes',
                                                          discription: e.notes,
                                                          titleColor: AppColors
                                                              .primaryColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Container(
                                                    margin:
                                                        EdgeInsets.symmetric(
                                                      vertical: 5.h,
                                                      horizontal: 20.w,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors
                                                          .primaryColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.r),
                                                    ),
                                                    height: 1.h,
                                                    width: double.infinity,
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.list_alt_rounded,
                                color: AppColors.primaryColor,
                                size: 30.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      SupTextAndDiscr(
                          title: 'permissions',
                          discription:
                              "\n -${controller.employeeService.employeeDetails.value!.permissions.map((e) => e.permissionName).join(', ').replaceAll(', ', '\n-')}"),
                      SizedBox(height: 30.h),
                    ],
                  ),
                );
        },
      ),
    );
  }
}
