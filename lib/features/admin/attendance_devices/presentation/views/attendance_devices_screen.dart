import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/databases/api/dio_consumer.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';

class AttendanceDevicesScreen extends StatefulWidget {
  const AttendanceDevicesScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceDevicesScreen> createState() => _AttendanceDevicesScreenState();
}

class _AttendanceDevicesScreenState extends State<AttendanceDevicesScreen> {
  final RxBool _loading = true.obs;
  final RxList<Map<String, dynamic>> _devices = <Map<String, dynamic>>[].obs;
  final RxString _error = ''.obs;
  final RxInt _busyDeviceId = 0.obs;

  DioConsumer? get _api =>
      Get.isRegistered<DioConsumer>() ? Get.find<DioConsumer>() : null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = _api;
    _error.value = '';
    if (api == null) {
      _loading.value = false;
      _error.value = 'لا يوجد API client';
      return;
    }
    _loading.value = true;
    try {
      final res = await api.get(EndPoints.attendanceDevices);
      final data = res.data;
      if (data is Map && data['status']?.toString() == 'success') {
        final list = data['devices'];
        if (list is List) {
          _devices.assignAll(list.map((e) => Map<String, dynamic>.from(e)));
        } else {
          _devices.clear();
        }
      } else {
        _error.value = (data is Map ? data['message']?.toString() : null) ??
            'فشل تحميل الأجهزة';
      }
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _loading.value = false;
    }
  }

  Future<void> _createDevice(Map<String, dynamic> payload) async {
    final api = _api;
    if (api == null) return;
    await api.post(EndPoints.attendanceDevices, data: payload);
  }

  Future<void> _updateDevice(int id, Map<String, dynamic> payload) async {
    final api = _api;
    if (api == null) return;
    await api.put('admin/attendance-devices/$id', data: payload);
  }

  Future<void> _deleteDevice(int id) async {
    final api = _api;
    if (api == null) return;
    await api.delete('admin/attendance-devices/$id');
  }

  Future<void> _openAddEditSheet({Map<String, dynamic>? device}) async {
    final isEdit = device != null;
    final id = int.tryParse(device?['id']?.toString() ?? '') ?? 0;

    final nameCtrl = TextEditingController(text: device?['name']?.toString() ?? '');
    final modelCtrl = TextEditingController(text: device?['model']?.toString() ?? '');
    final serialCtrl =
        TextEditingController(text: device?['serial_number']?.toString() ?? '');
    final ipCtrl =
        TextEditingController(text: device?['ip_address']?.toString() ?? '');
    final portCtrl = TextEditingController(
      text: (device?['port']?.toString().isNotEmpty == true)
          ? device!['port'].toString()
          : '4370',
    );
    final passCtrl = TextEditingController(
      text: device?['communication_password']?.toString() ?? '',
    );
    bool active = device?['is_active'] == true;
    String syncMode = (device?['sync_mode']?.toString() ?? 'disabled').toLowerCase();
    if (syncMode != 'pull' && syncMode != 'push') syncMode = 'disabled';

    final busy = false.obs;

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 16.w,
                right: 16.w,
                top: 14.h,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 14.h,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isEdit ? 'تعديل جهاز' : 'إضافة جهاز',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ),
                          Obx(() {
                            return TextButton(
                              onPressed: busy.value
                                  ? null
                                  : () async {
                                      final name = nameCtrl.text.trim();
                                      if (name.isEmpty) {
                                        Get.snackbar(
                                          'warning'.tr,
                                          'أدخل اسم الجهاز',
                                          snackPosition: SnackPosition.BOTTOM,
                                        );
                                        return;
                                      }
                                      final port =
                                          int.tryParse(portCtrl.text.trim()) ??
                                              4370;
                                      final payload = <String, dynamic>{
                                        'name': name,
                                        'model': modelCtrl.text.trim().isEmpty
                                            ? null
                                            : modelCtrl.text.trim(),
                                        'serial_number':
                                            serialCtrl.text.trim().isEmpty
                                                ? null
                                                : serialCtrl.text.trim(),
                                        'ip_address': ipCtrl.text.trim().isEmpty
                                            ? null
                                            : ipCtrl.text.trim(),
                                        'port': port,
                                        'communication_password':
                                            passCtrl.text.trim().isEmpty
                                                ? null
                                                : passCtrl.text.trim(),
                                        'is_active': active,
                                        'sync_mode': syncMode,
                                      };
                                      busy.value = true;
                                      try {
                                        if (isEdit && id > 0) {
                                          await _updateDevice(id, payload);
                                        } else {
                                          await _createDevice(payload);
                                        }
                                        if (!ctx.mounted) return;
                                        Navigator.pop(ctx);
                                        Get.snackbar(
                                          'success'.tr,
                                          'settingsUpdated'.tr,
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor:
                                              Colors.green.shade700,
                                          colorText: Colors.white,
                                        );
                                        await _load();
                                      } catch (e) {
                                        Get.snackbar(
                                          'error'.tr,
                                          e.toString(),
                                          snackPosition: SnackPosition.BOTTOM,
                                        );
                                      } finally {
                                        busy.value = false;
                                      }
                                    },
                              child: busy.value
                                  ? SizedBox(
                                      width: 18.w,
                                      height: 18.w,
                                      child: const CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : Text('save'.tr),
                            );
                          }),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      _Field(
                    label: 'الاسم',
                    controller: nameCtrl,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 8.h),
                  _Field(
                    label: 'الموديل (اختياري)',
                    controller: modelCtrl,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 8.h),
                  _Field(
                    label: 'السيريال (اختياري)',
                    controller: serialCtrl,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _Field(
                          label: 'IP',
                          controller: ipCtrl,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _Field(
                          label: 'Port',
                          controller: portCtrl,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  _Field(
                    label: 'كلمة المرور (اختياري)',
                    controller: passCtrl,
                    textInputAction: TextInputAction.done,
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'نشط',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ),
                        Switch(
                          value: active,
                          onChanged: (v) => setSheetState(() => active = v),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: syncMode,
                      items: const [
                        DropdownMenuItem(value: 'disabled', child: Text('Disabled')),
                        DropdownMenuItem(value: 'pull', child: Text('Pull')),
                        DropdownMenuItem(value: 'push', child: Text('Push')),
                      ],
                      onChanged: (v) => setSheetState(() => syncMode = v ?? 'disabled'),
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: 'Sync mode',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  if (isEdit && id > 0) ...[
                    SizedBox(height: 12.h),
                    OutlinedButton.icon(
                      onPressed: busy.value
                          ? null
                          : () async {
                              final ok = await showDialog<bool>(
                                context: ctx,
                                builder: (_) => AlertDialog(
                                  title: Text('confirmDelete'.tr),
                                  content: const Text('هل تريد حذف الجهاز؟'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text('cancel'.tr),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text('delete'.tr),
                                    ),
                                  ],
                                ),
                              );
                              if (ok != true) return;
                              busy.value = true;
                              try {
                                await _deleteDevice(id);
                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);
                                await _load();
                              } catch (e) {
                                Get.snackbar('error'.tr, e.toString(),
                                    snackPosition: SnackPosition.BOTTOM);
                              } finally {
                                busy.value = false;
                              }
                            },
                      icon: const Icon(Icons.delete_outline),
                      label: Text('delete'.tr),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade200),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    modelCtrl.dispose();
    serialCtrl.dispose();
    ipCtrl.dispose();
    portCtrl.dispose();
    passCtrl.dispose();
  }

  Future<void> _testConnection(int id) async {
    final api = _api;
    if (api == null) return;
    _busyDeviceId.value = id;
    try {
      final res = await api.post(EndPoints.attendanceDeviceTestConnection(id));
      final data = res.data;
      final ok = data is Map && data['status']?.toString() == 'success';
      final msg = data is Map ? data['message']?.toString() : null;
      Get.snackbar(
        ok ? 'success'.tr : 'error'.tr,
        msg ?? (ok ? 'تم الاتصال بنجاح' : 'فشل الاتصال'),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
        colorText: Colors.white,
      );
      await _load();
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _busyDeviceId.value = 0;
    }
  }

  Future<void> _syncUsers(int id) async {
    final api = _api;
    if (api == null) return;
    _busyDeviceId.value = id;
    try {
      final res = await api.post(EndPoints.attendanceDeviceSyncUsers(id));
      final data = res.data;
      final ok = data is Map && data['status']?.toString() == 'success';
      final msg = data is Map ? data['message']?.toString() : null;
      Get.snackbar(
        ok ? 'success'.tr : 'error'.tr,
        msg ?? (ok ? 'تمت المزامنة' : 'فشلت المزامنة'),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
        colorText: Colors.white,
      );
      await _load();
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      _busyDeviceId.value = 0;
    }
  }

  Future<void> _syncLogs(int id) async {
    final api = _api;
    if (api == null) return;
    _busyDeviceId.value = id;
    try {
      final res = await api.post(EndPoints.attendanceDeviceSyncLogs(id));
      final data = res.data;
      final ok = data is Map && data['status']?.toString() == 'success';
      final msg = data is Map ? data['message']?.toString() : null;
      Get.snackbar(
        ok ? 'success'.tr : 'error'.tr,
        msg ?? (ok ? 'تمت المزامنة' : 'فشلت المزامنة'),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
        colorText: Colors.white,
      );
      await _load();
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      _busyDeviceId.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final pageBg = isDark ? AppColors.darkColor : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('fingerprintDevices'.tr),
        actions: [
          TextButton.icon(
            onPressed: _loading.value ? null : _load,
            icon: const Icon(Icons.refresh, size: 20),
            label: Text('refresh'.tr),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF111827),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddEditSheet(),
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (_loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_error.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _error.value,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  OutlinedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: Text('tryAgain'.tr),
                  ),
                ],
              ),
            ),
          );
        }
        if (_devices.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Text('noData'.tr),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          itemBuilder: (_, i) {
            final d = _devices[i];
            final id = int.tryParse(d['id']?.toString() ?? '') ?? 0;
            final name = d['name']?.toString() ?? '';
            final ip = d['ip_address']?.toString();
            final port = d['port']?.toString();
            final syncMode = d['sync_mode']?.toString() ?? 'disabled';
            final active = d['is_active'] == true;
            final serial = d['serial_number']?.toString();
            final lastSeen = d['last_seen_at']?.toString();
            final lastSync = d['last_sync_at']?.toString();
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14.r),
                onTap: id > 0 ? () => _openAddEditSheet(device: d) : null,
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'edit'.tr,
                            onPressed: id > 0 ? () => _openAddEditSheet(device: d) : null,
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'fingerprintDeviceUsers'.tr,
                            onPressed: id > 0
                                ? () => Get.toNamed(
                                      AppRoutes.FINGERPRINTDEVICEUSERSSCREEN,
                                      arguments: {'deviceId': id, 'deviceName': name},
                                    )
                                : null,
                            icon: const Icon(Icons.badge_outlined),
                          ),
                          _Badge(
                            text: active ? 'active'.tr : 'notActive'.tr,
                            color: active
                                ? const Color(0xFF059669)
                                : const Color(0xFF6B7280),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        '${ip ?? '—'}:${port ?? '—'} • $syncMode',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      if (serial != null && serial.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          'SN: $serial',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                      SizedBox(height: 6.h),
                      Text(
                        '${'lastSeen'.tr}: ${(lastSeen != null && lastSeen.isNotEmpty) ? lastSeen : 'lastSeenNever'.tr}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: (lastSeen != null && lastSeen.isNotEmpty)
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                      if (lastSync != null && lastSync.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(
                          '${'lastSync'.tr}: $lastSync',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                      SizedBox(height: 10.h),
                      if (syncMode == 'push') ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            'fingerprintPushModeHint'.tr,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF1E40AF),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ] else
                        Obx(() {
                          final busy = _busyDeviceId.value == id;
                          return Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: busy || id <= 0
                                      ? null
                                      : () => _testConnection(id),
                                  icon: busy
                                      ? SizedBox(
                                          width: 16.w,
                                          height: 16.w,
                                          child: const CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Icon(Icons.wifi_tethering_outlined),
                                  label: const Text('اختبار الاتصال'),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: busy || id <= 0
                                      ? null
                                      : () => _syncUsers(id),
                                  icon: const Icon(Icons.people_outline),
                                  label: const Text('مزامنة المستخدمين'),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed:
                                      busy || id <= 0 ? null : () => _syncLogs(id),
                                  icon: const Icon(Icons.receipt_long_outlined),
                                  label: const Text('مزامنة السجلات'),
                                ),
                              ),
                            ],
                          );
                        }),
                    ],
                  ),
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => SizedBox(height: 10.h),
          itemCount: _devices.length,
        ),
        );
      }),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

