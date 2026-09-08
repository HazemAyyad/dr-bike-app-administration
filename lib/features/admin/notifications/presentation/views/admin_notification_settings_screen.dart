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
        backgroundColor: const Color(0xFFF7F5FA),
        appBar: const CustomAppBar(
          title: 'مركز التحكم بالإشعارات',
          action: false,
          actions: [],
        ),
        body: Theme(
          data: Theme.of(context).copyWith(
            iconTheme: const IconThemeData(size: 19),
            listTileTheme: const ListTileThemeData(
              dense: true,
              iconColor: Color(0xFF514C55),
              titleTextStyle: TextStyle(
                color: Color(0xFF211D24),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              subtitleTextStyle: TextStyle(
                color: Color(0xFF625D66),
                fontSize: 11,
              ),
            ),
          ),
          child: Column(
            children: [
              _ControlCenterSummary(controller: controller),
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x10000000), blurRadius: 12),
                  ],
                ),
                child: const TabBar(
                  dividerColor: Colors.transparent,
                  labelPadding: EdgeInsets.symmetric(horizontal: 4),
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: TextStyle(fontSize: 12),
                  tabs: [
                    Tab(
                        height: 48,
                        icon: Icon(Icons.campaign_outlined, size: 19),
                        text: 'إرسال'),
                    Tab(
                        height: 48,
                        icon: Icon(Icons.tune_rounded, size: 19),
                        text: 'السياسات'),
                    Tab(
                        height: 48,
                        icon: Icon(Icons.library_music_outlined, size: 19),
                        text: 'الأصوات'),
                    Tab(
                        height: 48,
                        icon: Icon(Icons.monitor_heart_outlined, size: 19),
                        text: 'المتابعة'),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value &&
                      controller.catalog.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return TabBarView(
                    children: [
                      _ManualSendTab(controller: controller),
                      _PoliciesTab(controller: controller),
                      _SoundsTab(controller: controller),
                      _TechnicalTab(controller: controller),
                    ],
                  );
                }),
              ),
            ],
          ),
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
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E1EC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined,
              size: 20, color: Color(0xFF6844A5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'جاهز للإرسال إلى ${controller.employeeOptions.length} موظف · '
              '${controller.activePolicies} سياسة فعالة',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          _StatusLabel(
            icon: controller.failedDeliveries == 0
                ? Icons.check_circle_outline
                : Icons.warning_amber,
            label: controller.failedDeliveries == 0
                ? 'جاهز'
                : '${controller.failedDeliveries} فشل',
            color: controller.failedDeliveries == 0
                ? const Color(0xFF268B69)
                : Colors.red,
          ),
        ],
      ),
    );
  }
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
      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
          children: [
            _ManualSection(
              number: '1',
              title: 'المستلمون',
              subtitle: isAll
                  ? 'كل الموظفين · $allEmployees مستلم'
                  : '$selected موظف محدد',
              icon: Icons.groups_outlined,
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
                          onPressed: () => controller.selectedEmployeeIds
                              .addAll(visibleEmployees
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
              subtitle: 'العنوان، الرسالة والمعاينة',
              icon: Icons.chat_bubble_outline_rounded,
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
              subtitle:
                  '${_priorityLabel(controller.manualPriority.value)} · ${controller.manualPush.value ? 'Push فوري' : 'داخل المركز فقط'}',
              icon: Icons.notifications_active_outlined,
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
                    onChanged: (value) =>
                        controller.manualSoundId.value = value,
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
                      if (value != null) {
                        controller.manualPriority.value = value;
                      }
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
        ),
      );
    });
  }
}

class _ManualSection extends StatelessWidget {
  const _ManualSection({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE7E1EC)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE5F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF6844A5), size: 18),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        children: [child],
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
        itemCount: controller.filteredPolicies.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      onChanged: (value) =>
                          controller.policySearch.value = value,
                      decoration: InputDecoration(
                        hintText: 'ابحث في السياسات',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: controller.policyCategory.value,
                      decoration: InputDecoration(
                        labelText: 'القسم',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('الكل'),
                        ),
                        ...controller.policyCategories.map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(
                              _categoryLabel(category),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          controller.policyCategory.value = value ?? 'all',
                    ),
                  ),
                ],
              ),
            );
          }
          if (controller.filteredPolicies.isEmpty) {
            return const _EmptyState(label: 'لا توجد سياسات مطابقة');
          }
          final item = controller.filteredPolicies[index - 1];
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
                '${_categoryLabel(item['category']?.toString())} · ${_priorityLabel(policy['priority'])} · ${sound?['name'] ?? 'افتراضي'}',
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
                          isExpanded: true,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<int>(
                              isExpanded: true,
                              initialValue:
                                  int.tryParse('${policy['sound_id']}'),
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
                              onChanged: controller.busyType.value == type
                                  ? null
                                  : (value) async {
                                      await controller.previewSoundById(value);
                                      await controller.updatePolicy(
                                        type,
                                        {'sound_id': value},
                                      );
                                    },
                            ),
                            TextButton.icon(
                              onPressed: policy['sound_id'] == null
                                  ? null
                                  : () => controller.previewSoundById(
                                        int.tryParse('${policy['sound_id']}'),
                                      ),
                              icon: const Icon(Icons.play_circle_outline),
                              label: const Text('معاينة الصوت الحالي'),
                            ),
                          ],
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

