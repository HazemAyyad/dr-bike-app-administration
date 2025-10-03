import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:doctorbike/core/helpers/showtime.dart';
import 'package:doctorbike/features/admin/employee_section/data/models/logs_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../employee_tasks/presentation/views/task_details_screen.dart';
import '../controllers/employee_section_controller.dart';

class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'activityLog', action: false),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                height: 32.h,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const CustomText(title: 'activity'),
                    const CustomText(title: 'description'),
                    SizedBox(width: 0.w),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: GetBuilder<EmployeeSectionController>(
                builder: (controller) {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (controller.employeeService.logsMap.isEmpty) {
                    return Column(
                      children: [
                        SizedBox(height: 250.h),
                        const ShowNoData(),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      ...controller.employeeService.logsMap.entries
                          .take(30)
                          .map(
                        (entry) {
                          final dateKey = entry.key;
                          final logs = entry.value;
                          if (logs.isEmpty) {
                            return const ShowNoData();
                          }
                          if (controller.isDialogLoading.value) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10.h),
                              Text(
                                dateKey,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14.sp,
                                    ),
                              ),
                              ...logs.map(
                                (log) => GestureDetector(
                                  onTap: () {
                                    Get.dialog(
                                      ShowLogDetails(log: log),
                                    );
                                  },
                                  child: Container(
                                    margin: EdgeInsets.symmetric(vertical: 5.h),
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 10.w),
                                    height: 40.h,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.primaryColor,
                                        width: 1.w,
                                      ),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        CustomText(
                                          title: log.name,
                                          color: AppColors.customGreyColor2,
                                        ),
                                        SizedBox(width: 5.w),
                                        Container(
                                          width: 1.w,
                                          height: 20.h,
                                          color: AppColors.primaryColor,
                                        ),
                                        SizedBox(width: 5.w),
                                        CustomText(
                                          title: log.description,
                                          color: AppColors.customGreyColor2,
                                        ),
                                        Container(
                                          width: 1.w,
                                          height: 20.h,
                                          color: AppColors.primaryColor,
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            controller.cancelLog(
                                              context: context,
                                              logId: log.id.toString(),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 50.h),
                    ],
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ShowLogDetails extends StatelessWidget {
  const ShowLogDetails({Key? key, required this.log}) : super(key: key);

  final LogsModel log;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 10.w,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            15.r,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 10.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(),
                    Text(
                      'details'.tr,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: ThemeService.isDark.value
                                ? AppColors.primaryColor
                                : AppColors.secondaryColor,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        Icons.close,
                        color: AppColors.redColor,
                        size: 30.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SupTextAndDiscr(
                title: 'activity',
                titleColor: AppColors.primaryColor,
                discription: log.name,
              ),
              SupTextAndDiscr(
                title: 'description',
                titleColor: AppColors.primaryColor,
                discription: log.description,
              ),
              SupTextAndDiscr(
                title: 'details',
                titleColor: AppColors.primaryColor,
                discription: log.type,
              ),
              SupTextAndDiscr(
                title: 'day',
                titleColor: AppColors.primaryColor,
                discription: showDataAndTime(log.createdAt),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomText extends StatelessWidget {
  const CustomText({
    Key? key,
    required this.title,
    this.color,
  }) : super(key: key);
  final String title;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Text(
        title.tr,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: color ?? Colors.white,
              fontWeight: FontWeight.w400,
              fontSize: 14.sp,
            ),
      ),
    );
  }
}
