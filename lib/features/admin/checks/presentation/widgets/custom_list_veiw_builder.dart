import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/checks_controller.dart';
import 'on_long_press.dart';
import 'view_checks_widget.dart';

class CustomListVeiwBuilder extends GetView<ChecksController> {
  const CustomListVeiwBuilder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChecksController>(
      builder: (controller) {
        if (controller.isLoading.value) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (controller.currentTab.value == 0) {
          if (controller.filteredInComingTasks.isEmpty &&
              !controller.isLoading.value) {
            return const SliverFillRemaining(
              hasScrollBody: false,
              child: ShowNoData(),
            );
          }
        }
        if (controller.currentTab.value == 1) {
          if (controller.filteredCashedToPersonTasks.isEmpty &&
              !controller.isLoading.value) {
            return const SliverFillRemaining(
              hasScrollBody: false,
              child: ShowNoData(),
            );
          }
        }
        if (controller.currentTab.value == 2) {
          if (controller.filteredArchiveTasks.isEmpty &&
              !controller.isLoading.value) {
            return const SliverFillRemaining(
              hasScrollBody: false,
              child: ShowNoData(),
            );
          }
        }
        return SliverList.builder(
          itemCount: controller.currentTab.value == 0
              ? controller.filteredInComingTasks.length
              : controller.currentTab.value == 1
                  ? controller.filteredCashedToPersonTasks.length
                  : controller.filteredArchiveTasks.length,
          itemBuilder: (context, section) {
            final monthReversed = controller.currentTab.value == 0
                ? controller.filteredInComingTasks.keys.toList()[section]
                : controller.currentTab.value == 1
                    ? controller.filteredCashedToPersonTasks.keys
                        .toList()[section]
                    : controller.filteredArchiveTasks.keys.toList()[section];

            final month = controller.currentTab.value == 0
                ? controller.filteredInComingTasks.keys
                    .toList()
                    .reversed
                    .toList()[section]
                : controller.currentTab.value == 1
                    ? controller.filteredCashedToPersonTasks.keys
                        .toList()
                        .reversed
                        .toList()[section]
                    : controller.filteredArchiveTasks.keys.toList()[section];

            final checks = controller.currentTab.value == 0
                ? controller.dateFilter.value
                    ? controller.filteredInComingTasks[month]!.toList().reversed
                    : controller.filteredInComingTasks[month]
                : controller.currentTab.value == 1
                    ? controller.dateFilter.value
                        ? controller.filteredCashedToPersonTasks[month]!
                            .toList()
                            .reversed
                        : controller.filteredCashedToPersonTasks[month]
                    : controller.dateFilter.value
                        ? controller.filteredArchiveTasks[month]!
                            .toList()
                            .reversed
                        : controller.filteredArchiveTasks[month];

            final monthTotal = controller.currentTab.value == 0
                ? controller.totalInComing[month]
                : controller.currentTab.value == 1
                    ? controller.totalCashedToPerson[month]
                    : controller.totalArchive[month] ?? 0.0;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // separator عنوان الشهر
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        controller.dateFilter.value ? monthReversed : month,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 15.sp,
                            ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15.w),
                        child: Text(
                          NumberFormat('#,###')
                              .format(double.parse(monthTotal.toString())),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium!
                              .copyWith(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 16.sp,
                              ),
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
                  // عرض العناصر
                  ...checks!.map(
                    (check) => GestureDetector(
                      onLongPress: () {
                        controller.getShowBoxes();
                        controller.getAllCustomersAndSellers();
                        Get.dialog(OnLongPress(check: check));
                      },
                      child: ViewChecksWidget(
                        type: controller.isInComing,
                        check: check,
                        currentTab: controller.currentTab.value,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
