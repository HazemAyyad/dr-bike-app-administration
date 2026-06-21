// بناء بطاقات الإحصائيات
import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/dashbord_employee_details_model.dart';
import '../controllers/employee_dashbord_controller.dart';
import 'employee_compact_stat_tile.dart';

class EmployeeHomeStatisticsCard extends GetView<EmployeeDashbordController> {
  const EmployeeHomeStatisticsCard({Key? key}) : super(key: key);

  static String _hoursSubtitle(String raw) {
    final n = int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return n > 10 ? 'hour'.tr : 'hours'.tr;
  }

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
            final day = controller.todayAttendance.value;
            final inside = controller.isStartWork ||
                day?.currentlyIn == true;
            if (!inside) {
              return const SizedBox();
            }

            Duration elapsed = controller.elapsed.value;
            if (!controller.isStartWork) {
              final checkIn = day?.firstCheckIn ?? day?.firstCheckInServer;
              if (checkIn != null) {
                elapsed = DateTime.now().difference(checkIn);
              }
            }

            final hours = elapsed.inHours;
            final minutes = elapsed.inMinutes % 60;
            final seconds = elapsed.inSeconds % 60;
            return Text(
              '$seconds : $minutes : $hours',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
            );
          },
        ),
        SizedBox(height: 10.h),
        Obx(() {
          final summary =
              controller.employeeData.value?.todayTasksSummary ??
              const TodayTasksSummary();
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: controller.openTasksTab,
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              color: AppColors.operationalPurple.withValues(alpha: 0.08),
              border: Border.all(
                color: AppColors.operationalPurple.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'todayTasksProgress'.tr,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.operationalNavy,
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Text(
                      '${summary.progressPercent}%',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.operationalPurple,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'todayTasksProgressSubtitle'.trParams({
                              'done': '${summary.completed}',
                              'total': '${summary.total}',
                            }),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.customGreyColor5,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4.r),
                            child: LinearProgressIndicator(
                              value: summary.total > 0
                                  ? summary.progressPercent / 100
                                  : 0,
                              minHeight: 6.h,
                              color: AppColors.operationalPurple,
                              backgroundColor: AppColors.operationalSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
        }),
        SizedBox(height: 8.h),
        GetBuilder<EmployeeDashbordController>(
          builder: (c) {
            final data = c.employeeData.value;
            final tiles = <Widget>[
              EmployeeCompactStatTile(
                title: 'workingHours',
                iconAsset: AssetsManager.doneIcon,
                value: data?.totalWorkHours ?? '0',
                subtitle: data == null
                    ? null
                    : _hoursSubtitle(data.numberOfWorkHours),
                formatNumber: false,
              ),
              EmployeeCompactStatTile(
                title: 'hourlyRate',
                iconAsset: AssetsManager.moneyIcon,
                value: data?.hourWorkPrice.toString() ?? '0',
                subtitle: 'currency',
              ),
              EmployeeCompactStatTile(
                title: 'advancesAndDebts',
                iconAsset: AssetsManager.cashIcon,
                value: data?.debts ?? '0',
                subtitle: 'currency',
              ),
              EmployeeCompactStatTile(
                title: 'remainingBalance',
                iconAsset: AssetsManager.cashIcon,
                value: data?.salary.toString() ?? '0',
                subtitle: 'currency',
              ),
              EmployeeCompactStatTile(
                title: 'points',
                iconAsset: AssetsManager.cashIcon4,
                value: data?.points ?? '0',
                subtitle: 'point',
                formatNumber: false,
              ),
            ];
            return Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9.r),
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor
                    : AppColors.whiteColor2,
              ),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 6.h,
                crossAxisSpacing: 6.w,
                childAspectRatio: 2.35,
                children: tiles,
              ),
            );
          },
        ),
      ],
    );
  }
}
