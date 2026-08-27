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
import '../../data/models/dashbord_employee_details_model.dart';
import '../controllers/employee_dashbord_controller.dart';
import '../binding/employee_dashbord_binding.dart';
import '../helpers/employee_task_visibility.dart';
import '../widgets/employee_dashbord_tasks.dart';
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
      body: Obx(() {
        if (userType == 'employee' &&
            controller.wifiPermissionsChecked.value &&
            !controller.wifiPermissionsReady.value) {
          return const _RequiredWifiPermissionsGate();
        }

        return AppPullToRefresh(
          onRefresh: () async {
            await controller.refreshWifiPresencePermissions(request: true);
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
                const _EmployeeSharedGoalsSection(),
                SizedBox(height: 12.h),
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
                                    final dashboardTasks =
                                        dashboardTasksForToday(
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
                                                        ThemeService
                                                                .isDark.value
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
                                      ...dashboardTasks.take(5).map((e) =>
                                          EmployeeDashbordTasks(task: e)),
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
                        // Employee reminders are delivered as push notifications only.
                        BuildActionButtons(
                          buttons: controller.buttons,
                          badges:
                              controller.employeeData.value?.dashboardBadges ??
                                  {},
                          employeePermissions: controller
                              .employeeData.value?.permissions
                              .map((e) => e.id)
                              .toList(),
                          onReorder: controller.reorderDashboardButton,
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 80.h),
              ],
            ),
          ),
        );
      }),
      floatingActionButton: const EmployeeFloatingActionButton(),
      floatingActionButtonLocation: Get.locale!.languageCode == 'ar'
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}

class _EmployeeSharedGoalsSection extends GetView<EmployeeDashbordController> {
  const _EmployeeSharedGoalsSection();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final goals = controller.employeeData.value?.sharedGoals ?? const [];
      if (goals.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'targetSection'.tr,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor5
                      : AppColors.operationalNavy,
                ),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 132.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: goals.length,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (context, index) =>
                  _EmployeeGoalCard(goal: goals[index]),
            ),
          ),
        ],
      );
    });
  }
}

class _EmployeeGoalCard extends StatelessWidget {
  const _EmployeeGoalCard({required this.goal});

  final EmployeeSharedGoal goal;

  @override
  Widget build(BuildContext context) {
    final achievement = double.tryParse(goal.achievementPercentage) ?? 0;
    final color = _goalStatusColor(goal.statusColor);
    return Container(
      width: 210.w,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 54.h,
                width: 54.h,
                child: CircularProgressIndicator(
                  value: (achievement / 100).clamp(0.0, 1.0),
                  strokeWidth: 6,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                '${achievement.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  goal.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                SizedBox(height: 5.h),
                Text(
                  goal.statusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                SizedBox(height: 3.h),
                Text(
                  '${goal.currentValue} / ${goal.targetedValue}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _goalStatusColor(String color) {
  switch (color) {
    case 'gold':
      return const Color(0xFFD4AF37);
    case 'green':
      return Colors.green;
    case 'blue':
      return AppColors.operationalPurple;
    case 'red':
    default:
      return Colors.redAccent;
  }
}

class _RequiredWifiPermissionsGate extends GetView<EmployeeDashbordController> {
  const _RequiredWifiPermissionsGate();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72.w,
                  height: 72.w,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AppColors.primaryColor,
                    size: 34.sp,
                  ),
                ),
                SizedBox(height: 18.h),
                Text(
                  'صلاحيات مطلوبة',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: ThemeService.isDark.value
                            ? Colors.white
                            : AppColors.operationalNavy,
                      ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'لازم تفعيل صلاحية الموقع والإشعارات حتى يتم تسجيل شبكة الواي فاي وتحديث حالة الدوام.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 13.sp,
                        height: 1.5,
                        color: ThemeService.isDark.value
                            ? AppColors.customGreyColor5
                            : AppColors.customGreyColor4,
                      ),
                ),
                SizedBox(height: 18.h),
                Obx(() {
                  final state = controller.wifiPermissionState.value;
                  return Column(
                    children: [
                      _PermissionRequirementRow(
                        icon: Icons.location_on_outlined,
                        title: 'الموقع',
                        ready: state?.locationGranted == true &&
                            state?.locationServiceEnabled == true,
                        detail: state?.locationServiceEnabled == false
                            ? 'شغّل الموقع GPS من اختصارات الجهاز'
                            : 'اسم شبكة الواي فاي يحتاج صلاحية الموقع',
                      ),
                      SizedBox(height: 8.h),
                      _PermissionRequirementRow(
                        icon: Icons.notifications_active_outlined,
                        title: 'الإشعارات',
                        ready: state?.notificationGranted == true,
                        detail: 'مطلوبة حتى تبقى خدمة التحديث شغالة بالخلفية',
                      ),
                    ],
                  );
                }),
                SizedBox(height: 22.h),
                Obx(() {
                  final busy = controller.wifiPermissionsBusy.value;
                  final state = controller.wifiPermissionState.value;
                  final needsSettings = state?.needsSettings ?? false;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: busy
                            ? null
                            : () => controller.refreshWifiPresencePermissions(
                                  request: true,
                                ),
                        icon: busy
                            ? SizedBox(
                                width: 18.sp,
                                height: 18.sp,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline_rounded),
                        label: Text(
                          busy ? 'جاري الفحص...' : 'فحص الصلاحيات',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      ),
                      if (needsSettings) ...[
                        SizedBox(height: 10.h),
                        OutlinedButton.icon(
                          onPressed: controller.openWifiPermissionSettings,
                          icon: const Icon(Icons.settings_rounded),
                          label: const Text('فتح إعدادات التطبيق'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                        ),
                      ],
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionRequirementRow extends StatelessWidget {
  const _PermissionRequirementRow({
    required this.icon,
    required this.title,
    required this.ready,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final bool ready;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final color = ready ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: ThemeService.isDark.value
                        ? Colors.white
                        : AppColors.operationalNavy,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor5
                        : AppColors.customGreyColor4,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            ready ? Icons.check_circle_rounded : Icons.error_rounded,
            color: color,
            size: 20.sp,
          ),
        ],
      ),
    );
  }
}
