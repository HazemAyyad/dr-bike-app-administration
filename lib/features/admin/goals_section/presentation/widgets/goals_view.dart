import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/features/admin/goals_section/data/models/goals_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/goals_services.dart';
import '../controllers/target_section_controller.dart';

class GoalsView extends StatelessWidget {
  const GoalsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TargetSectionController>(
      builder: (controller) {
        if (controller.isLoading.value) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (controller.currentTab.value == 0 &&
            GoalsServices().globalGoalsList.isEmpty) {
          return const SliverFillRemaining(child: ShowNoData());
        }
        if (controller.currentTab.value == 1 &&
            GoalsServices().privateGoalsList.isEmpty) {
          return const SliverFillRemaining(child: ShowNoData());
        }
        if (controller.currentTab.value == 2 &&
            GoalsServices().archiveGoalsList.isEmpty) {
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
              mainAxisExtent: 180.h,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final goal = controller.currentTab.value == 0
                    ? GoalsServices().globalGoalsList.reversed.toList()[index]
                    : controller.currentTab.value == 1
                        ? GoalsServices()
                            .privateGoalsList
                            .reversed
                            .toList()[index]
                        : GoalsServices()
                            .archiveGoalsList
                            .reversed
                            .toList()[index];
                return GestureDetector(
                  onLongPress: () {
                    controller.currentTab.value == 2
                        ? null
                        : Get.dialog(
                            DeleteGoalDialog(goal: goal),
                          );
                  },
                  onTap: () => {
                    controller.getGoalDetails(goalId: goal.id.toString()),
                    Get.toNamed(AppRoutes.TARGETDETAILSSCREEN),
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
                                '${goal.achievementPercentage}%',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      fontSize: 13.sp,
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
                                    value: (double.parse(
                                            goal.achievementPercentage) /
                                        100),
                                    strokeWidth: 8,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      double.parse(
                                                  goal.achievementPercentage) >=
                                              100
                                          ? Colors.green
                                          : AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Flexible(
                          child: Text(
                            goal.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: ThemeService.isDark.value
                                      ? AppColors.whiteColor2
                                      : AppColors.blackColor,
                                ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Flexible(
                          child: Text(
                            '${'targetValue'.tr}: ${NumberFormat('#,###').format(double.parse(goal.targetValue))}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w400,
                                  color: ThemeService.isDark.value
                                      ? AppColors.whiteColor2
                                      : AppColors.blackColor,
                                ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Flexible(
                          child: Text(
                            '${'currentValue'.tr}: ${NumberFormat('#,###').format(double.parse(goal.currentValue))}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w400,
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
                  ? GoalsServices().globalGoalsList.toList().length
                  : controller.currentTab.value == 1
                      ? GoalsServices().privateGoalsList.toList().length
                      : GoalsServices().archiveGoalsList.toList().length,
            ),
          ),
        );
      },
    );
  }
}

class DeleteGoalDialog extends GetView<TargetSectionController> {
  const DeleteGoalDialog({Key? key, required this.goal}) : super(key: key);

  final GoalsModel goal;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11.r),
      ),
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      child: Obx(
        () => Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24.w,
            vertical: 15.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomCheckBox(
                value: RxBool(!controller.isDelete.value == false),
                onChanged: (val) {
                  controller.isDelete.value = true;
                },
                title: 'cancelTarget',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: ThemeService.isDark.value
                          ? AppColors.whiteColor2
                          : AppColors.blackColor,
                    ),
              ),
              CustomCheckBox(
                value: RxBool(!controller.isDelete.value == true),
                onChanged: (value) {
                  controller.isDelete.value = false;
                },
                title: 'transferGoal',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: ThemeService.isDark.value
                          ? AppColors.whiteColor2
                          : AppColors.blackColor,
                    ),
              ),
              SizedBox(height: 15.h),
              AppButton(
                isSafeArea: false,
                isLoading: controller.isLoading,
                text: 'done',
                onPressed: () {
                  controller.getGoalDetails(
                    goalId: goal.id.toString(),
                    isCancel: controller.isDelete.value ? true : null,
                    isTransfer: controller.isDelete.value ? null : true,
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
