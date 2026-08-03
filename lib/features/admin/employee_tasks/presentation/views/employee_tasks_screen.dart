import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/costom_dialog_filter.dart';
import '../widgets/employee_tasks_fab_lens.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
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
          IconButton(
            tooltip: 'filter'.tr,
            onPressed: () {
              showCustomDialog(
                context,
                fromDateController: controller.fromDateController,
                toDateController: controller.toDateController,
                employeeNameController: controller.employeeNameController,
                label: 'employeeTasksSearch',
                onPressed: () {
                  controller.filterEmployeeTasks();
                  Get.back();
                },
              );
            },
            icon: Icon(
              Icons.calendar_today_outlined,
              color: ThemeService.isDark.value
                  ? AppColors.primaryColor
                  : AppColors.secondaryColor,
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
              child: AppTabs(
                tabs: controller.tabs,
                currentTab: controller.currentTab,
                changeTab: controller.changeTab,
              ),
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
