import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/admin_notification_router.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/admin_notification_center_controller.dart';

class AdminNotificationCenterScreen extends GetView<AdminNotificationCenterController> {
  const AdminNotificationCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme.bodyMedium!;
    return Scaffold(
      appBar: CustomAppBar(
        title: 'notificationCenterTitle',
        action: true,
        actions: [
          TextButton(
            onPressed: controller.isBusyAction.value
                ? null
                : () => controller.markAllRead(),
            child: Text(
              'markAllRead'.tr,
              style: theme.copyWith(
                fontSize: 14.sp,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 44.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                children: AdminNotificationCenterController.filterDefs
                    .map(
                      (def) => Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: ChoiceChip(
                          label: Text(
                            def['labelKey']!.tr,
                            style: TextStyle(fontSize: 12.sp),
                          ),
                          selected: controller.selectedFilter.value == def['id'],
                          onSelected: (_) =>
                              controller.setFilter(def['id'] ?? 'all'),
                          selectedColor: AppColors.primaryColor.withValues(alpha: 0.25),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.load,
                child: controller.items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: 80.h),
                          Center(
                            child: Text(
                              'notificationEmpty'.tr,
                              style: theme.copyWith(fontSize: 16.sp),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Center(
                            child: TextButton(
                              onPressed: controller.load,
                              child: Text('tryAgain'.tr),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        itemCount: controller.items.length,
                        itemBuilder: (context, index) {
                          final row = controller.items[index];
                          final id = row['id'];
                          final title = row['title']?.toString() ?? '';
                          final body = row['body']?.toString() ?? '';
                          final read = row['is_read'] == true || row['is_read'] == 1;
                          final created = row['created_at']?.toString() ?? '';
                          return Card(
                            color: ThemeService.isDark.value
                                ? AppColors.customGreyColor
                                : AppColors.whiteColor2,
                            child: ListTile(
                              title: Text(
                                title,
                                style: theme.copyWith(
                                  fontWeight:
                                      read ? FontWeight.w500 : FontWeight.w800,
                                  fontSize: 15.sp,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4.h),
                                  Text(body, style: theme.copyWith(fontSize: 13.sp)),
                                  SizedBox(height: 4.h),
                                  Text(
                                    created,
                                    style: theme.copyWith(
                                      fontSize: 11.sp,
                                      color: AppColors.customGreyColor5,
                                    ),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                              onTap: () {
                                if (id != null) {
                                  final parsedId = int.tryParse(id.toString());
                                  if (parsedId != null) {
                                    controller.markRead(parsedId);
                                  }
                                }
                                final data = row['data'];
                                final Map<String, dynamic> payload = {
                                  if (data is Map)
                                    ...Map<String, dynamic>.from(data),
                                  'type': row['type']?.toString() ?? '',
                                  'related_type': row['related_type']?.toString() ?? '',
                                  'related_id': row['related_id']?.toString() ?? '',
                                  'employee_id': row['employee_id']?.toString() ?? '',
                                };
                                AdminNotificationRouter.handlePayload(payload);
                              },
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: controller.isBusyAction.value
                                    ? null
                                    : () {
                                        if (id != null) {
                                          controller.deleteOne(
                                            int.parse(id.toString()),
                                          );
                                        }
                                      },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
