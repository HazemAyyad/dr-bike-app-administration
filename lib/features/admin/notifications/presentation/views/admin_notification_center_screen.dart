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
        action: false,
        actions: [
          Obx(
            () => TextButton(
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
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: Obx(
              () => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: AdminNotificationCenterController.filterDefs
                    .map(
                      (def) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            def['labelKey']!.tr,
                            style: TextStyle(fontSize: 12.sp),
                          ),
                          selected:
                              controller.selectedFilter.value == def['id'],
                          onSelected: (_) =>
                              controller.setFilter(def['id'] ?? 'all'),
                          selectedColor:
                              AppColors.primaryColor.withValues(alpha: 0.25),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.items.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.items.isEmpty) {
                return RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Text(
                          'notificationEmpty'.tr,
                          style: theme.copyWith(fontSize: 16.sp),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: controller.load,
                          child: Text('tryAgain'.tr),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: controller.load,
                child: ListView.builder(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
                  itemCount: controller.items.length,
                  itemBuilder: (context, index) {
                    final row = controller.items[index];
                    final id = row['id'];
                    final title = row['title']?.toString() ?? '';
                    final body = row['body']?.toString() ?? '';
                    final read =
                        row['is_read'] == true || row['is_read'] == 1;
                    final created = row['created_at']?.toString() ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: ThemeService.isDark.value
                          ? AppColors.customGreyColor
                          : AppColors.whiteColor2,
                      child: InkWell(
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
                            'related_type':
                                row['related_type']?.toString() ?? '',
                            'related_id':
                                row['related_id']?.toString() ?? '',
                            'employee_id':
                                row['employee_id']?.toString() ?? '',
                          };
                          AdminNotificationRouter.handlePayload(payload);
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: theme.copyWith(
                                        fontWeight: read
                                            ? FontWeight.w500
                                            : FontWeight.w800,
                                        fontSize: 15.sp,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      body,
                                      style:
                                          theme.copyWith(fontSize: 13.sp),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      created,
                                      style: theme.copyWith(
                                        fontSize: 11.sp,
                                        color: AppColors.customGreyColor5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: controller.isBusyAction.value
                                    ? null
                                    : () {
                                        if (id != null) {
                                          final parsedId =
                                              int.tryParse(id.toString());
                                          if (parsedId != null) {
                                            controller.deleteOne(parsedId);
                                          }
                                        }
                                      },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
