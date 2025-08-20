// بناء بطاقات الإحصائيات
import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/utils/assets_manger.dart';
import '../../../../../../routes/app_routes.dart';
import '../controllers/dashboard_controller.dart';
import 'stat_card.dart';

class EmployeeHomeStatisticsCard extends GetView<DashboardController> {
  const EmployeeHomeStatisticsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: AppButton(
                text: 'startWork',
                onPressed: () {
                  Get.toNamed(AppRoutes.FULLSCREENQRSCANNER);
                },
                color: Colors.green,
                borderRadius: BorderRadius.all(Radius.circular(8.r)),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: AppButton(
                text: 'leaveWork',
                onPressed: () {
                  Get.toNamed(AppRoutes.FULLSCREENQRSCANNER);
                },
                color: Colors.red,
                borderRadius: BorderRadius.all(
                  Radius.circular(8.r),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9.r),
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : AppColors.whiteColor2,
          ),
          child: GetBuilder<DashboardController>(
            builder: (_) {
              return Column(
                children: [
                  StatCard(
                    title: 'workingHours',
                    imageicon: AssetsManger.cashIcon,
                    value: controller.userData.value == null
                        ? '0'
                        : controller
                            .userData.value!.user.employee.totalWorkHours,
                    subtitle: 'currency',
                  ),
                  SizedBox(width: 8.w),
                  StatCard(
                    show: true,
                    title: 'hourlyRate',
                    imageicon: AssetsManger.cashIcon,
                    value: controller.userData.value == null
                        ? '0'
                        : controller.userData.value!.user.employee.hourWorkPrice
                            .toString(),
                    subtitle: 'currency',
                  ),
                  StatCard(
                    show: true,
                    title: 'advancesAndDebts',
                    imageicon: AssetsManger.cashIcon,
                    value: controller.userData.value == null
                        ? '0'
                        : controller.userData.value!.user.employee.debts,
                    subtitle: 'currency',
                  ),
                  SizedBox(width: 8.w),
                  StatCard(
                    show: true,
                    title: 'remainingBalance',
                    imageicon: AssetsManger.cashIcon,
                    value: controller.userData.value == null
                        ? '0'
                        : controller.userData.value!.user.employee.salary
                            .toString(),
                    subtitle: 'currency',
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
