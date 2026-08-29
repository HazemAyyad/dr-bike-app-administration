import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/services/admin_notification_settings_api_service.dart';

class AdminNotificationSettingsController extends GetxController {
  final _api = AdminNotificationSettingsApiService();
  final _player = AudioPlayer();

  final isLoading = false.obs;
  final busyType = ''.obs;
  final catalog = <Map<String, dynamic>>[].obs;
  final sounds = <Map<String, dynamic>>[].obs;
  final templates = <Map<String, dynamic>>[].obs;
  final devices = <Map<String, dynamic>>[].obs;
  final deliveries = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _api.fetchCatalog(),
        _api.fetchSounds(),
        _api.fetchTemplates(),
        _api.fetchDevices(),
        _api.fetchDeliveries(),
      ]);
      catalog.assignAll(results[0]);
      sounds.assignAll(results[1]);
      templates.assignAll(results[2]);
      devices.assignAll(results[3]);
      deliveries.assignAll(results[4]);
    } catch (error) {
      Get.snackbar('خطأ', 'تعذر تحميل إعدادات مركز الإشعارات');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePolicy(
    String type,
    Map<String, dynamic> values,
  ) async {
    busyType.value = type;
    try {
      await _api.updatePolicy(type, values);
      await _reloadCatalog();
    } catch (_) {
      Get.snackbar('خطأ', 'تعذر حفظ سياسة الإشعار');
    } finally {
      busyType.value = '';
    }
  }

  Future<void> resetPolicy(String type) async {
    busyType.value = type;
    try {
      await _api.resetPolicy(type);
      await _reloadCatalog();
    } finally {
      busyType.value = '';
    }
  }

  Future<void> editAdvancedPolicy(Map<String, dynamic> item) async {
    final type = item['type']?.toString() ?? '';
    final policy = Map<String, dynamic>.from(item['policy'] as Map? ?? {});
    final start = TextEditingController(
      text: _shortTime(policy['quiet_hours_start']),
    );
    final end = TextEditingController(
      text: _shortTime(policy['quiet_hours_end']),
    );
    final cooldown = TextEditingController(
      text: '${policy['cooldown_seconds'] ?? 0}',
    );
    final recipientValues = TextEditingController(
      text: ((policy['audience'] == 'roles'
                  ? policy['recipient_roles']
                  : policy['recipient_user_ids']) as List?)
              ?.join(', ') ??
          '',
    );
    var audience = policy['audience']?.toString() ?? 'all_admins';
    var bypassQuiet = policy['bypass_quiet_hours'] == true;
    var foregroundBanner = policy['show_foreground_banner'] == true;
    int? fallbackId = int.tryParse('${policy['fallback_sound_id']}');

    final values = await Get.dialog<Map<String, dynamic>>(
      StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('إعدادات متقدمة · ${item['name'] ?? type}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: start,
                        decoration: const InputDecoration(
                          labelText: 'بداية الهدوء HH:mm',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: end,
                        decoration: const InputDecoration(
                          labelText: 'نهاية الهدوء HH:mm',
                        ),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: cooldown,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'منع التكرار بالثواني',
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: audience,
                  decoration: const InputDecoration(labelText: 'المستلمون'),
                  items: const [
                    DropdownMenuItem(
                      value: 'all_admins',
                      child: Text('جميع الأدمن'),
                    ),
                    DropdownMenuItem(
                      value: 'selected_users',
                      child: Text('مستخدمون محددون'),
                    ),
                    DropdownMenuItem(
                      value: 'roles',
                      child: Text('أدوار محددة'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    audience = value ?? audience;
                  }),
                ),
                if (audience != 'all_admins')
                  TextField(
                    controller: recipientValues,
                    decoration: InputDecoration(
                      labelText: audience == 'roles'
                          ? 'الأدوار مفصولة بفاصلة'
                          : 'أرقام المستخدمين مفصولة بفاصلة',
                    ),
                  ),
                DropdownButtonFormField<int>(
                  initialValue: fallbackId,
                  decoration: const InputDecoration(
                    labelText: 'الصوت الاحتياطي',
                  ),
                  items: sounds
                      .where((row) => row['is_active'] == true)
                      .map(
                        (row) => DropdownMenuItem<int>(
                          value: int.tryParse('${row['id']}'),
                          child: Text(row['name']?.toString() ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => fallbackId = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تجاوز ساعات الهدوء'),
                  value: bypassQuiet,
                  onChanged: (value) => setState(() => bypassQuiet = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Banner أثناء فتح التطبيق'),
                  value: foregroundBanner,
                  onChanged: (value) =>
                      setState(() => foregroundBanner = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                final recipients = recipientValues.text
                    .split(',')
                    .map((value) => value.trim())
                    .where((value) => value.isNotEmpty)
                    .toList();
                Get.back(
                  result: {
                    'quiet_hours_start':
                        start.text.trim().isEmpty ? null : start.text.trim(),
                    'quiet_hours_end':
                        end.text.trim().isEmpty ? null : end.text.trim(),
                    'cooldown_seconds': int.tryParse(cooldown.text) ?? 0,
                    'audience': audience,
                    'recipient_user_ids': audience == 'selected_users'
                        ? recipients.map(int.tryParse).whereType<int>().toList()
                        : null,
                    'recipient_roles': audience == 'roles' ? recipients : null,
                    'fallback_sound_id': fallbackId,
                    'bypass_quiet_hours': bypassQuiet,
                    'show_foreground_banner': foregroundBanner,
                  },
                );
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    start.dispose();
    end.dispose();
    cooldown.dispose();
    recipientValues.dispose();
    if (values != null) await updatePolicy(type, values);
  }

  Future<void> editTemplate(Map<String, dynamic> item) async {
    final type = item['type']?.toString() ?? '';
    final current = templates.firstWhereOrNull(
      (row) => row['notification_type'] == type && row['locale'] == 'ar',
    );
    final title = TextEditingController(
      text: current?['title_template']?.toString() ?? '{{title}}',
    );
    final body = TextEditingController(
      text: current?['body_template']?.toString() ?? '{{body}}',
    );
    final lock = TextEditingController(
      text: current?['lock_screen_template']?.toString() ?? '',
    );
    final save = await Get.dialog<bool>(
      AlertDialog(
        title: Text('قالب · ${item['name'] ?? type}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'العنوان'),
              ),
              TextField(
                controller: body,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'النص'),
              ),
              TextField(
                controller: lock,
                decoration: const InputDecoration(
                  labelText: 'نص شاشة القفل الآمن',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'يمكن استخدام {{title}} و{{body}} وأسماء حقول الحدث مثل {{employee_name}}.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (save == true) {
      await _api.updateTemplate(type, {
        'locale': 'ar',
        'title_template': title.text.trim(),
        'body_template': body.text.trim(),
        'lock_screen_template':
            lock.text.trim().isEmpty ? null : lock.text.trim(),
        'is_active': true,
      });
      templates.assignAll(await _api.fetchTemplates());
    }
    title.dispose();
    body.dispose();
    lock.dispose();
  }

  Future<void> pickAndUploadSound() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['wav', 'mp3', 'caf'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    final nameController = TextEditingController(
      text: result!.files.single.name.replaceFirst(RegExp(r'\.[^.]+$'), ''),
    );
    final name = await Get.dialog<String>(
      AlertDialog(
        title: const Text('رفع صوت جديد'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'اسم الصوت'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Get.back(result: nameController.text.trim()),
            child: const Text('رفع'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    isLoading.value = true;
    try {
      await _api.uploadSound(name: name, filePath: path);
      sounds.assignAll(await _api.fetchSounds());
      Get.snackbar('تم', 'تم رفع الصوت إلى المكتبة');
    } catch (_) {
      Get.snackbar('خطأ', 'تعذر رفع الصوت. تأكد من الصيغة والحجم.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> preview(Map<String, dynamic> sound) async {
    if (sound['source'] != 'uploaded') {
      Get.snackbar(
          'صوت جاهز', 'يتم تشغيل هذا الصوت من موارد التطبيق عند وصول الإشعار.');
      return;
    }
    try {
      final bytes = await _api.downloadSound(int.parse(sound['id'].toString()));
      await _player.stop();
      await _player.play(BytesSource(bytes));
    } catch (_) {
      Get.snackbar('خطأ', 'تعذر تشغيل معاينة الصوت');
    }
  }

  Future<void> toggleSound(Map<String, dynamic> sound) async {
    if (sound['source'] == 'bundled') return;
    await _api.updateSound(
      int.parse(sound['id'].toString()),
      {'is_active': sound['is_active'] != true},
    );
    sounds.assignAll(await _api.fetchSounds());
  }

  Future<void> deleteSound(Map<String, dynamic> sound) async {
    try {
      await _api.deleteSound(int.parse(sound['id'].toString()));
      sounds.assignAll(await _api.fetchSounds());
    } catch (_) {
      Get.snackbar(
          'لا يمكن الحذف', 'استبدل الصوت في السياسات التي تستخدمه أولاً.');
    }
  }

  Future<void> _reloadCatalog() async {
    catalog.assignAll(await _api.fetchCatalog());
  }

  static String _shortTime(dynamic value) {
    final raw = value?.toString() ?? '';
    return raw.length >= 5 ? raw.substring(0, 5) : raw;
  }
}
