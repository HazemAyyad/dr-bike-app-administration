import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/widgets/app_pull_to_refresh.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/special_tasks_controller.dart';
import '../widgets/tasks_list.dart';

class SpecialTasksScreen extends GetView<SpecialTasksController> {
  const SpecialTasksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'privateTasks',
        fromDateController: controller.fromDateController,
        toDateController: controller.toDateController,
        onPressedFilter: () => controller.filterLists(true),
        action: false,
      ),
      body: AppPullToRefresh(
        onRefresh: controller.pullToRefresh,
        child: CustomScrollView(
          controller: controller.scrollController,
          physics: kRefreshableScrollPhysics,
          slivers: [
            SliverToBoxAdapter(
              child: _SpecialCompactTabs(controller: controller),
            ),
            const SliverToBoxAdapter(child: _SpecialTasksViewModeBar()),
            SliverToBoxAdapter(
              child: GetBuilder<SpecialTasksController>(
                id: 'specialPeriodBar',
                builder: (controller) {
                  return Obx(() {
                    controller.tasksViewMode.value;
                    return Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints:
                                BoxConstraints(minWidth: 36.w, minHeight: 36.w),
                            onPressed: () => controller.changePeriod(false),
                            icon: Icon(
                              Icons.chevron_left_rounded,
                              color: AppColors.operationalPurple,
                              size: 26.sp,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              controller.periodLabel,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: ThemeService.isDark.value
                                        ? AppColors.primaryColor
                                        : AppColors.operationalNavy,
                                  ),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints:
                                BoxConstraints(minWidth: 36.w, minHeight: 36.w),
                            onPressed: () => controller.changePeriod(true),
                            icon: Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.operationalPurple,
                              size: 26.sp,
                            ),
                          ),
                        ],
                      ),
                    );
                  });
                },
              ),
            ),
            const TasksList(),
            SliverToBoxAdapter(child: SizedBox(height: 72.h)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed(
            AppRoutes.CREATETASKSCREEN,
            arguments: {'title': 'addNewPravateTask', 'isEdit': false},
          );
        },
        backgroundColor: AppColors.secondaryColor,
        child: Icon(Icons.add, color: Colors.white, size: 28.sp),
      ),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}

class _SpecialCompactTabs extends StatelessWidget {
  const _SpecialCompactTabs({required this.controller});

  final SpecialTasksController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 4.h),
      child: Container(
        height: 38.h,
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor
              : AppColors.whiteColor2,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Obx(
          () => Row(
            children: List.generate(controller.tabs.length, (index) {
              final selected = controller.currentTab.value == index;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: InkWell(
                    onTap: () => controller.changeTab(index),
                    borderRadius: BorderRadius.circular(8.r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? ThemeService.isDark.value
                                ? AppColors.customGreyColor5
                                : AppColors.whiteColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        controller.tabs[index].tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              fontSize: 10.sp,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color: ThemeService.isDark.value
                                  ? Colors.white
                                  : AppColors.secondaryColor,
                            ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _SpecialTasksViewModeBar extends GetView<SpecialTasksController> {
  const _SpecialTasksViewModeBar();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SpecialTasksController>(
      id: 'specialViewMode',
      builder: (controller) {
        return Obx(() {
          final mode = controller.tasksViewMode.value;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            child: Row(
              children: [
                _chip(
                  label: 'tasksViewDaily'.tr,
                  selected: mode == SpecialTasksController.tasksViewDaily,
                  onTap: () => controller.setTasksViewMode(
                    SpecialTasksController.tasksViewDaily,
                  ),
                ),
                SizedBox(width: 6.w),
                _chip(
                  label: 'tasksViewWeekly'.tr,
                  selected: mode == SpecialTasksController.tasksViewWeekly,
                  onTap: () => controller.setTasksViewMode(
                    SpecialTasksController.tasksViewWeekly,
                  ),
                ),
                SizedBox(width: 6.w),
                _chip(
                  label: 'tasksViewMonthly'.tr,
                  selected: mode == SpecialTasksController.tasksViewMonthly,
                  onTap: () => controller.setTasksViewMode(
                    SpecialTasksController.tasksViewMonthly,
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 7.h),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                selected ? AppColors.operationalPurple : AppColors.whiteColor,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: selected
                  ? AppColors.operationalPurple
                  : AppColors.operationalCardBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.operationalNavy,
            ),
          ),
        ),
      ),
    );
  }
}
