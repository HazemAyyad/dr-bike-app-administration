// بناء بطاقات الإحصائيات
import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../admin/--/presentation/admin_dashbord/widgets/stat_card.dart';
import '../controllers/employee_dashbord_controller.dart';

class EmployeeHomeStatisticsCard extends StatelessWidget {
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
          child: GetBuilder<EmployeeDashbordController>(
            builder: (controller) {
              return Column(
                children: [
                  StatCard(
                    title: 'workingHours',
                    imageicon: AssetsManger.cashIcon,
                    value: controller.employeeData.value == null
                        ? '0'
                        : controller.employeeData.value!.numberOfWorkHours,
                    subtitle: controller.employeeData.value == null
                        ? '0'
                        : int.parse(controller
                                    .employeeData.value!.numberOfWorkHours) >
                                10
                            ? 'hour'.tr
                            : 'hours'.tr,
                  ),
                  SizedBox(width: 8.w),
                  StatCard(
                    show: true,
                    title: 'hourlyRate',
                    imageicon: AssetsManger.cashIcon,
                    value: controller.employeeData.value == null
                        ? '0'
                        : controller.employeeData.value!.hourWorkPrice
                            .toString(),
                    subtitle: 'currency',
                  ),
                  StatCard(
                    show: true,
                    title: 'advancesAndDebts',
                    imageicon: AssetsManger.cashIcon,
                    value: controller.employeeData.value == null
                        ? '0'
                        : controller.employeeData.value!.debts,
                    subtitle: 'currency',
                  ),
                  SizedBox(width: 8.w),
                  StatCard(
                    show: true,
                    title: 'remainingBalance',
                    imageicon: AssetsManger.cashIcon,
                    value: controller.employeeData.value == null
                        ? '0'
                        : controller.employeeData.value!.salary.toString(),
                    subtitle: 'currency',
                  ),
                  SizedBox(width: 8.w),
                  StatCard(
                    show: true,
                    title: 'points',
                    imageicon: AssetsManger.cashIcon,
                    value: controller.employeeData.value == null
                        ? '0'
                        : controller.employeeData.value!.points.toString(),
                    subtitle: 'point',
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
