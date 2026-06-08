import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/custom_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/widgets/app_pull_to_refresh.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/employee_dashbord_controller.dart';
import '../helpers/employee_task_visibility.dart';
import '../widgets/employee_operational_task_card.dart';
import '../widgets/employee_tasks_view_mode_bar.dart';
import '../widgets/impersonation_exit_button.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({Key? key}) : super(key: key);

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Get.find<EmployeeDashbordController>().prepareTasksScreenIfNeeded();
    });
  }

  EmployeeDashbordController get controller =>
      Get.find<EmployeeDashbordController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme.bodyMedium!;
    return Scaffold(
      backgroundColor: AppColors.operationalSurface,
      appBar: CustomAppBar(
        title: 'tasks',
        action: false,
        dsibalBack: true,
        actions: const [ImpersonationExitButton()],
      ),
      body: AppPullToRefresh(
        onRefresh: () async {
          await controller.getEmployeeData(scrollToTodayb: true);
        },
        child: CustomScrollView(
          physics: kRefreshableScrollPhysics,
          controller: controller.scrollController,
          slivers: [
          SliverToBoxAdapter(
            child: AppTabs(
              tabs: controller.tabs,
              currentTab: controller.currentTab,
              changeTab: controller.changeTab,
            ),
          ),
          const SliverToBoxAdapter(child: EmployeeTasksViewModeBar()),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              child: Obx(() {
                controller.tasksViewMode.value;
                controller.tasksFilterEpoch.value;
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
                        style: theme.copyWith(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: ThemeService.isDark.value
                              ? AppColors.operationalPurple
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
          Obx(() {
            controller.tasksFilterEpoch.value;
            if (controller.isLoading.value) {
              return const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.operationalPurple,
                  ),
                ),
              );
            }
            if (controller.employeeData.value == null) {
              return const SliverFillRemaining(child: Center(child: ShowNoData()));
            }

            final filtered = controller.tasksDataFilter;
            if (filtered.isEmpty) {
              return const SliverFillRemaining(child: Center(child: ShowNoData()));
            }

            final keys = controller.orderedDisplayKeys(filtered.keys.toList());
            final isDaily =
                controller.tasksViewMode.value ==
                    EmployeeDashbordController.tasksViewDaily;
            final todayKey = EmployeeDashbordController.dateKeyFrom(DateTime.now());

            return SliverList.builder(
              itemCount: keys.length,
              itemBuilder: (context, index) {
                final dateKey = keys[index];
                final tasks = (filtered[dateKey] ?? [])
                    .where((e) => controller.currentTab.value == 0
                        ? isEmployeeTaskActive(e.status)
                        : e.status == 'completed')
                    .toList();

                final isToday = dateKey == todayKey;
                if (tasks.isEmpty &&
                    !isDaily &&
                    !isToday) {
                  return const SizedBox.shrink();
                }

                final date = DateTime.parse(dateKey);

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                            0, index == 0 ? 4.h : 10.h, 0, 4.h),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                DateFormat('EEEE, d/M/yyyy',
                                        Get.locale?.languageCode)
                                    .format(date),
                                style: theme.copyWith(
                                  color: isToday
                                      ? AppColors.operationalPurple
                                      : AppColors.operationalNavy,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                            if (isToday)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: AppColors.operationalPurple
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  'today'.tr,
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.operationalPurple,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        height: 1,
                        color:
                            AppColors.operationalPurple.withValues(alpha: 0.35),
                      ),
                      SizedBox(height: 6.h),
                      if (tasks.isEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: Text(
                            'noTasksThisDay'.tr,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.customGreyColor5,
                            ),
                          ),
                        )
                      else
                        ...tasks.map(
                          (t) => EmployeeOperationalTaskCard(
                            task: t,
                            showCheckbox: false,
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          }),
          SliverToBoxAdapter(child: SizedBox(height: 72.h)),
        ],
        ),
      ),
    );
  }
}
