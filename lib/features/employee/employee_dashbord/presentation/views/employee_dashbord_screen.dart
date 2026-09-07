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
import '../widgets/impersonation_exit_button.dart';
import '../widgets/employee_salary_receipt_alert.dart';
import '../controllers/employee_salary_receipt_controller.dart';

class EmployeeDashbordScreen extends GetView<EmployeeDashbordController> {
  const EmployeeDashbordScreen({Key? key}) : super(key: key);

  @override
  EmployeeDashbordController get controller {
    EmployeeDashbordBinding.ensureSalaryReceiptController();
    if (!Get.isRegistered<EmployeeDashbordController>() &&
        !Get.isPrepared<EmployeeDashbordController>()) {
      EmployeeDashbordBinding().dependencies();
    }
    return Get.find<EmployeeDashbordController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(92.h),
        child: const _EmployeeHomeHeader(),
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
            if (Get.isRegistered<EmployeeSalaryReceiptController>()) {
              await Get.find<EmployeeSalaryReceiptController>().load();
            }
          },
          child: SingleChildScrollView(
            physics: kRefreshableScrollPhysics,
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 14.h),
                // بطاقات الإحصائيات
                const EmployeeHomeStatisticsCard(),
                SizedBox(height: 12.h),
                const EmployeeSalaryReceiptAlert(),
                SizedBox(height: 3.h),
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
                                      Row(children: [
                                        Text(
                                          'مهام اليوم',
                                          style: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w900,
                                            color: ThemeService.isDark.value
                                                ? Colors.white
                                                : AppColors.operationalNavy,
                                          ),
                                        ),
                                        SizedBox(width: 7.w),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 7.w, vertical: 2.h),
                                          decoration: const BoxDecoration(
                                            color: AppColors.operationalPurple,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                              '${dashboardTasks.length}',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10.sp,
                                                  fontWeight: FontWeight.w900)),
                                        ),
                                        const Spacer(),
                                        TextButton.icon(
                                          onPressed: () {
                                            if (Get.isRegistered<
                                                BottomNavBarController>()) {
                                              Get.find<BottomNavBarController>()
                                                  .changePage(1);
                                            }
                                          },
                                          icon: const Icon(
                                              Icons.chevron_left_rounded),
                                          label: const Text('عرض الكل'),
                                        ),
                                      ]),
                                      Container(
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(
                                          color: ThemeService.isDark.value
                                              ? AppColors.customGreyColor
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(14.r),
                                          border: Border.all(
                                            color:
                                                AppColors.operationalCardBorder,
                                          ),
                                        ),
                                        child: Column(
                                          children: dashboardTasks
                                              .take(4)
                                              .map((e) => EmployeeDashbordTasks(
                                                  task: e))
                                              .toList(),
                                        ),
                                      ),
                                      SizedBox(height: 12.h),
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
                          employeePurpleStyle: true,
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
          ? FloatingActionButtonLocation.endFloat
          : FloatingActionButtonLocation.startFloat,
    );
  }
}

class _EmployeeHomeHeader extends GetView<EmployeeDashbordController> {
  const _EmployeeHomeHeader();

  @override
  Widget build(BuildContext context) {
    final dark = ThemeService.isDark.value;
    return Material(
      color: dark ? AppColors.darkColor : AppColors.whiteColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(20.w, 7.h, 14.w, 7.h),
          child: Row(children: [
            Expanded(
              child: Text(
                userName.isEmpty ? 'مرحباً' : 'مرحباً، $userName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: dark ? Colors.white : AppColors.operationalNavy,
                ),
              ),
            ),
            const ImpersonationExitButton(),
            if (userType == 'employee') ...[
              if (Get.isRegistered<EmployeeNotificationBadgeController>())
                Obx(() {
                  final badge = Get.find<EmployeeNotificationBadgeController>();
                  return _HeaderAction(
                    icon: Icons.notifications_none_rounded,
                    label: 'التنبيهات',
                    badge: badge.unreadCount.value,
                    onTap: () async {
                      await Get.toNamed(AppRoutes.EMPLOYEENOTIFICATIONCENTER);
                      badge.refresh();
                    },
                  );
                })
              else
                _HeaderAction(
                  icon: Icons.notifications_none_rounded,
                  label: 'التنبيهات',
                  onTap: () =>
                      Get.toNamed(AppRoutes.EMPLOYEENOTIFICATIONCENTER),
                ),
              Obx(() => _HeaderAction(
                    icon: Icons.history_rounded,
                    label: 'سجل الدوام',
                    dotColor: controller.todayAttendanceLoading.value
                        ? null
                        : controller.isAttendanceInside
                            ? Colors.green
                            : controller.todayAttendance.value != null
                                ? AppColors.operationalPurple
                                : null,
                    onTap: controller.openMyAttendanceHistory,
                  )),
              _HeaderAction(
                icon: Icons.redeem_outlined,
                label: 'النقاط',
                onTap: () => Get.toNamed(AppRoutes.POINTSTABLE),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
    this.dotColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: SizedBox(
        width: 55.w,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            Icon(icon, color: AppColors.operationalPurple, size: 25.sp),
            if (badge > 0)
              PositionedDirectional(
                top: -7.h,
                end: -9.w,
                child: Container(
                  constraints: BoxConstraints(minWidth: 17.w, minHeight: 17.w),
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badge > 9 ? '9+' : '$badge',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            if (dotColor != null)
              PositionedDirectional(
                top: -2.h,
                end: -3.w,
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
          ]),
          SizedBox(height: 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: ThemeService.isDark.value
                    ? Colors.white70
                    : AppColors.operationalNavy,
                fontSize: 9.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _EmployeeSharedGoalsSection extends GetView<EmployeeDashbordController> {
  const _EmployeeSharedGoalsSection();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final goals = List<EmployeeSharedGoal>.from(
        controller.employeeData.value?.sharedGoals ?? const [],
      )..sort((a, b) => b.id.compareTo(a.id));
      if (goals.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الأهداف',
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
            height: 104.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: goals.length,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (_, index) => _EmployeeGoalCard(goal: goals[index]),
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
      width: 185.w,
      height: 94.h,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: .40)),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.track_changes_rounded, color: color, size: 24.sp),
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
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                SizedBox(height: 5.h),
                Row(children: [
                  Text(
                    '${achievement.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(width: 7.w),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: LinearProgressIndicator(
                        value: (achievement / 100).clamp(0.0, 1.0),
                        minHeight: 6.h,
                        color: color,
                        backgroundColor: color.withValues(alpha: .10),
                      ),
                    ),
                  ),
                ]),
                SizedBox(height: 2.h),
                Text(
                  goal.statusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _goalStatusColor(String statusColor) {
  switch (statusColor.toLowerCase()) {
    case 'red':
      return Colors.redAccent;
    case 'green':
      return Colors.green;
    case 'gold':
    case 'yellow':
      return const Color(0xFFD4A017);
    case 'blue':
      return Colors.blue;
    default:
      return AppColors.operationalPurple;
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
