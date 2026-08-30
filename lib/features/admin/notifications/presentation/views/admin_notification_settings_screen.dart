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
      length: 6,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5FA),
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
            _ControlCenterSummary(controller: controller),
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x10000000), blurRadius: 12),
                ],
              ),
              child: const TabBar(
                isScrollable: true,
                dividerColor: Colors.transparent,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(icon: Icon(Icons.campaign), text: 'إرسال'),
                  Tab(icon: Icon(Icons.tune), text: 'السياسات'),
                  Tab(icon: Icon(Icons.library_music), text: 'الأصوات'),
                  Tab(icon: Icon(Icons.devices), text: 'الأجهزة'),
                  Tab(icon: Icon(Icons.route), text: 'التسليم'),
                  Tab(icon: Icon(Icons.history), text: 'التدقيق'),
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
                    _ManualSendTab(controller: controller),
                    _PoliciesTab(controller: controller),
                    _SoundsTab(controller: controller),
                    _DevicesTab(controller: controller),
                    _DeliveriesTab(controller: controller),
                    _AuditsTab(controller: controller),
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

class _ControlCenterSummary extends StatelessWidget {
  const _ControlCenterSummary({required this.controller});

  final AdminNotificationSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4D2F83), Color(0xFF7652B1)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: Color(0x354D2F83), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0x28FFFFFF),
                child: Icon(Icons.notifications_active, color: Colors.white),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('غرفة تحكم الإشعارات',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    Text('الصوت، الظهور، المستلمون والتسليم من مكان واحد',
                        style:
                            TextStyle(color: Color(0xDFFFFFFF), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryPill(
                  label: 'سياسة فعالة',
                  value: controller.activePolicies,
                  icon: Icons.rule),
              _SummaryPill(
                  label: 'صوت متاح',
                  value: controller.readySounds,
                  icon: Icons.volume_up),
              _SummaryPill(
                  label: 'جهاز نشط',
                  value: controller.healthyDevices,
                  icon: Icons.smartphone),
              _SummaryPill(
                  label: 'فشل',
                  value: controller.failedDeliveries,
                  icon: Icons.warning_amber),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill(
      {required this.label, required this.value, required this.icon});
  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
            color: const Color(0x20FFFFFF),
            borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text('$value',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Color(0xE8FFFFFF), fontSize: 11)),
        ]),
      );
}

class _ManualSendTab extends StatelessWidget {
  const _ManualSendTab({required this.controller});

