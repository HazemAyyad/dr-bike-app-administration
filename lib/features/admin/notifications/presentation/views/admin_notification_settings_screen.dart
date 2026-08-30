import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/admin_notification_settings_controller.dart';

class AdminNotificationSettingsScreen
    extends GetView<AdminNotificationSettingsController> {
  const AdminNotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'مركز التحكم بالإشعارات',
          action: false,
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: controller.load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            const Material(
              color: Colors.transparent,
              child: TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'الأنواع'),
                  Tab(text: 'الأصوات'),
                  Tab(text: 'أجهزة الإشعارات'),
                  Tab(text: 'سجل التسليم'),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.catalog.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return TabBarView(
                  children: [
                    _PoliciesTab(controller: controller),
                    _SoundsTab(controller: controller),
                    _DevicesTab(controller: controller),
                    _DeliveriesTab(controller: controller),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _PoliciesTab extends StatelessWidget {
  const _PoliciesTab({required this.controller});

  final AdminNotificationSettingsController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.catalog.isEmpty) {
      return const _EmptyState(label: 'لا توجد أنواع إشعارات');
    }
    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: controller.catalog.length,
        itemBuilder: (context, index) {
          final item = controller.catalog[index];
          final policy =
              Map<String, dynamic>.from(item['policy'] as Map? ?? {});
          final type = item['type']?.toString() ?? '';
          final enabled = policy['is_enabled'] == true;
          final push = policy['push_enabled'] == true;
          final sound = policy['sound'] as Map?;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: enabled
                    ? AppColors.primaryColor.withValues(alpha: .15)
                    : Colors.grey.withValues(alpha: .15),
                child: Icon(
                  _categoryIcon(item['category']?.toString()),
                  color: enabled ? AppColors.primaryColor : Colors.grey,
                ),
              ),
              title: Text(
                item['name']?.toString() ?? type,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${item['category'] ?? ''} · ${_priorityLabel(policy['priority'])} · ${sound?['name'] ?? 'افتراضي'}',
              ),
              trailing: Switch(
                value: enabled,
                onChanged: controller.busyType.value == type
                    ? null
                    : (value) => controller.updatePolicy(
                          type,
                          {'is_enabled': value},
                        ),
              ),
              children: [
                SwitchListTile(
                  title: const Text('إظهار داخل مركز الإشعارات'),
                  value: policy['in_app_enabled'] == true,
                  onChanged: (value) => controller.updatePolicy(
                    type,
                    {'in_app_enabled': value},
                  ),
                ),
                SwitchListTile(
                  title: const Text('إرسال Push'),
                  value: push,
                  onChanged: (value) => controller.updatePolicy(
                    type,
                    {'push_enabled': value},
                  ),
                ),
                SwitchListTile(
                  title: const Text('اهتزاز'),
                  value: policy['vibration_enabled'] == true,
                  onChanged: (value) => controller.updatePolicy(
                    type,
                    {'vibration_enabled': value},
                  ),
                ),
                SwitchListTile(
                  title: const Text('إظهار المحتوى على شاشة القفل'),
                  subtitle: item['sensitive'] == true
                      ? const Text('هذا النوع قد يحتوي معلومات حساسة')
                      : null,
                  value: policy['show_on_lock_screen'] == true,
                  onChanged: (value) => controller.updatePolicy(
                    type,
                    {'show_on_lock_screen': value},
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue:
                              policy['priority']?.toString() ?? 'normal',
                          decoration: const InputDecoration(
                            labelText: 'الأولوية',
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'low', child: Text('منخفضة')),
                            DropdownMenuItem(
                                value: 'normal', child: Text('عادية')),
                            DropdownMenuItem(
                                value: 'high', child: Text('مرتفعة')),
                            DropdownMenuItem(
                                value: 'critical', child: Text('حرجة')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              controller
                                  .updatePolicy(type, {'priority': value});
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: int.tryParse('${policy['sound_id']}'),
                          decoration: const InputDecoration(
                            labelText: 'الصوت',
                            isDense: true,
                          ),
                          items: controller.sounds
                              .where((row) => row['is_active'] == true)
                              .map(
                                (row) => DropdownMenuItem<int>(
                                  value: int.tryParse('${row['id']}'),
                                  child: Text(
                                    row['name']?.toString() ?? '',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => controller.updatePolicy(
                            type,
                            {'sound_id': value},
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => controller.editTemplate(item),
                        icon: const Icon(Icons.edit_note),
                        label: const Text('القالب'),
                      ),
                      TextButton.icon(
                        onPressed: () => controller.editAdvancedPolicy(item),
                        icon: const Icon(Icons.tune),
                        label: const Text('متقدم'),
                      ),
                      TextButton.icon(
                        onPressed: () => controller.resetPolicy(type),
                        icon: const Icon(Icons.restore),
                        label: const Text('الافتراضي'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SoundsTab extends StatelessWidget {
  const _SoundsTab({required this.controller});

  final AdminNotificationSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: controller.pickAndUploadSound,
              icon: const Icon(Icons.upload_file),
              label: const Text('رفع صوت جديد'),
            ),
          ),
        ),
        Expanded(
          child: controller.sounds.isEmpty
              ? const _EmptyState(label: 'مكتبة الأصوات فارغة')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: controller.sounds.length,
                  itemBuilder: (context, index) {
                    final sound = controller.sounds[index];
                    final bundled = sound['source'] == 'bundled';
                    final fromLibrary = sound['category'] == 'library';
                    final active = sound['is_active'] == true;
                    return Card(
                      child: ListTile(
                        leading: IconButton.filledTonal(
                          tooltip: 'معاينة',
                          onPressed: () => controller.preview(sound),
                          icon: const Icon(Icons.play_arrow),
                        ),
                        title: Text(sound['name']?.toString() ?? ''),
                        subtitle: Text(
                          fromLibrary
                              ? 'من مكتبة الأصوات الجاهزة · يعمل بالخلفية'
                              : bundled
                                  ? 'جاهز مع التطبيق · يعمل بالخلفية'
                                  : 'مرفوع · المعاينة وForeground · الخلفية تستخدم الصوت الاحتياطي',
                        ),
                        trailing: bundled
                            ? Chip(
                                avatar: fromLibrary
                                    ? const Icon(Icons.library_music, size: 16)
                                    : null,
                                label: Text(
                                  fromLibrary ? 'مكتبة جاهزة' : 'نظام',
                                ),
                              )
                            : PopupMenuButton<String>(
                                onSelected: (action) {
                                  if (action == 'toggle') {
                                    controller.toggleSound(sound);
                                  } else if (action == 'delete') {
                                    controller.deleteSound(sound);
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'toggle',
                                    child: Text(active ? 'تعطيل' : 'تفعيل'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('حذف'),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DevicesTab extends StatelessWidget {
  const _DevicesTab({required this.controller});

  final AdminNotificationSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Card(
          margin: EdgeInsets.all(12),
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'يعرض هذا التبويب أجهزة الأدمن المسجلة لاستقبال الإشعارات، والمنصة وصاحب الجهاز وآخر اتصال بالسيرفر.',
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: controller.devices.isEmpty
              ? const _EmptyState(label: 'لا توجد أجهزة أدمن مسجلة')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: controller.devices.length,
                  itemBuilder: (context, index) {
                    final device = controller.devices[index];
                    final user = device['user'] as Map?;
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          device['platform'] == 'ios'
                              ? Icons.phone_iphone
                              : Icons.android,
                        ),
                        title: Text(
                          device['device_name']?.toString() ?? 'جهاز غير مسمى',
                        ),
                        subtitle: Text(
                          '${user?['name'] ?? ''}\nآخر اتصال: ${device['last_seen_at'] ?? '-'}',
                        ),
                        isThreeLine: true,
                        trailing: const Chip(
                          avatar: Icon(Icons.notifications_active, size: 16),
                          label: Text('FCM'),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DeliveriesTab extends StatelessWidget {
  const _DeliveriesTab({required this.controller});

  final AdminNotificationSettingsController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.deliveries.isEmpty) {
      return const _EmptyState(label: 'لا توجد محاولات تسليم مسجلة');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: controller.deliveries.length,
      itemBuilder: (context, index) {
        final row = controller.deliveries[index];
        final notification = row['notification'] as Map?;
        final sent = row['status'] == 'sent';
        return Card(
          child: ListTile(
            leading: Icon(
              sent ? Icons.check_circle : Icons.error_outline,
              color: sent ? Colors.green : Colors.red,
            ),
            title: Text(notification?['title']?.toString() ?? 'إشعار'),
            subtitle: Text(
              '${notification?['type'] ?? ''} · ${row['channel_id'] ?? '-'}\n'
              '${row['used_fallback'] == true ? 'استُخدم الصوت الاحتياطي' : 'الصوت المطلوب'}',
            ),
            isThreeLine: true,
            trailing: Text(row['status']?.toString() ?? ''),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

String _priorityLabel(dynamic priority) {
  switch (priority) {
    case 'low':
      return 'منخفضة';
    case 'high':
      return 'مرتفعة';
    case 'critical':
      return 'حرجة';
    default:
      return 'عادية';
  }
}

IconData _categoryIcon(String? category) {
  switch (category) {
    case 'attendance':
      return Icons.access_time;
    case 'tasks':
      return Icons.task_alt;
    case 'sales':
    case 'store':
      return Icons.shopping_cart_outlined;
    case 'checks':
      return Icons.receipt_long_outlined;
    case 'security':
      return Icons.security;
    case 'stock':
      return Icons.inventory_2_outlined;
    default:
      return Icons.notifications_outlined;
  }
}
