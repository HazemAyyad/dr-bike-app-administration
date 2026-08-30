import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/admin_notification_router.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
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
            tooltip: 'إرسال إشعار للموظفين',
            onPressed: () => Get.toNamed(AppRoutes.NOTIFICATIONSETTINGSCENTER),
            icon: const Icon(Icons.campaign_outlined),
          ),
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
          Obx(() => Container(
                margin: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4D2F83), Color(0xFF7652B1)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x284D2F83),
                        blurRadius: 16,
                        offset: Offset(0, 7)),
                  ],
                ),
                child: Row(children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0x24FFFFFF),
                    child:
                        Icon(Icons.notifications_active, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('كل ما يحتاج انتباهك',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800)),
                        Text(
                            '${controller.unreadCount} غير مقروء من النتائج الظاهرة',
                            style: const TextStyle(
                                color: Color(0xDFFFFFFF), fontSize: 12)),
                      ])),
                  IconButton.filledTonal(
                    tooltip: 'تحديث',
                    onPressed: controller.load,
                    icon: const Icon(Icons.refresh),
                  ),
                ]),
              )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: controller.searchController,
              onChanged: controller.setSearch,
              decoration: InputDecoration(
                hintText: 'ابحث في العنوان أو المحتوى...',
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
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                            color: read
                                ? const Color(0xFFE9E5EE)
                                : accent.withValues(alpha: .35)),
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
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
                            if (data is Map) ...Map<String, dynamic>.from(data),
                            'type': row['type']?.toString() ?? '',
                            'related_type':
                                row['related_type']?.toString() ?? '',
                            'related_id': row['related_id']?.toString() ?? '',
                            'employee_id': row['employee_id']?.toString() ?? '',
                          };
                          AdminNotificationRouter.handlePayload(payload);
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                margin:
                                    const EdgeInsetsDirectional.only(end: 12),
                                decoration: BoxDecoration(
                                    color: accent.withValues(alpha: .12),
                                    borderRadius: BorderRadius.circular(13)),
                                child: Icon(_notificationIcon(type),
                                    color: accent, size: 21),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      style: theme.copyWith(fontSize: 13.sp),
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
                                    : () async {
                                        if (id != null) {
                                          final parsedId =
                                              int.tryParse(id.toString());
                                          if (parsedId != null) {
                                            final confirmed =
                                                await Get.dialog<bool>(
                                              AlertDialog(
                                                title:
                                                    const Text('حذف الإشعار؟'),
                                                content: const Text(
                                                    'سيختفي هذا الإشعار من مركزك فقط.'),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () => Get.back(
                                                          result: false),
                                                      child:
                                                          const Text('إلغاء')),
                                                  FilledButton(
                                                      onPressed: () => Get.back(
                                                          result: true),
                                                      child: const Text('حذف')),
                                                ],
                                              ),
                                            );
                                            if (confirmed == true) {
                                              controller.deleteOne(parsedId);
                                            }
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
  if (type.contains('login')) {
    return Icons.login;
  }
  if (type.contains('check')) {
    return Icons.receipt_long_outlined;
  }
  return Icons.notifications_none;
}
