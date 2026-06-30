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
            BuildActionButtons(buttons: controller.buttons),
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
}
