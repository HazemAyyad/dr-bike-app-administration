import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/admin_notification_router.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/widgets/notification_swipe_card.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/admin_notification_center_controller.dart';

class AdminNotificationCenterScreen
    extends GetView<AdminNotificationCenterController> {
  const AdminNotificationCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme.bodyMedium!;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FA),
      appBar: CustomAppBar(
        title: 'notificationCenterTitle',
        action: false,
        actions: [
          IconButton(
            tooltip: 'مركز التحكم',
            onPressed: () => Get.toNamed(AppRoutes.NOTIFICATIONSETTINGSCENTER),
            icon: const Icon(Icons.tune),
          ),
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
          Obx(
            () => Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Row(
                children: [
                  const Icon(Icons.notifications_none_rounded,
                      size: 20, color: Color(0xFF6844A5)),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text(
                      'إشعارات الإدارة',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE5F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${controller.unreadCount} غير مقروء',
                      style: const TextStyle(
                        color: Color(0xFF6844A5),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: controller.searchController,
              onChanged: controller.setSearch,
              decoration: InputDecoration(
                hintText: 'بحث في الإشعارات...',
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(() => controller.search.value.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        onPressed: () {
                          controller.searchController.clear();
                          controller.setSearch('');
                        },
                        icon: const Icon(Icons.close),
                      )),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 8),
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
                          controller.errorMessage.value.isNotEmpty
                              ? controller.errorMessage.value
                              : 'notificationEmpty'.tr,
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
                  itemCount: controller.items.length +
                      (controller.hasMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == controller.items.length) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: OutlinedButton.icon(
                          onPressed: controller.isLoading.value
                              ? null
                              : () => controller.load(loadMore: true),
                          icon: const Icon(Icons.expand_more),
                          label: const Text('تحميل المزيد'),
                        ),
                      );
                    }
                    final row = controller.items[index];
                    final id = row['id'];
                    final title = row['title']?.toString() ?? '';
                    final body = row['body']?.toString() ?? '';
                    final read = row['is_read'] == true || row['is_read'] == 1;
                    final created = row['created_at']?.toString() ?? '';
                    final type = row['type']?.toString() ?? '';
                    final accent = _notificationColor(type);
                    return NotificationSwipeCard(
                      notificationKey: 'admin_notification_$id',
                      title: title,
                      body: body,
                      createdAt: created,
                      isRead: read,
                      icon: _notificationIcon(type),
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
                        AdminNotificationRouter.handlePayload(payload);
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

Color _notificationColor(String type) {
  if (type.contains('failed') ||
      type.contains('returned') ||
      type.contains('urgent')) {
    return const Color(0xFFD64545);
  }
  if (type.contains('completed') ||
      type.contains('delivered') ||
      type.contains('cashed')) {
    return const Color(0xFF268B69);
  }
  if (type.contains('sales') || type.contains('order')) {
    return const Color(0xFFE58A2B);
  }
  if (type.contains('whatsapp')) {
    return const Color(0xFF1FAF67);
  }
  if (type.contains('social')) {
    return const Color(0xFF3F70B5);
  }
  if (type.contains('login') || type.contains('security')) {
    return const Color(0xFF3F70B5);
  }
  return const Color(0xFF6844A5);
}

IconData _notificationIcon(String type) {
  if (type.contains('failed') || type.contains('returned')) {
    return Icons.error_outline;
  }
  if (type.contains('task')) {
    return Icons.task_alt;
  }
  if (type.contains('sales') || type.contains('order')) {
    return Icons.shopping_bag_outlined;
  }
  if (type.contains('whatsapp')) {
    return Icons.chat_outlined;
  }
  if (type.contains('social')) {
    return Icons.forum_outlined;
  }
  if (type.contains('login')) {
    return Icons.login;
  }
  if (type.contains('check')) {
    return Icons.receipt_long_outlined;
  }
  return Icons.notifications_none;
}