class _TechnicalTab extends StatelessWidget {
  const _TechnicalTab({required this.controller});

  final AdminNotificationSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const TabBar(
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              unselectedLabelStyle: TextStyle(fontSize: 11),
              tabs: [
                Tab(
                    height: 44,
                    icon: Icon(Icons.devices_outlined, size: 18),
                    text: 'الأجهزة'),
                Tab(
                    height: 44,
                    icon: Icon(Icons.route_outlined, size: 18),
                    text: 'الإرسال'),
                Tab(
                    height: 44,
                    icon: Icon(Icons.history_rounded, size: 18),
                    text: 'السجل'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _DevicesTab(controller: controller),
                _DeliveriesTab(controller: controller),
                _AuditsTab(controller: controller),
              ],
            ),
          ),
        ],
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
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: controller.pickAndUploadSound,
              icon: const Icon(Icons.upload_file),
              label: const Text('رفع صوت جديد'),
            ),
          ),
        ),
        Expanded(
          child: controller.sounds.isEmpty
              ? const _EmptyState(label: 'مكتبة الأصوات فارغة')
              : RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: controller.sounds.length,
                    itemBuilder: (context, index) {
                      final sound = controller.sounds[index];
                      final bundled = sound['source'] == 'bundled';
                      final fromLibrary = sound['category'] == 'library';
                      final active = sound['is_active'] == true;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          visualDensity: const VisualDensity(vertical: -1),
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
                              ? _StatusLabel(
                                  icon: fromLibrary
                                      ? Icons.library_music
                                      : Icons.inventory_2_outlined,
                                  label: fromLibrary
                                      ? 'مكتبة جاهزة'
                                      : 'مدمج بالتطبيق',
                                  color: const Color(0xFF6844A5),
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
          margin: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.devices_outlined,
                        color: Color(0xFF6844A5)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'أجهزة الأدمن المسجلة',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text('${controller.devices.length} جهاز',
                        style: const TextStyle(
                            color: Color(0xFF6844A5), fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
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
              : RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: controller.devices.length,
                    itemBuilder: (context, index) {
                      final device = controller.devices[index];
                      final user = device['user'] as Map?;
                      final platform = device['platform']?.toString();
                      final lastSeen =
                          _formatDeviceDate(device['last_seen_at']);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          visualDensity: const VisualDensity(vertical: -1),
                          leading: Icon(
                            platform == 'ios'
                                ? Icons.phone_iphone
                                : Icons.android,
                          ),
                          title: Text(
                            device['device_name']
                                        ?.toString()
                                        .trim()
                                        .isNotEmpty ==
                                    true
                                ? device['device_name'].toString()
                                : platform == 'ios'
                                    ? 'جهاز آيفون'
                                    : 'جهاز أندرويد',
                          ),
                          subtitle: Text(
                            '${user?['name'] ?? ''} · ${platform == 'ios' ? 'آيفون' : 'أندرويد'}\nآخر اتصال: $lastSeen\n'
                            'أصوات جاهزة: ${device['ready_sounds_count'] ?? 0} · فشل: ${device['failed_sounds_count'] ?? 0}',
                          ),
                          isThreeLine: true,
                          trailing: const _StatusLabel(
                            icon: Icons.circle,
                            label: 'Push مسجل',
                            color: Color(0xFF268B69),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

String _formatDeviceDate(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return '-';
  DateTime? parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    final legacy = RegExp(
      r'^(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?Z-(\d{2})-(\d{4})$',
    ).firstMatch(raw);
    if (legacy != null) {
      parsed = DateTime.tryParse(
        '${legacy.group(6)}-${legacy.group(5)}-${legacy.group(1)}T'
        '${legacy.group(2)}:${legacy.group(3)}:${legacy.group(4)}Z',
      );
    }
  }
  if (parsed == null) return raw;
  final local = parsed.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} · '
      '${two(local.hour)}:${two(local.minute)}';
}

class _DeliveriesTab extends StatelessWidget {
  const _DeliveriesTab({required this.controller});

  final AdminNotificationSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        const _InfoCard(
          icon: Icons.route,
          title: 'ماذا تعني حالة الإرسال؟',
          body:
              'يعرض كل محاولة Push إلى جهاز أدمن: أرسله السيرفر، وصل للتطبيق، تم فتحه، أو فشل ويمكن إعادة المحاولة.',
        ),
        Expanded(
          child: controller.deliveries.isEmpty
              ? const _EmptyState(label: 'لا توجد محاولات إرسال مسجلة بعد')
              : RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: controller.deliveries.length,
                    itemBuilder: (context, index) {
                      final row = controller.deliveries[index];
                      final notification = row['notification'] as Map?;
                      final status = row['status']?.toString() ?? 'pending';
                      final successful = const ['sent', 'delivered', 'opened']
                          .contains(status);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          visualDensity: const VisualDensity(vertical: -1),
                          leading: Icon(
                            successful
                                ? Icons.check_circle
                                : Icons.error_outline,
                            color: successful ? Colors.green : Colors.red,
                          ),
                          title: Text(
                            notification?['title']?.toString() ?? 'إشعار',
                          ),
                          subtitle: Text(
                            '${notification?['type'] ?? ''}\n'
                            '${row['used_fallback'] == true ? 'استُخدم الصوت الاحتياطي' : 'استُخدم الصوت المختار'}'
                            '${row['created_at'] == null ? '' : ' · ${_formatDeviceDate(row['created_at'])}'}',
                          ),
                          isThreeLine: true,
                          trailing: status == 'failed'
                              ? IconButton.filledTonal(
                                  tooltip: 'إعادة المحاولة',
                                  onPressed: controller.busyType.value ==
                                          'delivery_${row['id']}'
                                      ? null
                                      : () => controller.retryDelivery(row),
                                  icon: const Icon(Icons.refresh),
                                )
                              : _StatusLabel(
                                  icon: _deliveryStatusIcon(status),
                                  label: _deliveryStatusLabel(status),
                                  color: _deliveryStatusColor(status),
                                ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
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
    return Column(
      children: [
        const _InfoCard(
          icon: Icons.manage_history,
          title: 'ما هو سجل التغييرات؟',
          body:
              'يحفظ من غيّر سياسة أو قالباً أو صوتاً، ومتى حدث التغيير، لتسهيل المراجعة ومعرفة سبب أي إعداد.',
        ),
        Expanded(
          child: controller.audits.isEmpty
              ? const _EmptyState(label: 'لا توجد تغييرات إدارية مسجلة بعد')
              : RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: controller.audits.length,
                    itemBuilder: (context, index) {
                      final row = controller.audits[index];
                      final user = row['user'] as Map?;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          visualDensity: const VisualDensity(vertical: -1),
                          leading:
                              const CircleAvatar(child: Icon(Icons.history)),
                          title: Text(
                            '${_auditAction(row['action'])} · ${_auditType(row['auditable_type'])}',
                          ),
                          subtitle: Text(
                            '${user?['name'] ?? 'أدمن'} · ${_formatDeviceDate(row['created_at'])}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
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

String _auditType(dynamic type) {
  switch (type) {
    case 'policy':
      return 'سياسة إشعار';
    case 'template':
      return 'قالب رسالة';
    case 'sound':
      return 'صوت';
    case 'manual_employee_notification':
      return 'إشعار موظفين يدوي';
    default:
      return type?.toString() ?? 'إعداد';
  }
}

String _deliveryStatusLabel(String status) {
  switch (status) {
    case 'sent':
      return 'أرسله السيرفر';
    case 'delivered':
      return 'وصل للتطبيق';
    case 'opened':
      return 'تم فتحه';
    case 'pending':
      return 'قيد الإرسال';
    default:
      return status;
  }
}

IconData _deliveryStatusIcon(String status) {
  switch (status) {
    case 'opened':
      return Icons.mark_email_read_outlined;
    case 'delivered':
      return Icons.phone_android;
    case 'sent':
      return Icons.cloud_done_outlined;
    default:
      return Icons.schedule;
  }
}

Color _deliveryStatusColor(String status) {
  switch (status) {
    case 'opened':
      return const Color(0xFF268B69);
    case 'delivered':
      return const Color(0xFF3F70B5);
    default:
      return const Color(0xFF6844A5);
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EAF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCCEF0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6844A5)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(body, style: const TextStyle(fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
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
    case 'sales_orders':
      return Icons.shopping_cart_outlined;
    case 'checks':
      return Icons.receipt_long_outlined;
    case 'security':
      return Icons.security;
    case 'messages':
      return Icons.forum_outlined;
    case 'stock':
      return Icons.inventory_2_outlined;
    default:
      return Icons.notifications_outlined;
  }
}

String _categoryLabel(String? category) {
  switch (category) {
    case 'attendance':
      return 'الحضور';
    case 'tasks':
      return 'المهام';
    case 'sales':
      return 'المبيعات';
    case 'store':
      return 'المتجر';
    case 'sales_orders':
      return 'الطلبيات';
    case 'checks':
      return 'الشيكات';
    case 'security':
      return 'الأمان';
    case 'messages':
      return 'الرسائل';
    case 'stock':
      return 'المخزون';
    case 'employees':
      return 'الموظفون';
    case 'goals':
      return 'الأهداف';
    case 'maintenance':
      return 'الصيانة';
    case 'notes':
      return 'الملاحظات';
    case 'development':
      return 'التطوير';
    default:
      return category?.isNotEmpty == true ? category! : 'عام';
  }
}
