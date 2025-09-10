import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
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
                      SupTextAndDis(
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
                                      height: 200.h,
                                      width: 200.w,
                                      fit: BoxFit.fill,
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
                                      height: 200.h,
                                      width: 200.w,
                                      fit: BoxFit.fill,
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
                      SizedBox(height: 10.h),
                      SupTextAndDis(
                        title: 'email',
                        discription: controller
                            .employeeService.employeeDetails.value!.email,
                      ),
                      SizedBox(height: 10.h),
                      SupTextAndDis(
                        title: 'phoneNumber',
                        discription: controller
                            .employeeService.employeeDetails.value!.phone
                            .replaceAll(' ', ''),
                      ),
                      SizedBox(height: 10.h),
                      SupTextAndDis(
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
                      SupTextAndDis(
                        title: 'hourlyRate',
                        discription:
                            '${controller.employeeService.employeeDetails.value!.hourWorkPrice} ${'currency'.tr}',
                      ),
                      SizedBox(height: 10.h),
                      SupTextAndDis(
                        title: 'overTimeRate',
                        discription:
                            '${controller.employeeService.employeeDetails.value!.overtimeWorkPrice} ${'currency'.tr}',
                      ),
                      SizedBox(height: 10.h),
                      SupTextAndDis(
                        title: 'workHoursOfDay',
                        discription: int.parse(controller.employeeService
                                    .employeeDetails.value!.numberOfWorkHours) >
                                10
                            ? '${controller.employeeService.employeeDetails.value!.numberOfWorkHours} ${'hour'.tr}'
                            : '${controller.employeeService.employeeDetails.value!.numberOfWorkHours} ${'hours'.tr}',
                      ),
                      SizedBox(height: 10.h),
                      SupTextAndDis(
                        title: 'regularWorkingHours',
                        discription:
                            "${'from'.tr} ${formatTimeTo12Hour(controller.employeeService.employeeDetails.value!.startWorkTime)} ${'to'.tr} ${formatTimeTo12Hour(controller.employeeService.employeeDetails.value!.endWorkTime)}",
                      ),
                      SizedBox(height: 10.h),
                      SupTextAndDis(
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
