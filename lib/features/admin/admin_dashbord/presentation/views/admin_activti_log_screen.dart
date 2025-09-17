import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../employee_section/presentation/views/activity_log_screen.dart';
import '../controllers/admin_dashboard_controller.dart';

class AdminActivtiLogScreen extends GetView<AdminDashboardController> {
  const AdminActivtiLogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'activityLog', action: false),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Column(
                  children: [
                    Flexible(
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
                  ],
                ),
              ),
            ),
            GetBuilder<AdminDashboardController>(
              builder: (controller) {
                if (controller.isLoading.value) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return SliverToBoxAdapter(
                  child: Column(
                    children: [
                      ...controller.logsMap.entries.take(30).map(
                        (entry) {
                          final dateKey = entry.key;
                          final logs = entry.value;
                          if (logs.isEmpty) {
                            return const ShowNoData();
                          }
                          if (controller.isLoading.value) {
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
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