  final AdminNotificationSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final allEmployees = controller.employeeOptions.length;
      final selected = controller.selectedEmployeeIds.length;
      final isAll = controller.manualAudience.value == 'all';
      final visibleEmployees = controller.filteredEmployeeOptions;
      return ListView(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EAF9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDCCEF0)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFF6844A5),
                  child: Icon(Icons.campaign, color: Colors.white),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إنشاء إشعار للموظفين',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'سيظهر داخل مركز الموظف، ويمكن إرساله كتنبيه فوري بالصوت والأولوية التي تختارها.',
                        style: TextStyle(fontSize: 12, height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ManualSection(
            number: '1',
            title: 'المستلمون',
            child: Column(
              children: [
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'all',
                      icon: const Icon(Icons.groups),
                      label: Text('كل الموظفين ($allEmployees)'),
                    ),
                    ButtonSegment(
                      value: 'selected',
                      icon: const Icon(Icons.person_search),
                      label: Text('تحديد ($selected)'),
                    ),
                  ],
                  selected: {controller.manualAudience.value},
                  onSelectionChanged: (values) =>
                      controller.manualAudience.value = values.first,
                ),
                if (!isAll) ...[
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (value) =>
                        controller.employeeSearch.value = value,
                    decoration: InputDecoration(
                      hintText: 'ابحث باسم الموظف أو المسمى الوظيفي',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: const Color(0xFFF8F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => controller.selectedEmployeeIds.addAll(
                            visibleEmployees
                                .map((row) => int.tryParse('${row['id']}'))
                                .whereType<int>()),
                        child: const Text('تحديد الظاهر'),
                      ),
                      TextButton(
                        onPressed: controller.selectedEmployeeIds.clear,
                        child: const Text('إلغاء التحديد'),
                      ),
                    ],
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 290),
                    child: visibleEmployees.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('لا يوجد موظفون مطابقون للبحث'),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: visibleEmployees.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final employee = visibleEmployees[index];
                              final id = int.tryParse('${employee['id']}');
                              final checked = id != null &&
                                  controller.selectedEmployeeIds.contains(id);
                              return CheckboxListTile(
                                value: checked,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                                onChanged: id == null
                                    ? null
                                    : (_) => controller.toggleEmployee(id),
                                title: Text(
                                  employee['name']?.toString() ?? 'موظف #$id',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                                subtitle: Text(
                                  [
                                    employee['job_title']?.toString() ?? '',
                                    employee['has_push'] == true
                                        ? 'Push جاهز'
                                        : 'داخل المركز فقط عند غياب FCM',
                                  ]
                                      .where((text) => text.isNotEmpty)
                                      .join(' · '),
                                ),
                                secondary: Icon(
                                  employee['has_push'] == true
                                      ? Icons.notifications_active
                                      : Icons.notifications_none,
                                  color: employee['has_push'] == true
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ManualSection(
            number: '2',
            title: 'محتوى الإشعار',
            child: Column(
              children: [
                TextField(
                  controller: controller.manualTitleController,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                    hintText: 'مثال: اجتماع الفريق اليوم',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller.manualBodyController,
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'نص الإشعار',
                    hintText: 'اكتب الرسالة التي ستظهر للموظف بوضوح...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ManualSection(
            number: '3',
            title: 'طريقة التنبيه',
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  initialValue: controller.manualSoundId.value,
                  decoration: const InputDecoration(
                    labelText: 'الصوت',
                    prefixIcon: Icon(Icons.volume_up),
                    border: OutlineInputBorder(),
                  ),
                  items: controller.manualSounds
                      .map(
                        (sound) => DropdownMenuItem<int>(
                          value: int.tryParse('${sound['id']}'),
                          child: Text(sound['name']?.toString() ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => controller.manualSoundId.value = value,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: controller.previewManualSound,
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('معاينة الصوت المختار'),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: controller.manualPriority.value,
                  decoration: const InputDecoration(
                    labelText: 'الأولوية',
                    prefixIcon: Icon(Icons.flag_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('منخفضة')),
                    DropdownMenuItem(value: 'normal', child: Text('عادية')),
                    DropdownMenuItem(value: 'high', child: Text('مرتفعة')),
                    DropdownMenuItem(value: 'critical', child: Text('حرجة')),
                  ],
                  onChanged: (value) {
                    if (value != null) controller.manualPriority.value = value;
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('إرسال Push فوري'),
                  subtitle:
                      const Text('يبقى الإشعار داخل المركز حتى عند فشل Push'),
                  secondary: const Icon(Icons.send_to_mobile),
                  value: controller.manualPush.value,
                  onChanged: (value) => controller.manualPush.value = value,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('الاهتزاز'),
                  secondary: const Icon(Icons.vibration),
                  value: controller.manualVibration.value,
                  onChanged: controller.manualPush.value
                      ? (value) => controller.manualVibration.value = value
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: controller.isSendingManual.value
                ? null
                : controller.sendManualEmployeeNotification,
            icon: controller.isSendingManual.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(
              controller.isSendingManual.value
                  ? 'جاري الإرسال...'
                  : 'مراجعة وإرسال إلى ${isAll ? allEmployees : selected} موظف',
            ),
          ),
        ],
      );
    });
  }
}

class _ManualSection extends StatelessWidget {
  const _ManualSection({
    required this.number,
    required this.title,
    required this.child,
  });

  final String number;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE7E1EC)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: const Color(0xFF6844A5),
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
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
    return Obx(() => _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
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
    return Obx(() => _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
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
                        subtitle: Text(fromLibrary
                            ? 'مكتبة Doctor Bike · جاهز بالخلفية'
                            : bundled
                                ? 'صوت نظام · جاهز بالخلفية'
                                : 'مرفوع · يتزامن تلقائياً مع أجهزة الأدمن'),
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
    return Obx(() => _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                const Row(
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
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: controller.busyType.value == 'sound_sync'
                        ? null
                        : controller.syncCurrentDeviceSounds,
                    icon: const Icon(Icons.sync),
                    label: const Text('مزامنة أصوات هذا الجهاز الآن'),
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
                          '${user?['name'] ?? ''}\nآخر اتصال: ${device['last_seen_at'] ?? '-'}\n'
                          'أصوات جاهزة: ${device['ready_sounds_count'] ?? 0} · فشل: ${device['failed_sounds_count'] ?? 0}',
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
    return Obx(() => _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
    if (controller.deliveries.isEmpty) {
      return const _EmptyState(label: 'لا توجد محاولات تسليم مسجلة');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: controller.deliveries.length,
      itemBuilder: (context, index) {
        final row = controller.deliveries[index];
        final notification = row['notification'] as Map?;
        final sent =
            const ['sent', 'delivered', 'opened'].contains(row['status']);
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
            trailing: sent
                ? const Chip(label: Text('أُرسل'))
                : IconButton.filledTonal(
                    tooltip: 'إعادة المحاولة',
                    onPressed:
                        controller.busyType.value == 'delivery_${row['id']}'
                            ? null
                            : () => controller.retryDelivery(row),
                    icon: const Icon(Icons.refresh),
                  ),
          ),
        );
      },
    );
  }
}

class _AuditsTab extends StatelessWidget {
  const _AuditsTab({required this.controller});

  final AdminNotificationSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
    if (controller.audits.isEmpty) {
      return const _EmptyState(label: 'لا توجد تغييرات إدارية مسجلة بعد');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: controller.audits.length,
      itemBuilder: (context, index) {
        final row = controller.audits[index];
        final user = row['user'] as Map?;
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.history)),
            title: Text(
                '${_auditAction(row['action'])} · ${row['auditable_type'] ?? ''}'),
            subtitle: Text(
                '${user?['name'] ?? 'أدمن'} · ${row['created_at'] ?? '-'}'),
            trailing: Text('#${row['auditable_id'] ?? '-'}'),
          ),
        );
      },
    );
  }
}

String _auditAction(dynamic action) {
  switch (action) {
    case 'created':
      return 'إنشاء';
    case 'updated':
      return 'تعديل';
    case 'deleted':
      return 'حذف';
    case 'reset':
      return 'استعادة الافتراضي';
    case 'sent':
      return 'إرسال';
    default:
      return action?.toString() ?? 'تغيير';
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
