import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
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
      body: CustomScrollView(
        controller: controller.scrollController,
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            flexibleSpace: AppTabs(
              tabs: controller.tabs,
              currentTab: controller.currentTab,
              changeTab: controller.changeTab,
            ),
          ),
          GetBuilder<SpecialTasksController>(
            builder: (controller) {
              if (controller.currentTab.value == 1) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
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
          const TasksList(),
          SliverToBoxAdapter(child: SizedBox(height: 40.h)),
        ],
      ),
      floatingActionButton: AddFloatingActionButton(
        onPressed: () {
          Get.toNamed(
            AppRoutes.CREATETASKSCREEN,
            arguments: {'title': 'addNewPravateTask', 'isEdit': false},
          );
        },
      ),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}
