import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:doctorbike/features/admin/projects/presentation/controllers/project_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';

class ProjectView extends GetView<ProjectController> {
  const ProjectView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        if (controller.isLoading.value) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (controller.currentTab.value == 0 &&
            controller.ongoingProjectsSearch.isEmpty) {
          return const SliverFillRemaining(child: ShowNoData());
        }
        if (controller.currentTab.value == 1 &&
            controller.completedProjectsSearch.isEmpty) {
          return const SliverFillRemaining(child: ShowNoData());
        }
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              mainAxisSpacing: 10.h,
              crossAxisSpacing: 10.w,
              mainAxisExtent: 120.h,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final project = controller.currentTab.value == 0
                    ? controller.ongoingProjectsSearch.reversed.toList()[index]
                    : controller.completedProjectsSearch.reversed
                        .toList()[index];
                return GestureDetector(
                  onTap: () => {
                    controller.getProjectDetails(project.id),
                    Get.toNamed(AppRoutes.PROJECTDETAILSSCREEN),
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: ThemeService.isDark.value
                          ? AppColors.customGreyColor
                          : AppColors.whiteColor2,
                      borderRadius: BorderRadius.circular(9.r),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                '${project.achievementPercentage.toStringAsFixed(2)}%',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                      color: ThemeService.isDark.value
                                          ? AppColors.whiteColor2
                                          : AppColors.blackColor,
                                    ),
                              ),
                              Center(
                                child: SizedBox(
                                  height: 65.h,
                                  width: 70.w,
                                  child: CircularProgressIndicator(
                                    value: (project.achievementPercentage),
                                    strokeWidth: 7,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      project.achievementPercentage >= 100
                                          ? Colors.green
                                          : AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Flexible(
                          child: Text(
                            project.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: ThemeService.isDark.value
                                      ? AppColors.whiteColor2
                                      : AppColors.blackColor,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: controller.currentTab.value == 0
                  ? controller.ongoingProjectsSearch.length
                  : controller.completedProjectsSearch.length,
            ),
          ),
        );
      },
    );
  }
}
