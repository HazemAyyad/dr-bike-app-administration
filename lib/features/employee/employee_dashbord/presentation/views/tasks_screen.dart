import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/custom_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/theme_service.dart';
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
        controller: controller.scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: AppTabs(
              tabs: controller.tabs,
              currentTab: controller.currentTab,
              changeTab: controller.changeTab,
            ),
          ),
          GetBuilder<EmployeeDashbordController>(
            builder: (controller) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => controller.changeWeek(false),
                        icon: const Icon(
                          Icons.arrow_circle_right_outlined,
                          color: AppColors.primaryColor,
                          size: 35,
                        ),
                      ),
                      Text(
                        "من ${DateFormat('dd/M/yyyy').format(controller.startDate)} "
                        "الى ${DateFormat('dd/M/yyyy').format(controller.endDate)}",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: ThemeService.isDark.value
                                  ? AppColors.primaryColor
                                  : AppColors.secondaryColor,
                            ),
                      ),
                      IconButton(
                        onPressed: () => controller.changeWeek(true),
                        icon: const Icon(
                          Icons.arrow_circle_left_outlined,
                          color: AppColors.primaryColor,
                          size: 35,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          GetBuilder<EmployeeDashbordController>(
            builder: (controller) {
              if (controller.isLoading.value) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
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
                    final dateKey = controller.tasksDataFilter.keys
                        .toList()
                        .reversed
                        .toList()[index];
                    final tasks = controller.tasksDataFilter[dateKey] ?? [];

                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    DateFormat('EEEE, yyyy/MM/dd',
                                            Get.locale!.languageCode)
                                        .format(DateTime.parse(dateKey)),
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
                              tasks
                                      .where((e) =>
                                          controller.currentTab.value == 0
                                              ? e.status != 'completed'
                                              : e.status != 'ongoing')
                                      .isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'noData'.tr,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              color: AppColors.primaryColor,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15.sp,
                                            ),
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        SizedBox(height: 5.h),
                                        ...tasks
                                            .where((e) =>
                                                controller.currentTab.value == 0
                                                    ? e.status != 'completed'
                                                    : e.status != 'ongoing')
                                            .map((e) =>
                                                EmployeeDashbordTasks(task: e)),
                                      ],
                                    ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  childCount: controller.tasksDataFilter.length,
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
