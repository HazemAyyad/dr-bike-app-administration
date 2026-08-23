import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/showtime.dart';
import 'package:doctorbike/features/admin/goals_section/data/models/goals_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

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
              mainAxisExtent: 168.h,
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
                final achievement =
                    double.tryParse(goal.achievementPercentage) ?? 0;
                final progressColor = _goalStatusColor(goal.statusMeta.color);
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
                  child: _GoalSummaryCard(
                    goal: goal,
                    achievement: achievement,
                    progressColor: progressColor,
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

class _GoalSummaryCard extends StatelessWidget {
  const _GoalSummaryCard({
    required this.goal,
    required this.achievement,
    required this.progressColor,
  });

  final GoalsModel goal;
  final double achievement;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    final current = double.tryParse(goal.currentValue) ?? 0;
    final target = double.tryParse(goal.targetValue) ?? 0;
    final progress = (achievement / 100).clamp(0.0, 1.0);
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: progressColor.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                        color: ThemeService.isDark.value
                            ? Colors.white
                            : AppColors.operationalNavy,
                      ),
                ),
              ),
              SizedBox(width: 7.w),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 48.h,
                    width: 48.h,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  Text(
                    '${achievement.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w900,
                          color: progressColor,
                        ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 7.h),
          Wrap(
            spacing: 5.w,
            runSpacing: 5.h,
            children: [
              _GoalPill(
                label: goal.statusMeta.label.isEmpty
                    ? _goalStatusLabel(achievement)
                    : goal.statusMeta.label,
                color: progressColor,
              ),
              if (goal.scope.isNotEmpty)
                _GoalPill(
                  label: goal.scope.tr,
                  color: AppColors.operationalPurple,
                  soft: true,
                ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  title: 'currentValue',
                  value: _compactNumber(current),
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _MiniMetric(
                  title: 'targetValue',
                  value: _compactNumber(target),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 14.sp,
                color: AppColors.customGreyColor5,
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  showData(goal.dueDate.toIso8601String()),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontSize: 10.sp,
                        color: AppColors.customGreyColor5,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalPill extends StatelessWidget {
  const _GoalPill({
    required this.label,
    required this.color,
    this.soft = false,
  });

  final String label;
  final Color color;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: soft ? 0.08 : 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              fontSize: 9.sp,
              color: color,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.operationalSurface,
        borderRadius: BorderRadius.circular(7.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontSize: 9.sp,
                  color: AppColors.customGreyColor5,
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
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

Color _goalStatusColor(String color) {
  switch (color) {
    case 'gold':
      return const Color(0xFFD4AF37);
    case 'green':
      return Colors.green;
    case 'blue':
      return AppColors.operationalPurple;
    case 'red':
    default:
      return Colors.redAccent;
  }
}

String _goalStatusLabel(double achievement) {
  if (achievement >= 100) return 'محقق';
  if (achievement >= 80) return 'ممتاز';
  if (achievement >= 50) return 'قيد التقدم';
  return 'متأخر';
}

String _compactNumber(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}
