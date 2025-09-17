import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/checks_controller.dart';
import 'on_long_press.dart';
import 'view_checks_widget.dart';

class CustomListVeiwBuilder extends GetView<ChecksController> {
  const CustomListVeiwBuilder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        if (controller.isLoading.value) {
          return const SliverFillRemaining(
            hasScrollBody: true,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (controller.currentTab.value == 0) {
          if (controller.inComingChecksList.value == null) {
            return const SliverFillRemaining(
              hasScrollBody: true,
              child: ShowNoData(),
            );
          }
        }
        if (controller.currentTab.value == 1) {
          if (controller.cashedToPerson.value == null) {
            return const SliverFillRemaining(
              hasScrollBody: true,
              child: ShowNoData(),
            );
          }
        }
        if (controller.currentTab.value == 2) {
          if (controller.archiveData.value == null) {
            return const SliverFillRemaining(
              hasScrollBody: true,
              child: ShowNoData(),
            );
          }
        }
        return SliverList.builder(
          itemCount: controller.currentTab.value == 0
              ? controller.inComingTasks.length
              : controller.currentTab.value == 1
                  ? controller.cashedToPersonTasks.length
                  : controller.archiveTasks.length,
          itemBuilder: (context, section) {
            final month = controller.currentTab.value == 0
                ? controller.inComingTasks.keys.toList()[section]
                : controller.currentTab.value == 1
                    ? controller.cashedToPersonTasks.keys.toList()[section]
                    : controller.archiveTasks.keys.toList()[section];

            final checks = controller.currentTab.value == 0
                ? controller.inComingTasks[month]
                : controller.currentTab.value == 1
                    ? controller.cashedToPersonTasks[month]
                    : controller.archiveTasks[month];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // separator عنوان الشهر
                  Row(
                    children: [
                      Text(
                        month.split('-').reversed.join(' - '),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
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
                  // عرض العناصر
                  ...checks!.map(
                    (check) => GestureDetector(
                      onLongPress: !controller.isInComing &&
                              controller.currentTab.value == 2
                          ? null
                          : () {
                              Get.dialog(OnLongPress(check: check));
                            },
                      child: ViewChecksWidget(
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
