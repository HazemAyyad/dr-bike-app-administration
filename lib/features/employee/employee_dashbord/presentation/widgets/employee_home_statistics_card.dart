// بناء بطاقات الإحصائيات
import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../admin/admin_dashbord/presentation/widgets/stat_card.dart';
import '../controllers/employee_dashbord_controller.dart';

class EmployeeHomeStatisticsCard extends GetView<EmployeeDashbordController> {
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
        Obx(
          () {
            final hours = controller.elapsed.value.inHours;
            final minutes = controller.elapsed.value.inMinutes % 60;
            final seconds = controller.elapsed.value.inSeconds % 60;
            return controller.isStartWork
                ? Text(
                    '$seconds : $minutes : $hours',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: controller.isStartWork
                              ? Colors.green
                              : Colors.red,
                        ),
                  )
                : const SizedBox();
          },
        ),
        SizedBox(height: 10.h),
        Container(
          padding: const EdgeInsets.all(10),
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
                  GestureDetector(
                    onTap: () {
                      controller.downloadReport(
                        context: context,
                        customerId: '',
                        customerName: userName,
                      );
                    },
                    child: StatCard(
                      // show: true,
                      title: 'workingHours',
                      imageicon: AssetsManager.doneIcon,
                      value: controller.employeeData.value == null
                          ? '0'
                          : controller.employeeData.value!.totalWorkHours,
                      subtitle: controller.employeeData.value == null
                          ? '0'
                          : int.parse(controller
                                      .employeeData.value!.numberOfWorkHours) >
                                  10
                              ? 'hour'.tr
                              : 'hours'.tr,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  StatCard(
                    show: true,
                    title: 'hourlyRate',
                    imageicon: AssetsManager.moneyIcon,
                    value: controller.employeeData.value == null
                        ? '0'
                        : controller.employeeData.value!.hourWorkPrice
                            .toString(),
                    subtitle: 'currency',
                  ),
                  StatCard(
                    show: true,
                    title: 'advancesAndDebts',
                    imageicon: AssetsManager.cashIcon,
                    value: controller.employeeData.value == null
                        ? '0'
                        : controller.employeeData.value!.debts,
                    subtitle: 'currency',
                  ),
                  SizedBox(width: 8.w),
                  StatCard(
                    show: true,
                    title: 'remainingBalance',
                    imageicon: AssetsManager.cashIcon,
                    value: controller.employeeData.value == null
                        ? '0'
                        : controller.employeeData.value!.salary.toString(),
                    subtitle: 'currency',
                  ),
                  SizedBox(width: 8.w),
                  StatCard(
                    show: true,
                    title: 'points',
                    imageicon: AssetsManager.cashIcon4,
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
