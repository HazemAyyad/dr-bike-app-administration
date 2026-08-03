import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../widgets/employee_tasks_fab_lens.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/employee_tasks_controller.dart';
import '../widgets/employee_tasks_list.dart';
import '../widgets/tasks_view_mode_bar.dart';
import '../../../../../core/widgets/app_pull_to_refresh.dart';

class EmployeeTasksScreen extends GetView<EmployeeTasksController> {
  const EmployeeTasksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'employeeTasks'.tr,
        fromDateController: controller.fromDateController,
        toDateController: controller.toDateController,
        employeeNameController: controller.employeeNameController,
        label: 'employeeTasksSearch',
        onPressedFilter: () {
          controller.filterEmployeeTasks();
          Get.back();
        },
        action: false,
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'employeeTasksSearch'.tr,
              onPressed: controller.toggleSearch,
              icon: Icon(
                controller.isSearchVisible.value
                    ? Icons.search_off_rounded
                    : Icons.search_rounded,
                color: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
              ),
            ),
          ),
          Obx(
            () => IconButton(
              tooltip: 'تصدير المهام المستقبلية',
              onPressed: controller.isExportingFutureTasks.value
                  ? null
                  : controller.exportFutureTasks,
              icon: controller.isExportingFutureTasks.value
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.file_download_outlined,
                      color: ThemeService.isDark.value
                          ? AppColors.primaryColor
                          : AppColors.secondaryColor,
                    ),
            ),
          ),
          if (controller.canClearAllTasks)
            IconButton(
              tooltip: 'تفريغ كل المهام',
              onPressed: controller.showClearAllTasksDialog,
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: Colors.red,
              ),
            ),
          SizedBox(width: 8.w),
        ],
      ),
      body: AppPullToRefresh(
        onRefresh: controller.pullToRefresh,
        child: CustomScrollView(
          controller: controller.scrollController,
          physics: kRefreshableScrollPhysics,
          slivers: [
            SliverToBoxAdapter(
              child: _EmployeeTaskIconTabs(controller: controller),
            ),
            GetBuilder<EmployeeTasksController>(
              id: 'searchBar',
              builder: (_) => SliverToBoxAdapter(
                child: Obx(
                  () => controller.isSearchVisible.value
                      ? Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 6.h,
                          ),
                          child: SearchBar(
                            controller: controller.employeeNameController,
                            shadowColor:
                                WidgetStateProperty.all(Colors.transparent),
                            leading: const Icon(Icons.search),
                            trailing: [
                              IconButton(
                                tooltip: 'cancel'.tr,
                                onPressed: controller.closeSearch,
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                            hintText: 'employeeTasksSearchHint'.tr,
                            backgroundColor: WidgetStateProperty.all(
                              ThemeService.isDark.value
                                  ? AppColors.customGreyColor
                                  : AppColors.customGreyColor7,
                            ),
                            onChanged: (_) => controller.filterEmployeeTasks(),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: TasksViewModeBar()),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
                child: Obx(() {
                  controller.listEpoch.value;
                  controller.tasksViewMode.value;
                  return Row(
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
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
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
                  );
                }),
              ),
            ),
            const EmployeeTasks(),
            SliverToBoxAdapter(child: SizedBox(height: 72.h)),
          ],
        ),
      ),
      floatingActionButton: const EmployeeTasksCreateFab(),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}

class _EmployeeTaskIconTabs extends StatelessWidget {
  const _EmployeeTaskIconTabs({required this.controller});

  final EmployeeTasksController controller;

  IconData _iconForIndex(int index) {
    if (index == controller.archiveTabIndex) {
      return Icons.archive_outlined;
    }
    if (index == controller.completedTabIndex) {
      return Icons.check_circle_outline_rounded;
    }
    if (controller.canReviewTasks && index == 1) {
      return Icons.rate_review_outlined;
    }
    return Icons.playlist_add_check_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        margin: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 4.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor
              : AppColors.whiteColor2,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            for (var i = 0; i < controller.tabs.length; i++)
              Expanded(
                child: _EmployeeTaskIconTab(
                  icon: _iconForIndex(i),
                  label: controller.tabs[i].tr,
                  selected: controller.currentTab.value == i,
                  onTap: () => controller.changeTab(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeTaskIconTab extends StatelessWidget {
  const _EmployeeTaskIconTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? Colors.white
        : ThemeService.isDark.value
            ? Colors.white70
            : AppColors.secondaryColor;
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(9.r),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 44.h,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            color: selected ? AppColors.operationalPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(9.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18.sp, color: fg),
              SizedBox(width: 4.w),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
