import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/showtime.dart';
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
            controller.globalGoalsFilterList.isEmpty) {
          return const SliverFillRemaining(child: ShowNoData());
        }
        if (controller.currentTab.value == 1 &&
            controller.privateGoalsFilterList.isEmpty) {
          return const SliverFillRemaining(child: ShowNoData());
        }
        if (controller.currentTab.value == 2 &&
            controller.archiveGoalsFilterList.isEmpty) {
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
                    ? controller.globalGoalsFilterList.reversed.toList()[index]
                    : controller.currentTab.value == 1
                        ? controller.privateGoalsFilterList.reversed
                            .toList()[index]
                        : controller.archiveGoalsFilterList.reversed
                            .toList()[index];
                return GestureDetector(
                  onLongPress: () {
                    controller.currentTab.value == 2
                        ? Get.dialog(
                            Dialog(
                              backgroundColor: ThemeService.isDark.value
                                  ? AppColors.darkColor
                                  : AppColors.whiteColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${'delete'.tr} ${goal.name}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(
                                            color: ThemeService.isDark.value
                                                ? AppColors.whiteColor
                                                : AppColors.secondaryColor,
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    SizedBox(height: 20.h),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: AppButton(
                                            isSafeArea: false,
                                            text: 'cancel'.tr,
                                            onPressed: () {
                                              Get.back();
                                            },
                                          ),
                                        ),
                                        SizedBox(width: 10.w),
                                        Expanded(
                                          child: AppButton(
                                            isLoading: controller.isAddLoading,
                                            isSafeArea: false,
                                            color: Colors.red,
                                            text: 'clear'.tr,
                                            onPressed: () {
                                              controller.getGoalDetails(
                                                goalId: goal.id.toString(),
                                                isCancel: null,
                                                isTransfer: null,
                                                isDelete: true,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : Get.dialog(DeleteGoalDialog(goal: goal));
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
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 10.h),
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
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                      color: ThemeService.isDark.value
                                          ? AppColors.whiteColor2
                                          : AppColors.blackColor,
                                    ),
                              ),
                              Center(
                                child: SizedBox(
                                  height: 65,
                                  width: 65,
                                  child: CircularProgressIndicator(
                                    value: (double.parse(
                                            goal.achievementPercentage) /
                                        100),
                                    strokeWidth: 6,
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
                        SizedBox(height: 10.h),
                        Flexible(
                          child: Text(
                            goal.name,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  color: ThemeService.isDark.value
                                      ? AppColors.whiteColor2
                                      : AppColors.blackColor,
                                ),
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          '${'targetValue'.tr}: ${NumberFormat('#,###').format(double.parse(goal.targetValue))}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w400,
                                    color: ThemeService.isDark.value
                                        ? AppColors.whiteColor2
                                        : AppColors.blackColor,
                                  ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          '${'currentValue'.tr}: ${NumberFormat('#,###').format(double.parse(goal.currentValue))}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w400,
                                    color: ThemeService.isDark.value
                                        ? AppColors.whiteColor2
                                        : AppColors.blackColor,
                                  ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          showData(goal.dueDate),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w400,
                                    color: ThemeService.isDark.value
                                        ? AppColors.whiteColor2
                                        : AppColors.blackColor,
                                  ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: controller.currentTab.value == 0
                  ? controller.globalGoalsFilterList.toList().length
                  : controller.currentTab.value == 1
                      ? controller.privateGoalsFilterList.toList().length
                      : controller.archiveGoalsFilterList.toList().length,
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
