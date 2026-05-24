import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
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
        onPressedFilter: () {
          controller.filterEmployeeTasks();
          Get.back();
        },
        action: false,
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
                      constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.w),
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
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
                      constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.w),
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
