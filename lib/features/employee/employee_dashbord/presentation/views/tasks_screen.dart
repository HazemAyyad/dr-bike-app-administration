import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/custom_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/state_manager.dart';

import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/employee_dashbord_controller.dart';
import '../widgets/employee_dashbord_tasks.dart';

class TasksScreen extends GetView<EmployeeDashbordController> {
  const TasksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'tasks',
        action: false,
        dsibalBack: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppTabs(
              tabs: controller.tabs,
              currentTab: controller.currentTab,
              changeTab: controller.changeTab,
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          GetBuilder<EmployeeDashbordController>(
            builder: (controller) {
              if (controller.isLoading.value) {
                return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()));
              }
              if (controller.employeeData.value == null) {
                return const SliverFillRemaining(
                  child: Center(child: ShowNoData()),
                );
              }
              if (controller.currentTab.value == 0 &&
                  controller.employeeData.value!.tasks
                      .where((e) => e.status == 'ongoing')
                      .toList()
                      .isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: ShowNoData()),
                );
              }
              if (controller.currentTab.value == 1 &&
                  controller.employeeData.value!.tasks
                      .where((e) => e.status == 'completed')
                      .toList()
                      .isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: ShowNoData()),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final keys = controller.tasksData.keys
                        .where((e) => controller.currentTab.value == 0
                            ? controller.tasksData[e]!
                                .any((t) => t.status == 'ongoing')
                            : controller.tasksData[e]!
                                .any((t) => t.status == 'completed'))
                        .toList()
                      ..sort((a, b) => b.compareTo(a));

                    final monthKey = keys[index];
                    final tasks = controller.tasksData[monthKey]!
                        .where((t) => controller.currentTab.value == 0
                            ? t.status == 'ongoing'
                            : t.status == 'completed')
                        .toList();

                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    monthKey,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          color: AppColors.primaryColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15.sp,
                                        ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 5.h),
                              Container(
                                height: 1.h,
                                width: double.infinity,
                                color: AppColors.primaryColor,
                              ),
                              SizedBox(height: 10.h),
                              ...tasks
                                  .map((e) => EmployeeDashbordTasks(task: e)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  childCount: controller.tasksData.entries
                      .where(
                        (e) => e.value.any(
                          (t) => controller.currentTab.value == 0
                              ? t.status == 'ongoing'
                              : t.status == 'completed',
                        ),
                      )
                      .toList()
                      .length,
                ),
              );
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: 50.h)),
        ],
      ),
    );
  }
}
