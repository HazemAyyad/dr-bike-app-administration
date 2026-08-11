import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/databases/api/dio_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';

class EmployeeWifiPresenceHistoryScreen extends StatefulWidget {
  const EmployeeWifiPresenceHistoryScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeWifiPresenceHistoryScreen> createState() =>
      _EmployeeWifiPresenceHistoryScreenState();
}

class _EmployeeWifiPresenceHistoryScreenState
    extends State<EmployeeWifiPresenceHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<_CurrentWifiRow> _current = const [];
  List<_WifiLogRow> _logs = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await Get.find<DioConsumer>().get(
        EndPoints.employeeWifiPresenceHistory,
        queryParameters: {'limit': 150},
      );
      final data = response.data;
      if (data is! Map || data['status']?.toString() != 'success') {
        throw Exception(data is Map ? data['message'] : null);
      }
      final currentRaw = data['current'];
      final logsRaw = data['logs'];
      setState(() {
        _current = currentRaw is List
            ? currentRaw
                .whereType<Map>()
                .map((e) => _CurrentWifiRow.fromJson(
                      Map<String, dynamic>.from(e),
                    ))
                .toList()
            : const [];
        _logs = logsRaw is List
            ? logsRaw
                .whereType<Map>()
                .map((e) => _WifiLogRow.fromJson(
                      Map<String, dynamic>.from(e),
                    ))
                .toList()
            : const [];
      });
    } catch (_) {
      setState(() => _error = 'تعذر تحميل سجل الشبكات');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final greenCount = _current.where((row) => row.state == 'green').length;
    final orangeCount = _current.where((row) => row.state == 'orange').length;
    final redCount = _current.where((row) => row.state == 'red').length;
    return Scaffold(
      appBar: const CustomAppBar(title: 'سجل شبكات الموظفين'),
      backgroundColor:
          isDark ? AppColors.customGreyColor : const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    padding: EdgeInsets.all(24.w),
                    children: [
                      SizedBox(height: 120.h),
                      Center(child: Text(_error!)),
                    ],
                  )
                : ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
                    children: [
                      _WifiSummaryBar(
                        green: greenCount,
                        orange: orangeCount,
                        red: redCount,
                      ),
                      SizedBox(height: 14.h),
                      _SectionHeader(
                          title: 'الحالي الآن', count: _current.length),
                      SizedBox(height: 10.h),
                      if (_current.isEmpty)
                        const _EmptyBox(text: 'لا توجد بيانات حالية')
                      else
                        ..._current.map((row) => _CurrentWifiTile(row: row)),
                      SizedBox(height: 18.h),
                      _SectionHeader(title: 'سجل الاتصال', count: _logs.length),
                      SizedBox(height: 10.h),
                      if (_logs.isEmpty)
                        const _EmptyBox(text: 'لا يوجد سجل شبكات بعد')
                      else
                        ..._logs.map((row) => _WifiLogTile(row: row)),
                    ],
                  ),
      ),
    );
  }
}

class _WifiSummaryBar extends StatelessWidget {
  const _WifiSummaryBar({
    required this.green,
    required this.orange,
    required this.red,
  });

