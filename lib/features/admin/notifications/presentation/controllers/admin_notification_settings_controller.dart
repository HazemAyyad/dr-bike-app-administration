import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../core/services/admin_notification_settings_api_service.dart';
import '../../../../../core/services/notification_firebase_service.dart';

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
  final audits = <Map<String, dynamic>>[].obs;
  final audienceUsers = <Map<String, dynamic>>[].obs;
  final audienceRoles = <String>[].obs;
  final employeeOptions = <Map<String, dynamic>>[].obs;
  final failedSections = <String>{}.obs;
  final isSendingManual = false.obs;
  final manualAudience = 'all'.obs;
  final selectedEmployeeIds = <int>{}.obs;
  final manualPriority = 'normal'.obs;
  final manualVibration = true.obs;
  final manualPush = true.obs;
  final manualSoundId = RxnInt();
  final employeeSearch = ''.obs;
  final manualTitleController = TextEditingController();
  final manualBodyController = TextEditingController();

  int get activePolicies => catalog.where((row) {
        final policy = row['policy'] as Map?;
        return policy?['is_enabled'] == true;
      }).length;
  int get readySounds => sounds.where((row) => row['is_active'] == true).length;
  int get healthyDevices =>
      devices.where((row) => row['is_active'] == true).length;
  int get failedDeliveries =>
      deliveries.where((row) => row['status'] == 'failed').length;

  List<Map<String, dynamic>> get manualSounds => sounds.where((row) {
        if (row['source'] != 'bundled' || row['is_active'] != true) {
          return false;
        }
        final ios = row['ios_filename']?.toString().toLowerCase() ?? '';
        return ios.isEmpty || ios == 'silent' || !ios.endsWith('.mp3');
      }).toList();

  List<Map<String, dynamic>> get filteredEmployeeOptions {
    final query = employeeSearch.value.trim().toLowerCase();
    if (query.isEmpty) return employeeOptions.toList();
    return employeeOptions.where((row) {
      return '${row['name'] ?? ''} ${row['job_title'] ?? ''} ${row['email'] ?? ''}'
          .toLowerCase()
          .contains(query);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    _player.dispose();
    manualTitleController.dispose();
    manualBodyController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    failedSections.clear();
    await Future.wait([
      _loadSection('الأنواع', _api.fetchCatalog, catalog.assignAll),
      _loadSection('الأصوات', _api.fetchSounds, sounds.assignAll),
      _loadSection('القوالب', _api.fetchTemplates, templates.assignAll),
      _loadSection('الأجهزة', _api.fetchDevices, devices.assignAll),
      _loadSection('التسليم', _api.fetchDeliveries, deliveries.assignAll),
      _loadSection('التدقيق', _api.fetchAudits, audits.assignAll),
      _loadAudience(),
      _loadEmployeeAudience(),
    ]);
    manualSoundId.value ??= int.tryParse(
      '${manualSounds.firstWhereOrNull((row) => row['key'] == 'default')?['id']}',
    );
    isLoading.value = false;
    if (failedSections.isNotEmpty) {
      Get.snackbar(
        'تحميل جزئي',
        'تعذر تحميل: ${failedSections.join('، ')}',
      );
    }
  }

  Future<void> _loadSection(
    String name,
    Future<List<Map<String, dynamic>>> Function() loader,
    void Function(Iterable<Map<String, dynamic>>) assign,
  ) async {
    try {
      assign(await loader());
    } catch (_) {
      failedSections.add(name);
    }
  }

  Future<void> _loadAudience() async {
    try {
      final data = await _api.fetchAudienceOptions();
      audienceUsers.assignAll(
        (data['users'] as List? ?? const [])
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row)),
      );
      audienceRoles.assignAll(
        (data['roles'] as List? ?? const []).map((role) => role.toString()),
      );
    } catch (_) {
      failedSections.add('المستلمون');
    }
  }

  Future<void> _loadEmployeeAudience() async {
    try {
      final data = await _api.fetchEmployeeAudienceOptions();
      employeeOptions.assignAll(
        (data['employees'] as List? ?? const [])
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row)),
      );
    } catch (_) {
      failedSections.add('موظفو الإرسال');
    }
  }

  void toggleEmployee(int id) {
    selectedEmployeeIds.contains(id)
        ? selectedEmployeeIds.remove(id)
        : selectedEmployeeIds.add(id);
  }

  Future<void> sendManualEmployeeNotification() async {
    final title = manualTitleController.text.trim();
    final body = manualBodyController.text.trim();
    final soundId = manualSoundId.value ??
        int.tryParse(
            '${manualSounds.firstWhereOrNull((row) => row['key'] == 'default')?['id']}');
    if (title.isEmpty || body.isEmpty) {
      Get.snackbar('بيانات ناقصة', 'اكتب عنوان الإشعار ومحتواه');
      return;
    }
    if (employeeOptions.isEmpty) {
      Get.snackbar('لا يوجد مستلمون', 'لم يتم العثور على موظفين نشطين');
      return;
    }
    if (manualAudience.value == 'selected' && selectedEmployeeIds.isEmpty) {
      Get.snackbar('حدد المستلمين', 'اختر موظفاً واحداً على الأقل');
      return;
    }
    if (soundId == null) {
      Get.snackbar('الصوت غير جاهز', 'حدّث المركز ثم اختر صوتاً');
      return;
    }

    final recipientCount = manualAudience.value == 'all'
        ? employeeOptions.length
        : selectedEmployeeIds.length;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('تأكيد إرسال الإشعار'),
        content: Text(
          'سيتم حفظ الإشعار في مركز $recipientCount موظف'
          '${manualPush.value ? ' وإرساله كتنبيه Push.' : ' بدون Push.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('مراجعة'),
          ),
          FilledButton.icon(
            onPressed: () => Get.back(result: true),
            icon: const Icon(Icons.send),
            label: const Text('إرسال الآن'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    isSendingManual.value = true;
    try {
      final response = await _api.sendManualEmployeeNotification({
        'audience': manualAudience.value,
        if (manualAudience.value == 'selected')
          'employee_ids': selectedEmployeeIds.toList(),
        'title': title,
        'body': body,
        'sound_id': soundId,
        'priority': manualPriority.value,
        'vibration_enabled': manualVibration.value,
        'push_enabled': manualPush.value,
      });
      final summary =
          Map<String, dynamic>.from(response['summary'] as Map? ?? {});
      manualTitleController.clear();
      manualBodyController.clear();
      selectedEmployeeIds.clear();
      audits.assignAll(await _api.fetchAudits());
      await Get.dialog<void>(
        AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('تم إرسال الإشعار'),
          content: Text(
            'المستلمون: ${summary['created'] ?? 0}\n'
            'Push ناجح: ${summary['push_sent'] ?? 0}\n'
            'محفوظ بدون وصول Push: ${(summary['push_failed'] ?? 0) + (summary['in_app_only'] ?? 0)}',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: Get.back,
              child: const Text('تم'),
            ),
          ],
        ),
      );
    } catch (_) {
      Get.snackbar('تعذر الإرسال', 'راجع البيانات والاتصال ثم حاول مرة أخرى');
    } finally {
      isSendingManual.value = false;
    }
  }

  Future<void> previewManualSound() async {
    final id = manualSoundId.value;
    final sound = manualSounds.firstWhereOrNull(
      (row) => int.tryParse('${row['id']}') == id,
    );
    if (sound != null) await preview(sound);
  }

  Future<void> retryDelivery(Map<String, dynamic> row) async {
    final id = int.tryParse('${row['id']}');
    if (id == null) return;
    busyType.value = 'delivery_$id';
    try {
      await _api.retryDelivery(id);
      deliveries.assignAll(await _api.fetchDeliveries());
      Get.snackbar('تمت إعادة المحاولة', 'تم إرسال الإشعار للجهاز مرة أخرى');
    } catch (_) {
      Get.snackbar('تعذر الإرسال', 'راجع اتصال الجهاز وبيانات Firebase');
    } finally {
      busyType.value = '';
    }
  }

  Future<void> syncCurrentDeviceSounds() async {
    busyType.value = 'sound_sync';
    try {
      await NotificationFirebaseService.instance
          .registerAdminDeviceTokenIfReady(
        source: 'notification_center_manual_sync',
      );
      devices.assignAll(await _api.fetchDevices());
      Get.snackbar('اكتملت المزامنة', 'تم تحديث جاهزية الأصوات على هذا الجهاز');
    } catch (_) {
      Get.snackbar('تعذرت المزامنة', 'تحقق من الاتصال ثم حاول مرة أخرى');
    } finally {
      busyType.value = '';
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
    final selectedUsers = <int>{
      ...((policy['recipient_user_ids'] as List? ?? const [])
          .map((id) => int.tryParse('$id'))
          .whereType<int>()),
    };
    final selectedRoles = <String>{
      ...((policy['recipient_roles'] as List? ?? const [])
          .map((role) => role.toString())),
    };
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
                if (audience == 'selected_users') ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('اختر الأدمن (${selectedUsers.length})'),
                  ),
                  Wrap(
                    spacing: 6,
                    children: audienceUsers.map((user) {
                      final id = int.tryParse('${user['id']}');
                      return FilterChip(
                        label: Text(user['name']?.toString() ?? '#$id'),
                        selected: id != null && selectedUsers.contains(id),
                        onSelected: id == null
                            ? null
                            : (value) => setState(() => value
                                ? selectedUsers.add(id)
                                : selectedUsers.remove(id)),
                      );
                    }).toList(),
                  ),
                ],
                if (audience == 'roles') ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('اختر الأدوار (${selectedRoles.length})'),
                  ),
                  Wrap(
                    spacing: 6,
                    children: audienceRoles
                        .map((role) => FilterChip(
                              label: Text(role),
                              selected: selectedRoles.contains(role),
                              onSelected: (value) => setState(() => value
                                  ? selectedRoles.add(role)
                                  : selectedRoles.remove(role)),
                            ))
                        .toList(),
                  ),
                ],
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
                Get.back(
                  result: {
                    'quiet_hours_start':
                        start.text.trim().isEmpty ? null : start.text.trim(),
                    'quiet_hours_end':
                        end.text.trim().isEmpty ? null : end.text.trim(),
                    'cooldown_seconds': int.tryParse(cooldown.text) ?? 0,
                    'audience': audience,
                    'recipient_user_ids': audience == 'selected_users'
                        ? selectedUsers.toList()
                        : null,
                    'recipient_roles':
                        audience == 'roles' ? selectedRoles.toList() : null,
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
    var category = 'custom';
    int? fallbackId = int.tryParse('${sounds.firstWhereOrNull(
      (row) => row['key'] == 'default',
    )?['id']}');
    final values = await Get.dialog<Map<String, dynamic>>(
      StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('رفع صوت جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم الصوت'),
                  autofocus: true,
                ),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'التصنيف'),
                  items: const [
                    DropdownMenuItem(value: 'custom', child: Text('مخصص')),
                    DropdownMenuItem(value: 'urgent', child: Text('عاجل')),
                    DropdownMenuItem(value: 'sales', child: Text('مبيعات')),
                    DropdownMenuItem(value: 'tasks', child: Text('مهام')),
                  ],
                  onChanged: (value) =>
                      setState(() => category = value ?? category),
                ),
                DropdownButtonFormField<int>(
                  initialValue: fallbackId,
                  decoration:
                      const InputDecoration(labelText: 'الصوت الاحتياطي'),
                  items: sounds
                      .where((row) =>
                          row['source'] == 'bundled' &&
                          row['is_active'] == true)
                      .map((row) => DropdownMenuItem<int>(
                            value: int.tryParse('${row['id']}'),
                            child: Text(row['name']?.toString() ?? ''),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => fallbackId = value),
                ),
                const SizedBox(height: 10),
                const Text(
                  'حتى 2MB و30 ثانية. WAV هو الأفضل لكل الأجهزة؛ MP3 يعمل على Android ويستخدم الاحتياطي على iOS.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('إلغاء')),
            FilledButton(
              onPressed: () => Get.back(result: {
                'name': nameController.text.trim(),
                'category': category,
                'fallback_sound_id': fallbackId,
              }),
              child: const Text('رفع ومزامنة'),
            ),
          ],
        ),
      ),
    );
    final name = values?['name']?.toString() ?? '';
    if (name.isEmpty) return;

    isLoading.value = true;
    try {
      await _api.uploadSound(
        name: name,
        filePath: path,
        category: values?['category']?.toString(),
        fallbackSoundId: values?['fallback_sound_id'] as int?,
      );
      await NotificationFirebaseService.instance
          .registerAdminDeviceTokenIfReady(
        source: 'notification_sound_upload',
      );
      sounds.assignAll(await _api.fetchSounds());
      Get.snackbar('تم', 'تم رفع الصوت وبدأت مزامنته مع هذا الجهاز');
    } catch (_) {
      Get.snackbar('خطأ', 'تعذر رفع الصوت. تأكد من الصيغة والحجم.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> preview(Map<String, dynamic> sound) async {
    try {
      await _player.stop();
      if (sound['source'] == 'uploaded') {
        final bytes =
            await _api.downloadSound(int.parse(sound['id'].toString()));
        await _player.play(BytesSource(bytes));
        return;
      }

      final key = sound['key']?.toString() ?? '';
      if (key == 'silent') {
        Get.snackbar('بدون صوت', 'هذا الخيار يرسل الإشعار بشكل صامت.');
        return;
      }
      if (key == 'default') {
        await SystemSound.play(SystemSoundType.alert);
        return;
      }

      final fileName = sound['ios_filename']?.toString() ?? '';
      if (fileName.isEmpty) {
        throw StateError('Missing bundled sound filename');
      }
      final data = await rootBundle.load(
        'android/app/src/main/res/raw/$fileName',
      );
      await _player.play(BytesSource(data.buffer.asUint8List()));
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
