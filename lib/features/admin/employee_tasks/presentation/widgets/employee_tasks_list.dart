import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/employee_tasks_controller.dart';

class EmployeeTasks extends StatelessWidget {
  const EmployeeTasks({Key? key, required this.controller}) : super(key: key);

  final EmployeeTasksController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme.bodyMedium!;
    return Obx(
      () {
        if (controller.isLoading.value) {
          return SliverToBoxAdapter(
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            ),
          );
        } else if (controller.orders.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 100.h,
                    color: AppColors.graywhiteColor,
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'noDebts'.tr,
                    style: theme.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.graywhiteColor,
                    ),
                  ),
                  SizedBox(height: 150.h),
                ],
              ),
            ),
          );
        }
        final grouped =
            groupBy(controller.orders, (Map v) => v['month'] as String);
        final months = grouped.keys.toList();
        return SliverList.builder(
          itemCount: months.length,
          itemBuilder: (context, index) {
            final month = months[index];
            final orders = grouped[month]!;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 5.h),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        month,
                        style: theme.copyWith(
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
                  ...orders.map(
                    (order) {
                      return EmployeeTasksLists(
                        controller: controller,
                        order: order,
                        index: index,
                      );
                    },
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

class EmployeeTasksLists extends StatelessWidget {
  const EmployeeTasksLists({
    Key? key,
    required this.controller,
    required this.order,
    required this.index,
  }) : super(key: key);

  final EmployeeTasksController controller;
  final Map<String, dynamic> order;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme.bodyMedium!;

    return Column(
      children: [
        SizedBox(height: index == 0 ? 5.h : 0.h),
        GestureDetector(
          onTap: () {
            // controller.getUserTransactionsData(
            //     debt.customerId.toString());
            // showUserTransactions(context, controller, debt);
          },
          child: Container(
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.whiteColor2,
              borderRadius: BorderRadius.circular(5.r),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5.r),
                    child: CachedNetworkImage(
                      imageUrl: order['image'],
                      placeholder: (context, url) => Center(
                        child: const CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                      fit: BoxFit.cover,
                      width: 65.w,
                      height: 65.h,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 15.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '${order['taskName']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.copyWith(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.customGreyColor5,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              '${order['endDate']}',
                              style: theme.copyWith(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w400,
                                color: AppColors.customGreyColor5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15.h),
                      Text(
                        '${order['employeeName']}',
                        style: theme.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.customGreyColor5,
                        ),
                      ),
                    ],
                  ),
                ),
                controller.currentTab.value == 2
                    ? SizedBox(height: 75.h, width: 90.w)
                    : Container(
                        width: 60.w,
                        height: 75.h,
                        decoration: BoxDecoration(
                          color: int.parse(order['time'] ?? 0) > 2
                              ? AppColors.customGreen1
                              : int.parse(order['time'] ?? 0) > 0
                                  ? AppColors.customOrange3
                                  : AppColors.redColor,
                          borderRadius: Get.locale!.languageCode == 'en'
                              ? BorderRadius.only(
                                  topRight: Radius.circular(4.r),
                                  bottomRight: Radius.circular(4.r),
                                )
                              : BorderRadius.only(
                                  topLeft: Radius.circular(4.r),
                                  bottomLeft: Radius.circular(4.r),
                                ),
                        ),
                        margin: Get.locale!.languageCode == 'en'
                            ? EdgeInsets.only(left: 30.w)
                            : EdgeInsets.only(right: 30.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              order['time'] ?? '0',
                              textAlign: TextAlign.center,
                              style: theme.copyWith(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 5.h),
                            Text(
                              int.parse(order['time']) > 10 ||
                                      int.parse(order['time']) < -10
                                  ? 'hour'.tr
                                  : 'hours'.tr,
                              style: theme.copyWith(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: index == controller.orders.length - 1 ? 60.h : 0.h,
        ),
      ],
    );
  }
}