  final int green;
  final int orange;
  final int red;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryChip(
            label: 'مسموحة',
            value: green,
            color: _stateColor('green'),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _SummaryChip(
            label: 'شبكة أخرى',
            value: orange,
            color: _stateColor('orange'),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _SummaryChip(
            label: 'بدون إنترنت',
            value: red,
            color: _stateColor('red'),
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.customGreyColor : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.operationalNavy,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count سجل',
            style: TextStyle(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white70 : AppColors.secondaryColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _CurrentWifiTile extends StatelessWidget {
  const _CurrentWifiTile({required this.row});

  final _CurrentWifiRow row;

  @override
  Widget build(BuildContext context) {
    return _PresenceTile(
      employeeName: row.employeeName,
      networkName: row.networkName,
      state: row.state,
      statusLabel: row.statusLabel,
      connectionType: row.connectionType,
      trailingTop: _formatTime(row.updatedAt),
      trailingBottom: 'آخر تحديث',
    );
  }
}

class _WifiLogTile extends StatelessWidget {
  const _WifiLogTile({required this.row});

  final _WifiLogRow row;

  @override
  Widget build(BuildContext context) {
    return _PresenceTile(
      employeeName: row.employeeName,
      networkName: row.networkName,
      state: row.state,
      statusLabel: row.statusLabel,
      connectionType: row.connectionType,
      trailingTop:
          '${_formatShortDate(row.startedAt)} - ${row.endedAt == null ? 'الآن' : _formatShortDate(row.endedAt)}',
      trailingBottom: _formatDuration(row.durationSeconds),
    );
  }
}

class _PresenceTile extends StatelessWidget {
  const _PresenceTile({
    required this.employeeName,
    required this.networkName,
    required this.state,
    required this.statusLabel,
    required this.connectionType,
    required this.trailingTop,
    required this.trailingBottom,
  });

  final String employeeName;
  final String networkName;
  final String state;
  final String statusLabel;
  final String? connectionType;
  final String trailingTop;
  final String trailingBottom;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final color = _stateColor(state);
    return Container(
      margin: EdgeInsets.only(bottom: 7.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.customGreyColor : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              _connectionIcon(connectionType),
              size: 19.sp,
              color: color,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employeeName.isEmpty ? 'موظف' : employeeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.operationalNavy,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  networkName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  trailingTop,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF374151),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  '$statusLabel | $trailingBottom',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: isDark ? Colors.white70 : const Color(0xFF6B7280),
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

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: ThemeService.isDark.value
              ? Colors.white12
              : const Color(0xFFE5E7EB),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CurrentWifiRow {
  const _CurrentWifiRow({
    required this.employeeName,
    required this.state,
    this.ssid,
    this.displayName,
    this.label,
    this.connectionType,
    this.updatedAt,
  });

  factory _CurrentWifiRow.fromJson(Map<String, dynamic> json) {
    final wifi = json['wifi_status'] is Map
        ? Map<String, dynamic>.from(json['wifi_status'] as Map)
        : <String, dynamic>{};
    return _CurrentWifiRow(
      employeeName: json['employee_name']?.toString() ?? '',
      state: wifi['state']?.toString() ?? 'red',
      ssid: wifi['ssid']?.toString(),
      displayName: wifi['display_name']?.toString(),
      label: wifi['label']?.toString(),
      connectionType: wifi['connection_type']?.toString(),
      updatedAt: _parseDate(wifi['updated_at']),
    );
  }

  final String employeeName;
  final String state;
  final String? ssid;
  final String? displayName;
  final String? label;
  final String? connectionType;
  final DateTime? updatedAt;

  String get statusLabel => label ?? _stateLabel(state);
  String get networkName => _networkName(
        displayName: displayName,
        ssid: ssid,
        connectionType: connectionType,
        state: state,
      );
}

class _WifiLogRow {
  const _WifiLogRow({
    required this.employeeName,
    required this.state,
    required this.durationSeconds,
    this.ssid,
    this.displayName,
    this.label,
    this.connectionType,
    this.startedAt,
    this.endedAt,
  });

  factory _WifiLogRow.fromJson(Map<String, dynamic> json) {
    return _WifiLogRow(
      employeeName: json['employee_name']?.toString() ?? '',
      state: json['state']?.toString() ?? 'red',
      ssid: json['ssid']?.toString(),
      displayName: json['display_name']?.toString(),
      label: json['label']?.toString(),
      connectionType: json['connection_type']?.toString(),
      startedAt: _parseDate(json['started_at']),
      endedAt: _parseDate(json['ended_at']),
      durationSeconds: int.tryParse(
            json['duration_seconds']?.toString() ?? '',
          ) ??
          0,
    );
  }

  final String employeeName;
  final String state;
  final String? ssid;
  final String? displayName;
  final String? label;
  final String? connectionType;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int durationSeconds;

  String get statusLabel => label ?? _stateLabel(state);
  String get networkName => _networkName(
        displayName: displayName,
        ssid: ssid,
        connectionType: connectionType,
        state: state,
      );
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}

String _formatShortDate(DateTime? date) {
  if (date == null) return 'لا يوجد';
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}

String _formatTime(DateTime? date) {
  if (date == null) return 'لا يوجد';
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatDuration(int seconds) {
  final duration = Duration(seconds: seconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0) return '$hours ساعة و $minutes دقيقة';
  if (minutes > 0) return '$minutes دقيقة';
  return 'أقل من دقيقة';
}

String _networkName({
  required String? displayName,
  required String? ssid,
  required String? connectionType,
  required String state,
}) {
  final display = displayName?.trim();
  if (display != null && display.isNotEmpty) return display;
  final rawSsid = ssid?.trim();
  if (rawSsid != null && rawSsid.isNotEmpty) return rawSsid;
  if (connectionType == 'mobile') return 'بيانات الهاتف';
  if (state == 'red') return 'بدون إنترنت';
  return 'شبكة غير معروفة';
}

IconData _connectionIcon(String? type) {
  switch (type) {
    case 'mobile':
      return Icons.signal_cellular_alt_rounded;
    case 'wifi':
      return Icons.wifi_rounded;
    default:
      return Icons.wifi_off_rounded;
  }
}

Color _stateColor(String state) {
  switch (state) {
    case 'green':
      return const Color(0xFF16A34A);
    case 'orange':
      return const Color(0xFFF59E0B);
    default:
      return const Color(0xFFDC2626);
  }
}

String _stateLabel(String state) {
  switch (state) {
    case 'green':
      return 'شبكة مسموحة';
    case 'orange':
      return 'شبكة أخرى';
    default:
      return 'بدون إنترنت';
  }
}
