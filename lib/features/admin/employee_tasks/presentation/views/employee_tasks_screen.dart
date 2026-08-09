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
          _EmployeeTaskAppBarTabs(controller: controller),
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

class _EmployeeTaskAppBarTabs extends StatelessWidget {
  const _EmployeeTaskAppBarTabs({required this.controller});

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
      () {
        controller.listEpoch.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < controller.tabs.length; i++)
              _EmployeeTaskAppBarTab(
                icon: _iconForIndex(i),
                label: controller.tabs[i].tr,
                selected: controller.currentTab.value == i,
                badge: controller.canReviewTasks && i == 1
                    ? controller.awaitingReviewTasksCount
                    : 0,
                onTap: () => controller.changeTab(i),
              ),
          ],
        );
      },
    );
  }
}

class _EmployeeTaskAppBarTab extends StatelessWidget {
  const _EmployeeTaskAppBarTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final int badge;
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
      child: IconButton(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(minWidth: 34.w, minHeight: 40.h),
        onPressed: onTap,
        icon: Container(
          width: 30.w,
          height: 30.w,
          decoration: BoxDecoration(
            color: selected ? AppColors.operationalPurple : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 18.sp, color: fg),
              if (badge > 0)
                PositionedDirectional(
                  top: -5.h,
                  end: -6.w,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    constraints:
                        BoxConstraints(minWidth: 16.w, minHeight: 16.w),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 1.2),
                    ),
                    child: Text(
                      badge > 99 ? '99+' : '$badge',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
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
