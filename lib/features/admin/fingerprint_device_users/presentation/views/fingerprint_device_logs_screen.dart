import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/databases/api/dio_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';

class FingerprintDeviceLogsScreen extends StatefulWidget {
  const FingerprintDeviceLogsScreen({Key? key}) : super(key: key);

  @override
  State<FingerprintDeviceLogsScreen> createState() =>
      _FingerprintDeviceLogsScreenState();
}

class _FingerprintDeviceLogsScreenState extends State<FingerprintDeviceLogsScreen> {
  final RxBool _loading = true.obs;
  final RxString _error = ''.obs;
  final RxList<Map<String, dynamic>> _days = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _allDaysFromApi = <Map<String, dynamic>>[].obs;
  final RxString _logViewMode = 'attendance'.obs;
  final RxInt _totalScans = 0.obs;
  final RxInt _totalIn = 0.obs;
  final RxInt _totalOut = 0.obs;
  final RxString _rangeFrom = ''.obs;
  final RxString _rangeTo = ''.obs;

  int _deviceId = 0;
  String _deviceName = '';
  bool _allDevices = false;

  DioConsumer? get _api =>
      Get.isRegistered<DioConsumer>() ? Get.find<DioConsumer>() : null;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _deviceId = int.tryParse(args['deviceId']?.toString() ?? '') ?? 0;
    _deviceName = args['deviceName']?.toString() ?? '';
    _allDevices = args['allDevices'] == true || _deviceId <= 0;
    _load();
  }

  bool _isAttendanceViewScan(Map<String, dynamic> scan) {
    final pin = scan['device_user_id']?.toString().trim() ?? '';
    final kind = scan['raw_kind']?.toString().toLowerCase() ?? '';
    final err = scan['processing_error']?.toString().toLowerCase() ?? '';

    if (kind == 'oplog' || kind == 'operlog') return false;
    if (err.contains('operlog_not_attendance')) return false;
    if (RegExp(r'^oplog|^operlog|^user$|^fp$|^raw$', caseSensitive: false).hasMatch(pin)) {
      return false;
    }
    if (RegExp(r'oplog|operlog', caseSensitive: false).hasMatch(pin)) {
      return false;
    }

    return RegExp(r'^[1-9][0-9]{0,7}$').hasMatch(pin);
  }

  bool _passesViewFilter(Map<String, dynamic> scan) {
    if (_logViewMode.value == 'all') return true;
    return _isAttendanceViewScan(scan);
  }

  List<Map<String, dynamic>> _filterDays(List<dynamic> rawDays) {
    final out = <Map<String, dynamic>>[];
    for (final dayRaw in rawDays) {
      if (dayRaw is! Map) continue;
      final day = Map<String, dynamic>.from(dayRaw);
      final scansRaw = day['scans'];
      if (scansRaw is! List) continue;
      final scans = scansRaw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((s) => _passesViewFilter(s))
          .toList();
      if (scans.isEmpty) continue;
      day['scans'] = scans;
      out.add(day);
    }
    return out;
  }

  void _applyViewToDays() {
    final filtered = _filterDays(_allDaysFromApi);
    _days.assignAll(filtered);
    _applyTotals(filtered);
  }

  void _setLogViewMode(String mode) {
    if (_logViewMode.value == mode) return;
    _logViewMode.value = mode;
    _applyViewToDays();
  }

  void _applyTotals(List<Map<String, dynamic>> days) {
    var total = 0;
    var ins = 0;
    var outs = 0;
    for (final day in days) {
      final scans = day['scans'];
      if (scans is! List) continue;
      for (final raw in scans) {
        if (raw is! Map) continue;
        total++;
        final action = raw['action']?.toString().toLowerCase();
        if (action == 'in') {
          ins++;
        } else if (action == 'out') {
          outs++;
        }
      }
    }
    _totalScans.value = total;
    _totalIn.value = ins;
    _totalOut.value = outs;
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
      final Map<String, dynamic> query = {'days': 90, 'limit': 800};
      final dynamic res;
      if (_allDevices) {
        res = await api.get(
          EndPoints.fingerprintActivityLog,
          queryParameters: query,
        );
      } else {
        res = await api.get(
          EndPoints.attendanceDeviceLogs(_deviceId),
          queryParameters: query,
        );
      }

      final data = res.data;
      if (data is Map && data['status']?.toString() == 'success') {
        final list = data['days'];
        if (list is List) {
          _allDaysFromApi.assignAll(
            list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
          );
          _applyViewToDays();
        } else {
          _allDaysFromApi.clear();
          _days.clear();
          _totalScans.value = 0;
          _totalIn.value = 0;
          _totalOut.value = 0;
        }
        _rangeFrom.value = data['range_from']?.toString() ?? '';
        _rangeTo.value = data['range_to']?.toString() ?? '';
        final dev = data['device'];
        if (dev is Map) {
          _deviceName = dev['name']?.toString() ?? _deviceName;
        }
      } else {
        _error.value = (data is Map ? data['message']?.toString() : null) ??
            'فشل تحميل السجلات';
      }
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _loading.value = false;
    }
  }

  String _actionLabel(String? action) {
    switch (action?.toLowerCase()) {
      case 'in':
        return 'fingerprintScanActionIn'.tr;
      case 'out':
        return 'fingerprintScanActionOut'.tr;
      default:
        return '—';
    }
  }

  IconData _actionIcon(String? action) {
    switch (action?.toLowerCase()) {
      case 'in':
        return Icons.login_rounded;
      case 'out':
        return Icons.logout_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _actionColor(String? action) {
    switch (action?.toLowerCase()) {
      case 'in':
        return const Color(0xFF059669);
      case 'out':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _actionBg(String? action) {
    switch (action?.toLowerCase()) {
      case 'in':
        return const Color(0xFFECFDF5);
      case 'out':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Map<String, int> _dayCounts(List<Map<String, dynamic>> scans) {
    var ins = 0;
    var outs = 0;
    for (final s in scans) {
      final action = s['action']?.toString().toLowerCase();
      if (action == 'in') ins++;
      if (action == 'out') outs++;
    }
    return {'in': ins, 'out': outs};
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

    return Scaffold(
      backgroundColor: pageBg,
      appBar: CustomAppBar(
        title: 'fingerprintActivityLog',
        backgroundColor: pageBg,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'refresh'.tr,
          ),
        ],
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_allDevices && _deviceName.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Text(
                        _deviceName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  Text(
                    'fingerprintActivityLogDesc'.tr,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Obx(() => Row(
                        children: [
                          Expanded(
                            child: _ViewModeChip(
                              label: 'fingerprintLogViewAttendance'.tr,
                              selected: _logViewMode.value == 'attendance',
                              onTap: () => _setLogViewMode('attendance'),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _ViewModeChip(
                              label: 'fingerprintLogViewAll'.tr,
                              selected: _logViewMode.value == 'all',
                              onTap: () => _setLogViewMode('all'),
                            ),
                          ),
                        ],
                      )),
                ],
              ),
            ),
            if (_totalScans.value > 0) ...[
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryChip(
                        label: 'fingerprintScanActionIn'.tr,
                        count: _totalIn.value,
                        color: const Color(0xFF059669),
                        bg: const Color(0xFFECFDF5),
                        icon: Icons.login_rounded,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _SummaryChip(
                        label: 'fingerprintScanActionOut'.tr,
                        count: _totalOut.value,
                        color: const Color(0xFFDC2626),
                        bg: const Color(0xFFFEF2F2),
                        icon: Icons.logout_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              if (_rangeFrom.value.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                  child: Text(
                    '${_totalScans.value} ${'scansCountLabel'.tr} • ${_rangeFrom.value} → ${_rangeTo.value}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ),
            ],
            SizedBox(height: 8.h),
            Expanded(
              child: _days.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fingerprint, size: 48.sp, color: textSecondary),
                          SizedBox(height: 8.h),
                          Text('noData'.tr, style: TextStyle(color: textSecondary)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      itemCount: _days.length,
                      itemBuilder: (_, dayIndex) {
                        final day = _days[dayIndex];
                        final date = day['date']?.toString() ?? '';
                        final scansRaw = day['scans'];
                        final scans = scansRaw is List
                            ? scansRaw
                                .map((e) => Map<String, dynamic>.from(e))
                                .toList()
                            : <Map<String, dynamic>>[];
                        final dayCounts = _dayCounts(scans);
                        final dayIn = dayCounts['in'] ?? 0;
                        final dayOut = dayCounts['out'] ?? 0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                top: dayIndex == 0 ? 0 : 16.h,
                                bottom: 10.h,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      formatDayHeader(date),
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                  _MiniStat(
                                    label: 'fingerprintScanActionIn'.tr,
                                    count: dayIn,
                                    color: const Color(0xFF059669),
                                  ),
                                  SizedBox(width: 6.w),
                                  _MiniStat(
                                    label: 'fingerprintScanActionOut'.tr,
                                    count: dayOut,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ],
                              ),
                            ),
                            ...scans.map((scan) => _ScanTile(
                                  scan: scan,
                                  allDevices: _allDevices,
                                  cardBg: cardBg,
                                  borderColor: borderColor,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  actionLabel: _actionLabel,
                                  actionIcon: _actionIcon,
                                  actionColor: _actionColor,
                                  actionBg: _actionBg,
                                )),
                          ],
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }
}

class _ViewModeChip extends StatelessWidget {
  const _ViewModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEEF2FF) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: selected ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: selected ? const Color(0xFF4338CA) : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
    required this.bg,
    required this.icon,
  });

  final String label;
  final int count;
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
        border: Border.all(color: color.withValues(alpha: 0.25)),
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
                  '$count',
                  style: TextStyle(
                    fontSize: 18.sp,
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $count',
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ScanTile extends StatelessWidget {
  const _ScanTile({
    required this.scan,
    required this.allDevices,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.actionLabel,
    required this.actionIcon,
    required this.actionColor,
    required this.actionBg,
  });

  final Map<String, dynamic> scan;
  final bool allDevices;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final String Function(String?) actionLabel;
  final IconData Function(String?) actionIcon;
  final Color Function(String?) actionColor;
  final Color Function(String?) actionBg;

  @override
  Widget build(BuildContext context) {
    final pin = scan['device_user_id']?.toString() ?? '—';
    final emp = scan['employee_name']?.toString();
    final deviceName = scan['device_name']?.toString();
    final deviceAt = scan['device_at']?.toString() ?? scan['scan_time']?.toString();
    final serverAt = scan['server_at']?.toString() ?? scan['server_received_at']?.toString();
    final action = scan['action']?.toString();
    final color = actionColor(action);
    final bg = actionBg(action);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5.w,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadiusDirectional.horizontal(
                  start: Radius.circular(16.r),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58.w,
                      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'deviceTimeShort'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            formatTimeOnly12(deviceAt),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          if (serverAt != null && serverAt.isNotEmpty) ...[
                            SizedBox(height: 4.h),
                            Text(
                              'serverTimeShort'.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 8.sp,
                                fontWeight: FontWeight.w700,
                                color: textSecondary,
                              ),
                            ),
                            Text(
                              formatTimeOnly12(serverAt),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w700,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  emp != null && emp.isNotEmpty ? emp : 'PIN: $pin',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(actionIcon(action), size: 14.sp, color: color),
                                    SizedBox(width: 4.w),
                                    Text(
                                      actionLabel(action),
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w800,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (emp != null && emp.isNotEmpty && pin.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 2.h),
                              child: Text(
                                'PIN: $pin',
                                style: TextStyle(fontSize: 11.sp, color: textSecondary),
                              ),
                            ),
                          if (allDevices && deviceName != null && deviceName.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 2.h),
                              child: Row(
                                children: [
                                  Icon(Icons.devices_other_outlined,
                                      size: 12.sp, color: textSecondary),
                                  SizedBox(width: 4.w),
                                  Expanded(
                                    child: Text(
                                      deviceName,
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
