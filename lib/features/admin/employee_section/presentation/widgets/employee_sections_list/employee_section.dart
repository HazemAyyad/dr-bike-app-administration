import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/employee_section_controller.dart';
import 'entitlements_list.dart';
import 'employee_list.dart';
import 'loans_list.dart';
import 'work_hours_list.dart';

class EmployeeSection extends StatelessWidget {
  const EmployeeSection({Key? key, required this.controller}) : super(key: key);

  final EmployeeSectionController controller;

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
        } else if (controller.employeeList.isEmpty) {
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
            groupBy(controller.employeeList, (Map v) => v['warkDay'] as String);
        final filter = grouped.keys.toList();
        return SliverList.builder(
          itemCount: filter.length,
          itemBuilder: (context, index) {
            final days = filter[index];
            final employeeList = grouped[days]!;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 5.h),
              child: Column(
                children: [
                  controller.currentTab.value == 1
                      ? Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  days,
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
                          ],
                        )
                      : SizedBox.shrink(),
                  SizedBox(height: 10.h),
                  ...employeeList.map(
                    (employee) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 10.h),
                        decoration: BoxDecoration(
                          color: ThemeService.isDark.value
                              ? AppColors.customGreyColor4
                              : AppColors.whiteColor2,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: controller.currentTab.value == 0
                            ? EmployeeList(employee: employee)
                            : controller.currentTab.value == 1
                                ? WorkHoursList(employee: employee)
                                : controller.currentTab.value == 2
                                    ? EntitlementsList(employee: employee)
                                    : controller.currentTab.value == 3
                                        ? LoansList(
                                            employee: employee,
                                            isOvertime: false,
                                          )
                                        : LoansList(
                                            employee: employee,
                                            isOvertime: true,
                                          ),
                      );
                    },
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}
