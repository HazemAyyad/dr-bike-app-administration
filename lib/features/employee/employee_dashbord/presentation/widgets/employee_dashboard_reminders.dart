import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../employee_reminders/data/employee_reminder_models.dart';
import '../controllers/employee_dashbord_controller.dart';

const Color _employeeAlertColor = Color(0xff0f766e);

class EmployeeDashboardReminders extends GetView<EmployeeDashbordController> {
  const EmployeeDashboardReminders({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.remindersLoading.value &&
          controller.dashboardReminders.isEmpty) {
        return Padding(
          padding: EdgeInsets.only(top: 12.h),
          child: const Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.dashboardReminders.isEmpty) {
        return const SizedBox.shrink();
      }

      final titleStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor5
                : AppColors.operationalNavy,
          );

      return Padding(
        padding: EdgeInsets.only(top: 14.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('employeeReminders'.tr, style: titleStyle),
                ),
                TextButton(
                  onPressed: () =>
                      Get.toNamed(AppRoutes.MYEMPLOYEEREMINDERSSCREEN),
                  child: Text('showAll'.tr),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            ...controller.dashboardReminders.map(
              (item) => _DashboardReminderTile(item: item),
            ),
          ],
        ),
      );
    });
  }
}

class _DashboardReminderTile extends StatelessWidget {
  final EmployeeReminderItem item;

  const _DashboardReminderTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('EEEE، d/M - h:mm a', Get.locale?.languageCode)
        .format(item.scheduledAt);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: _employeeAlertColor.withValues(alpha: .22),
        ),
      ),
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.MYEMPLOYEEREMINDERSSCREEN),
        child: Row(
          children: [
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: const Color(0xffe6f4f1),
                borderRadius: BorderRadius.circular(9.r),
              ),
              child: Icon(
                Icons.notifications_active_outlined,
                color: _employeeAlertColor,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    dateText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.customGreyColor5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.customGreyColor5,
              size: 22.sp,
            ),
          ],
        ),
      ),
    );
  }
}
