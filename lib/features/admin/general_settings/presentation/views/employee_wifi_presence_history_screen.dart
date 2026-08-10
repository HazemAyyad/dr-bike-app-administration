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
                      const _SectionTitle(
                        title: 'الشبكات الحالية',
                        subtitle: 'آخر حالة وصلت من أجهزة الموظفين',
                      ),
                      SizedBox(height: 10.h),
                      if (_current.isEmpty)
                        const _EmptyBox(text: 'لا توجد بيانات حالية')
                      else
                        ..._current.map((row) => _CurrentWifiCard(row: row)),
                      SizedBox(height: 18.h),
                      const _SectionTitle(
                        title: 'سجل الاتصال',
                        subtitle: 'من متى لمتى كان الموظف على كل شبكة',
                      ),
                      SizedBox(height: 10.h),
                      if (_logs.isEmpty)
                        const _EmptyBox(text: 'لا يوجد سجل شبكات بعد')
                      else
                        ..._logs.map((row) => _WifiLogCard(row: row)),
                    ],
                  ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: ThemeService.isDark.value
                ? Colors.white
                : AppColors.operationalNavy,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12.sp,
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor5
                : AppColors.customGreyColor4,
          ),
        ),
      ],
    );
  }
}

class _CurrentWifiCard extends StatelessWidget {
  const _CurrentWifiCard({required this.row});

  final _CurrentWifiRow row;

  @override
  Widget build(BuildContext context) {
    return _PresenceCard(
      name: row.employeeName,
      ssid: row.ssid,
      state: row.state,
      lines: [
        'آخر تحديث: ${_formatDate(row.updatedAt)}',
      ],
    );
  }
}

class _WifiLogCard extends StatelessWidget {
  const _WifiLogCard({required this.row});

  final _WifiLogRow row;

  @override
  Widget build(BuildContext context) {
    return _PresenceCard(
      name: row.employeeName,
      ssid: row.ssid,
      state: row.state,
      lines: [
        'من: ${_formatDate(row.startedAt)}',
        'إلى: ${row.endedAt == null ? 'حالياً' : _formatDate(row.endedAt)}',
        'المدة: ${_formatDuration(row.durationSeconds)}',
      ],
    );
  }
}

class _PresenceCard extends StatelessWidget {
  const _PresenceCard({
    required this.name,
    required this.ssid,
    required this.state,
    required this.lines,
  });

  final String name;
  final String? ssid;
  final String state;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final color = _stateColor(state);
    final label = _stateLabel(state);
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 14.w,
            height: 14.w,
            margin: EdgeInsets.only(top: 4.h),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name.isEmpty ? 'موظف' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  ssid == null || ssid!.trim().isEmpty ? 'بدون شبكة' : ssid!,
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6.h),
                ...lines.map(
                  (line) => Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: Text(
                      line,
                      style: TextStyle(
                        color: ThemeService.isDark.value
                            ? AppColors.customGreyColor5
                            : AppColors.customGreyColor4,
                        fontSize: 11.sp,
                      ),
                    ),
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
      ),
      alignment: Alignment.center,
      child: Text(text),
    );
  }
}

class _CurrentWifiRow {
  const _CurrentWifiRow({
    required this.employeeName,
    required this.state,
    this.ssid,
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
      updatedAt: _parseDate(wifi['updated_at']),
    );
  }

  final String employeeName;
  final String state;
  final String? ssid;
  final DateTime? updatedAt;
}

class _WifiLogRow {
  const _WifiLogRow({
    required this.employeeName,
    required this.state,
    required this.durationSeconds,
    this.ssid,
    this.startedAt,
    this.endedAt,
  });

  factory _WifiLogRow.fromJson(Map<String, dynamic> json) {
    return _WifiLogRow(
      employeeName: json['employee_name']?.toString() ?? '',
      state: json['state']?.toString() ?? 'red',
      ssid: json['ssid']?.toString(),
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
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}

String _formatDate(DateTime? date) {
  if (date == null) return 'لا يوجد';
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.year}-$month-$day $hour:$minute';
}

String _formatDuration(int seconds) {
  final duration = Duration(seconds: seconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0) return '$hours ساعة و $minutes دقيقة';
  if (minutes > 0) return '$minutes دقيقة';
  return 'أقل من دقيقة';
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
