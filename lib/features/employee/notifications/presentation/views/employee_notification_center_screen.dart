import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/employee_notification_router.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/widgets/notification_swipe_card.dart';
import '../controllers/employee_notification_center_controller.dart';

class EmployeeNotificationCenterScreen
    extends GetView<EmployeeNotificationCenterController> {
  const EmployeeNotificationCenterScreen({Key? key}) : super(key: key);

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
                children: EmployeeNotificationCenterController.filterDefs
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
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
                  itemCount: controller.items.length,
                  itemBuilder: (context, index) {
                    final row = controller.items[index];
                    final id = row['id'];
                    final title = row['title']?.toString() ?? '';
                    final body = row['body']?.toString() ?? '';
                    final read = row['is_read'] == true || row['is_read'] == 1;
                    final created = row['created_at']?.toString() ?? '';
                    final type = row['type']?.toString() ?? '';
                    final accent = _employeeNotificationColor(type);
                    return NotificationSwipeCard(
                      notificationKey: 'employee_notification_$id',
                      title: title,
                      body: body,
                      createdAt: created,
                      isRead: read,
                      icon: _employeeNotificationIcon(type),
                      accent: accent,
                      onMarkRead: () async {
                        final parsedId = int.tryParse('$id');
                        if (parsedId != null) {
                          await controller.markRead(parsedId);
                        }
                      },
                      onDelete: () async {
                        final parsedId = int.tryParse('$id');
                        if (parsedId != null) {
                          await controller.deleteOne(parsedId);
                        }
                      },
                      onTap: () {
                        if (id != null) {
                          final parsedId = int.tryParse(id.toString());
                          if (parsedId != null) {
                            controller.markRead(parsedId);
                          }
                        }
                        final data = row['data'];
                        final Map<String, dynamic> payload = {
                          if (data is Map) ...Map<String, dynamic>.from(data),
                          'type': row['type']?.toString() ?? '',
                          'related_type': row['related_type']?.toString() ?? '',
                          'related_id': row['related_id']?.toString() ?? '',
                          'employee_id': row['employee_id']?.toString() ?? '',
                        };
                        EmployeeNotificationRouter.handlePayload(payload);
                      },
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

Color _employeeNotificationColor(String type) {
  if (type.contains('complete') || type.contains('approved')) {
    return const Color(0xFF268B69);
  }
  if (type.contains('urgent') || type.contains('overdue')) {
    return const Color(0xFFD64545);
  }
  if (type.contains('reminder')) return const Color(0xFFE58A2B);
  return const Color(0xFF6844A5);
}

IconData _employeeNotificationIcon(String type) {
  if (type.contains('task')) return Icons.task_alt_rounded;
  if (type.contains('reminder')) return Icons.alarm_rounded;
  if (type.contains('salary')) return Icons.payments_outlined;
  if (type.contains('point') || type.contains('reward')) {
    return Icons.workspace_premium_outlined;
  }
  return Icons.notifications_none_rounded;
}
