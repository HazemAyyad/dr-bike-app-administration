import 'package:doctorbike/core/services/initial_bindings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/show_no_data.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/widgets/app_pull_to_refresh.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../features/bottom_nav_bar/controllers/bottom_nav_bar_controller.dart';
import '../../../../../routes/app_routes.dart';
import '../../../notifications/presentation/controllers/employee_notification_badge_controller.dart';
import '../../../../admin/admin_dashbord/presentation/widgets/actions_buttons.dart';
import '../controllers/employee_dashbord_controller.dart';
import '../binding/employee_dashbord_binding.dart';
import '../helpers/employee_task_visibility.dart';
import '../widgets/employee_dashbord_tasks.dart';
import '../widgets/employee_dashboard_reminders.dart';
import '../widgets/employee_floating_action_button.dart';
import '../widgets/employee_home_statistics_card.dart';
import '../widgets/employee_attendance_app_bar_button.dart';
import '../widgets/impersonation_exit_button.dart';

class EmployeeDashbordScreen extends GetView<EmployeeDashbordController> {
  const EmployeeDashbordScreen({Key? key}) : super(key: key);

  @override
  EmployeeDashbordController get controller {
    if (!Get.isRegistered<EmployeeDashbordController>() &&
        !Get.isPrepared<EmployeeDashbordController>()) {
      EmployeeDashbordBinding().dependencies();
    }
    return Get.find<EmployeeDashbordController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          userName.isEmpty ? 'welcome'.tr : '${'welcome'.tr}  $userName',
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
        ),
        actions: [
          const ImpersonationExitButton(),
          if (userType == 'employee') ...[
            const EmployeeAttendanceAppBarButton(),
            Obx(() {
              final c = Get.isRegistered<EmployeeNotificationBadgeController>()
                  ? Get.find<EmployeeNotificationBadgeController>()
                  : null;
              final n = c?.unreadCount.value ?? 0;
              return Padding(
                padding: EdgeInsets.only(right: 4.w),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      ClipOval(
                        child: Material(
                          color: ThemeService.isDark.value
                              ? AppColors.customGreyColor
                              : AppColors.whiteColor2,
                          child: InkWell(
                            onTap: () async {
                              await Get.toNamed(
                                AppRoutes.EMPLOYEENOTIFICATIONCENTER,
                              );
                              c?.refresh();
                            },
                            customBorder: const CircleBorder(),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: Icon(
                                Icons.notifications_none_rounded,
                                color: AppColors.primaryColor,
                                size: 25.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (n > 0)
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(minWidth: 18),
                            child: Text(
                              n > 99 ? '99+' : '$n',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
      body: AppPullToRefresh(
        onRefresh: () async {
          await controller.getEmployeeData(scrollToTodayb: false);
        },
        child: SingleChildScrollView(
          physics: kRefreshableScrollPhysics,
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.h),
              // بطاقات الإحصائيات
              const EmployeeHomeStatisticsCard(),
              SizedBox(height: 15.h),
              // أزرار الوظائف
              Obx(
                () {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (controller.employeeData.value == null) {
                    return const ShowNoData();
                  }
                  return Column(
                    children: [
                      Obx(
                        () {
                          if (controller.employeeData.value != null) {
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'tasks'.tr,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            fontSize: 17.sp,
                                            fontWeight: FontWeight.w700,
                                            color: ThemeService.isDark.value
                                                ? AppColors.customGreyColor5
                                                : AppColors.operationalNavy,
                                          ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                ...() {
                                  final dashboardTasks = dashboardTasksForToday(
                                    controller.employeeData.value!.tasks,
                                    weeklyDaysOff: controller
                                        .employeeData.value!.weeklyDaysOff,
                                  );
                                  if (dashboardTasks.isEmpty) {
                                    return [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'لا يوجد مهمات'.tr,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .copyWith(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w400,
                                                  color:
                                                      ThemeService.isDark.value
                                                          ? AppColors
                                                              .customGreyColor7
                                                          : AppColors
                                                              .customGreyColor4,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ];
                                  }
                                  return [
                                    ...dashboardTasks.take(5).map(
                                        (e) => EmployeeDashbordTasks(task: e)),
                                    if (dashboardTasks.length > 5)
                                      Padding(
                                        padding: EdgeInsets.only(top: 8.h),
                                        child: Align(
                                          alignment:
                                              AlignmentDirectional.centerEnd,
                                          child: TextButton(
                                            onPressed: () {
                                              if (Get.isRegistered<
                                                  BottomNavBarController>()) {
                                                Get.find<
                                                        BottomNavBarController>()
                                                    .changePage(1);
                                              }
                                            },
                                            child: Text(
                                              'showMoreTasks'.tr,
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primaryColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ];
                                }(),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const EmployeeDashboardReminders(),
                      BuildActionButtons(
                        buttons: controller.buttons,
                        badges:
                            controller.employeeData.value?.dashboardBadges ??
                                {},
                        employeePermissions: controller
                            .employeeData.value?.permissions
                            .map((e) => e.id)
                            .toList(),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 80.h),
            ],
          ),
        ),
      ),
      floatingActionButton: const EmployeeFloatingActionButton(),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}
