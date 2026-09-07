import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_floating_action_button.dart';

import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/widgets/skeleton_loading.dart';
import '../../../../../routes/app_routes.dart';
import '../../../notifications/presentation/controllers/admin_notification_badge_controller.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../widgets/actions_buttons.dart';
import '../widgets/admin_statistics_cards.dart';

class AdminDashboardScreen extends GetView<AdminDashboardController> {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'welcome'.tr,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontSize: userName.isEmpty ? 18.sp : 11.sp,
                    fontWeight: FontWeight.w700,
                    color: userName.isEmpty ? null : AppColors.customGreyColor5,
                  ),
            ),
            if (userName.isNotEmpty)
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
          ],
        ),
        actions: [
          if (userType == 'admin')
            Obx(() {
              final c = Get.isRegistered<AdminNotificationBadgeController>()
                  ? Get.find<AdminNotificationBadgeController>()
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
                              await Get.toNamed(AppRoutes.NOTIFICATIONCENTER);
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
          if (userType == 'admin')
            ClipOval(
              child: Container(
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor
                    : AppColors.whiteColor2,
                child: IconButton(
                  tooltip: 'customizeDashboard'.tr,
                  highlightColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  icon: Icon(
                    Icons.tune_rounded,
                    color: AppColors.primaryColor,
                    size: 24.sp,
                  ),
                  onPressed: () => _showCustomizeDashboardDialog(context),
                ),
              ),
            ),
          if (userType == 'admin') SizedBox(width: 8.w),
          ClipOval(
            child: Container(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.whiteColor2,
              child: IconButton(
                highlightColor: Colors.transparent,
                focusColor: Colors.transparent,
                icon: Icon(
                  Icons.history_rounded,
                  color: AppColors.primaryColor,
                  size: 25.sp,
                ),
                onPressed: () {
                  controller.getLogs();
                  Get.toNamed(AppRoutes.ADMINACTIVTILOGSCREEN);
                },
              ),
            ),
          ),
          SizedBox(width: 10.w),
        ],
      ),
      body: Obx(
        () => controller.isDashboardPreparing.value
            ? const _AdminDashboardSkeleton()
            : RefreshIndicator(
                onRefresh: controller.refreshDashboard,
                color: AppColors.primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // const CustomSearchBar(),
                      SizedBox(height: 12.h),
                      // بطاقات الإحصائيات
                      const BuildStatisticsCards(),
                      SizedBox(height: 14.h),
                      GetBuilder<AdminDashboardController>(
                        builder: (controller) {
                          final buttons = controller.visibleDashboardButtons;
                          final preferredQuickCount =
                              controller.dashboardQuickAccessCount.value;
                          final quickCount =
                              buttons.length > preferredQuickCount
                                  ? preferredQuickCount
                                  : buttons.length;
                          final quick = buttons.take(quickCount).toList();
                          final remaining = buttons.skip(quickCount).toList();
                          final badges = controller
                                  .mainDashboardDataModel?.dashboardBadges ??
                              {};
                          return Column(
                            children: [
                              BuildActionButtons(
                                buttons: quick,
                                badges: badges,
                                onReorder: controller.reorderDashboardButton,
                                employeePurpleStyle: true,
                                sectionTitle: 'الوصول السريع',
                                sectionSubtitle: 'اضغط مطولاً لتغيير الترتيب',
                                accentColor: const Color(0xFFF28C28),
                                reorderMode:
                                    controller.isDashboardReorderMode.value,
                                onReorderStarted:
                                    controller.startDashboardReorder,
                                onReorderFinished:
                                    controller.finishDashboardReorder,
                              ),
                              if (remaining.isNotEmpty) ...[
                                SizedBox(height: 16.h),
                                BuildActionButtons(
                                  buttons: remaining,
                                  badges: badges,
                                  onReorder: controller.reorderDashboardButton,
                                  employeePurpleStyle: true,
                                  sectionTitle: 'كل الأقسام',
                                  sectionSubtitle: 'الأقسام المتاحة للأدمن',
                                  reorderMode:
                                      controller.isDashboardReorderMode.value,
                                  onReorderStarted:
                                      controller.startDashboardReorder,
                                  onReorderFinished:
                                      controller.finishDashboardReorder,
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 70.h),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: Obx(
        () => controller.isDashboardPreparing.value
            ? const SizedBox.shrink()
            : CustomFloatingActionButton(
                isAddMenuOpen: controller.isAddMenuOpen,
                onTap: () => controller.toggleAddMenu(),
                opacityAnimation: controller.sizeAnimation,
                sizeAnimation: controller.opacityAnimation,
                addList: controller.visibleAdminAddList,
                useGrid: true,
                backgroundColor: AppColors.operationalPurple,
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showCustomizeDashboardDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 24.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 520.w, maxHeight: 620.h),
          child: Padding(
            padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 12.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: AppColors.primaryColor,
                      size: 22.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'customizeDashboard'.tr,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w800,
                              color: ThemeService.isDark.value
                                  ? AppColors.customGreyColor6
                                  : AppColors.secondaryColor,
                            ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                GetBuilder<AdminDashboardController>(
                  builder: (controller) => Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: AppColors.operationalPurple.withValues(alpha: .06),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'عدد أقسام الوصول السريع',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'اختر عدد البطاقات التي تظهر في الأعلى',
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  color: AppColors.customGreyColor5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: controller
                                      .dashboardQuickAccessCount.value <=
                                  3
                              ? null
                              : () => controller.setDashboardQuickAccessCount(
                                    controller.dashboardQuickAccessCount.value -
                                        1,
                                  ),
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                        ),
                        Container(
                          constraints: BoxConstraints(minWidth: 34.w),
                          child: Text(
                            '${controller.dashboardQuickAccessCount.value}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.operationalPurple,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: controller
                                      .dashboardQuickAccessCount.value >=
                                  controller.visibleDashboardButtons.length
                              ? null
                              : () => controller.setDashboardQuickAccessCount(
                                    controller.dashboardQuickAccessCount.value +
                                        1,
                                  ),
                          icon: const Icon(Icons.add_circle_outline_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Flexible(
                  child: GetBuilder<AdminDashboardController>(
                    builder: (controller) => ListView.separated(
                      shrinkWrap: true,
                      itemCount: controller.buttons.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: ThemeService.isDark.value
                            ? AppColors.customGreyColor
                            : AppColors.customGreyColor3,
                      ),
                      itemBuilder: (context, index) {
                        final button = controller.buttons[index];
                        final isVisible =
                            !controller.isDashboardButtonHidden(button);
                        return SwitchListTile.adaptive(
                          value: isVisible,
                          onChanged: controller.isUiPreferencesSaving.value
                              ? null
                              : (value) => controller.setDashboardButtonVisible(
                                    button,
                                    value,
                                  ),
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.primaryColor,
                          title: Text(
                            (button['title']?.toString() ?? '').tr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          controller.resetDashboardButtonsVisibility(),
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: Text('resetDashboardSections'.tr),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: Get.back,
                      child: Text('close'.tr),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminDashboardSkeleton extends StatelessWidget {
  const _AdminDashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 80.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBlock(width: double.infinity, height: 66.h, radius: 12),
          SizedBox(height: 14.h),
          SkeletonBlock(width: 118.w, height: 22.h, radius: 6),
          SizedBox(height: 8.h),
          SkeletonBlock(width: double.infinity, height: 82.h, radius: 12),
          SizedBox(height: 20.h),
          SkeletonBlock(width: 145.w, height: 24.h, radius: 6),
          SizedBox(height: 5.h),
          SkeletonBlock(width: 172.w, height: 11.h, radius: 5),
          SizedBox(height: 10.h),
          const _DashboardGridSkeleton(colorHint: Color(0xFFF28C28)),
          SizedBox(height: 22.h),
          SkeletonBlock(width: 112.w, height: 24.h, radius: 6),
          SizedBox(height: 5.h),
          SkeletonBlock(width: 155.w, height: 11.h, radius: 5),
          SizedBox(height: 10.h),
          const _DashboardGridSkeleton(),
        ],
      ),
    );
  }
}

class _DashboardGridSkeleton extends StatelessWidget {
  const _DashboardGridSkeleton({this.colorHint});

  final Color? colorHint;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.25.h,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 7.h,
      ),
      itemBuilder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          const SkeletonBlock(
              width: double.infinity, height: double.infinity, radius: 10),
          if (colorHint != null)
            Container(
              width: 24.r,
              height: 24.r,
              decoration: BoxDecoration(
                color: colorHint!.withValues(alpha: .10),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
