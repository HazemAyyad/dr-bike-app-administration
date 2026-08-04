import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_floating_action_button.dart';

import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
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
        title: Text(
          userName.isEmpty ? 'welcome'.tr : '${'welcome'.tr} $userName',
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
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
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const CustomSearchBar(),
            SizedBox(height: 20.h),
            // بطاقات الإحصائيات
            const BuildStatisticsCards(),
            SizedBox(height: 20.h),
            // أزرار الوظائف
            GetBuilder<AdminDashboardController>(
              builder: (controller) => BuildActionButtons(
                buttons: controller.visibleDashboardButtons,
                badges:
                    controller.mainDashboardDataModel?.dashboardBadges ?? {},
              ),
            ),
            SizedBox(height: 70.h),
          ],
        ),
      ),
      floatingActionButton: Obx(
        () => CustomFloatingActionButton(
          isAddMenuOpen: controller.isAddMenuOpen,
          onTap: () => controller.toggleAddMenu(),
          opacityAnimation: controller.sizeAnimation,
          sizeAnimation: controller.opacityAnimation,
          addList: controller.visibleAdminAddList,
          useGrid: true,
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
                Flexible(
                  child: Obx(
                    () => ListView.separated(
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
