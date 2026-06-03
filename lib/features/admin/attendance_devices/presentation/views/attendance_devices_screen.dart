import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/databases/api/dio_consumer.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/showtime.dart';
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
    final cardBg = isDark ? const Color(0xFF1F2937) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    final activeCount =
        _devices.where((d) => d['is_active'] == true).length;
    final onlineCount = _devices.where((d) => d['is_online'] == true).length;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: CustomAppBar(
        title: 'fingerprintDevices',
        backgroundColor: pageBg,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'fingerprintActivityLog'.tr,
            onPressed: () => Get.toNamed(
              AppRoutes.FINGERPRINTDEVICELOGSSCREEN,
              arguments: const {'allDevices': true},
            ),
            icon: const Icon(Icons.history_rounded),
          ),
          IconButton(
            tooltip: 'refresh'.tr,
            onPressed: _loading.value ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditSheet(),
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'add'.tr,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
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
                  Icon(Icons.error_outline, size: 40.sp, color: Colors.red.shade400),
                  SizedBox(height: 12.h),
                  Text(_error.value, textAlign: TextAlign.center),
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

        return RefreshIndicator(
          onRefresh: _load,
          child: _devices.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: 80.h),
                    Icon(Icons.devices_other_outlined,
                        size: 56.sp, color: textSecondary),
                    SizedBox(height: 12.h),
                    Center(
                      child: Text('noData'.tr, style: TextStyle(color: textSecondary)),
                    ),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 88.h),
                  children: [
                    Text(
                      'fingerprintDevicesDesc'.tr,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                    if (_devices.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryTile(
                              label: 'active'.tr,
                              value: '$activeCount/${_devices.length}',
                              color: const Color(0xFF2563EB),
                              bg: const Color(0xFFEFF6FF),
                              icon: Icons.check_circle_outline_rounded,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _SummaryTile(
                              label: 'online'.tr,
                              value: '$onlineCount',
                              color: const Color(0xFF059669),
                              bg: const Color(0xFFECFDF5),
                              icon: Icons.wifi_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 14.h),
                    ...List.generate(_devices.length, (i) {
                      final d = _devices[i];
                      final id = int.tryParse(d['id']?.toString() ?? '') ?? 0;
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: _DeviceCard(
                          device: d,
                          deviceId: id,
                          cardBg: cardBg,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          busyDeviceId: _busyDeviceId.value,
                          onEdit: () => _openAddEditSheet(device: d),
                          onUsers: () => Get.toNamed(
                            AppRoutes.FINGERPRINTDEVICEUSERSSCREEN,
                            arguments: {
                              'deviceId': id,
                              'deviceName': d['name']?.toString() ?? '',
                            },
                          ),
                          onLogs: () => Get.toNamed(
                            AppRoutes.FINGERPRINTDEVICELOGSSCREEN,
                            arguments: {
                              'deviceId': id,
                              'deviceName': d['name']?.toString() ?? '',
                            },
                          ),
                          onTest: () => _testConnection(id),
                          onSyncUsers: () => _syncUsers(id),
                          onSyncLogs: () => _syncLogs(id),
                        ),
                      );
                    }),
                  ],
                ),
        );
      }),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final Color bg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.device,
    required this.deviceId,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.busyDeviceId,
    required this.onEdit,
    required this.onUsers,
    required this.onLogs,
    required this.onTest,
    required this.onSyncUsers,
    required this.onSyncLogs,
  });

  final Map<String, dynamic> device;
  final int deviceId;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final int busyDeviceId;
  final VoidCallback onEdit;
  final VoidCallback onUsers;
  final VoidCallback onLogs;
  final VoidCallback onTest;
  final VoidCallback onSyncUsers;
  final VoidCallback onSyncLogs;

  Color _syncModeColor(String mode) {
    switch (mode) {
      case 'push':
        return const Color(0xFF7C3AED);
      case 'pull':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _syncModeLabel(String mode) {
    switch (mode) {
      case 'push':
        return 'fingerprintSyncModePush'.tr;
      case 'pull':
        return 'fingerprintSyncModePull'.tr;
      default:
        return 'fingerprintSyncModeDisabled'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = device['name']?.toString() ?? '';
    final ip = device['ip_address']?.toString();
    final port = device['port']?.toString();
    final syncMode = device['sync_mode']?.toString() ?? 'disabled';
    final active = device['is_active'] == true;
    final serial = device['serial_number']?.toString();
    final lastSeen = device['last_seen_at']?.toString();
    final lastSync = device['last_sync_at']?.toString();
    final isOnline = device['is_online'] == true;
    final usersCount = device['users_count']?.toString() ?? '0';
    final logsCount = device['fingerprint_logs_count']?.toString() ?? '0';
    final busy = busyDeviceId == deviceId;
    final syncColor = _syncModeColor(syncMode);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    Icons.fingerprint_rounded,
                    color: const Color(0xFF7C3AED),
                    size: 26.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? '#$deviceId' : name,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 4.h,
                        children: [
                          _Badge(
                            text: isOnline ? 'online'.tr : 'offline'.tr,
                            color: isOnline
                                ? const Color(0xFF059669)
                                : const Color(0xFF6B7280),
                          ),
                          _Badge(
                            text: active ? 'active'.tr : 'notActive'.tr,
                            color: active
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF9CA3AF),
                          ),
                          _Badge(
                            text: _syncModeLabel(syncMode),
                            color: syncColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'edit'.tr,
                  onPressed: deviceId > 0 ? onEdit : null,
                  icon: Icon(Icons.edit_outlined, color: textSecondary),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 0),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.lan_outlined,
                  label: 'IP / Port',
                  value: '${ip ?? '—'}:${port ?? '—'}',
                  textSecondary: textSecondary,
                ),
                if (serial != null && serial.isNotEmpty)
                  _InfoRow(
                    icon: Icons.tag_outlined,
                    label: 'SN',
                    value: serial,
                    textSecondary: textSecondary,
                  ),
                _InfoRow(
                  icon: Icons.access_time_rounded,
                  label: 'lastSeen'.tr,
                  value: (lastSeen != null && lastSeen.isNotEmpty)
                      ? formatApiDateTime12(lastSeen)
                      : 'lastSeenNever'.tr,
                  valueColor: (lastSeen != null && lastSeen.isNotEmpty)
                      ? const Color(0xFF059669)
                      : const Color(0xFFDC2626),
                  textSecondary: textSecondary,
                ),
                if (lastSync != null && lastSync.isNotEmpty)
                  _InfoRow(
                    icon: Icons.sync_rounded,
                    label: 'lastSync'.tr,
                    value: formatApiDateTime12(lastSync),
                    textSecondary: textSecondary,
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 0),
            child: Row(
              children: [
                Expanded(
                  child: _StatChip(
                    icon: Icons.people_outline_rounded,
                    label: 'usersCount'.tr,
                    value: usersCount,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _StatChip(
                    icon: Icons.receipt_long_outlined,
                    label: 'fingerprintLogsCount'.tr,
                    value: logsCount,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _ActionChip(
                  icon: Icons.badge_outlined,
                  label: 'fingerprintDeviceUsers'.tr,
                  onTap: deviceId > 0 ? onUsers : null,
                ),
                _ActionChip(
                  icon: Icons.history_rounded,
                  label: 'fingerprintActivityLog'.tr,
                  onTap: deviceId > 0 ? onLogs : null,
                ),
              ],
            ),
          ),
          if (syncMode == 'push')
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18.sp, color: const Color(0xFF2563EB)),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'fingerprintPushModeHint'.tr,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF1E40AF),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: busy || deviceId <= 0 ? null : onTest,
                      icon: busy
                          ? SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: const CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_tethering_rounded, size: 18),
                      label: Text('testConnection'.tr),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: busy || deviceId <= 0 ? null : onSyncUsers,
                          icon: const Icon(Icons.people_outline_rounded, size: 18),
                          label: Text('syncUsers'.tr),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: busy || deviceId <= 0 ? null : onSyncLogs,
                          icon: const Icon(Icons.receipt_long_outlined, size: 18),
                          label: Text('syncLogs'.tr),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textSecondary,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color textSecondary;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Icon(icon, size: 15.sp, color: textSecondary),
          SizedBox(width: 8.w),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11.sp, color: textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: valueColor ?? textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: const Color(0xFF6B7280)),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.sp, color: const Color(0xFF9CA3AF)),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16.sp, color: const Color(0xFF374151)),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
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

