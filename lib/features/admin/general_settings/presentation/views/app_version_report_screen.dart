import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/app_settings_service.dart';

class AppVersionReportScreen extends StatefulWidget {
  const AppVersionReportScreen({Key? key}) : super(key: key);

  @override
  State<AppVersionReportScreen> createState() => _AppVersionReportScreenState();
}

class _AppVersionReportScreenState extends State<AppVersionReportScreen> {
  AppVersionReport? _report;
  bool _loading = true;

  static const _platforms = ['android', 'ios', 'windows'];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);
    final report = await AppSettingsService.instance.fetchAppVersionReport();
    if (!mounted) return;
    setState(() {
      _report = report;
      _loading = false;
    });
    if (report == null) {
      Get.snackbar(
        'error'.tr,
        'settingsUpdateFailed'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFF5F5F5);
    final report = _report;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: const CustomAppBar(
        title: 'appVersionReportTitle',
        action: false,
        backgroundColor: pageBg,
      ),
      body: RefreshIndicator(
        onRefresh: _loadReport,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          children: [
            _ReportHeaderCard(
              loading: _loading,
              summary: report?.summary ?? const [],
              devices: report?.devices ?? const [],
              onRefresh: _loadReport,
            ),
            SizedBox(height: 12.h),
            if (_loading)
              Padding(
                padding: EdgeInsets.only(top: 48.h),
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (report == null || report.summary.isEmpty)
              const _EmptyReportCard()
            else
              ..._platforms.map(
                (platform) => _PlatformVersionsSection(
                  platform: platform,
                  summary: _versionsForPlatform(report.summary, platform),
                  devices: report.devices,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<AppVersionSummaryRow> _versionsForPlatform(
    List<AppVersionSummaryRow> rows,
    String platform,
  ) {
    final filtered = rows.where((row) => row.platform == platform).toList()
      ..sort((a, b) => b.build.compareTo(a.build));
    return filtered.take(3).toList();
  }
}

class _ReportHeaderCard extends StatelessWidget {
  const _ReportHeaderCard({
    required this.loading,
    required this.summary,
    required this.devices,
    required this.onRefresh,
  });

  final bool loading;
  final List<AppVersionSummaryRow> summary;
  final List<AppVersionDeviceRow> devices;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final platforms = summary.map((row) => row.platform).toSet().length;
    final users = devices
        .map((row) => row.userName)
        .where((e) => e.isNotEmpty)
        .toSet()
        .length;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 46.w,
            height: 46.w,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.query_stats_outlined,
              color: const Color(0xFF2563EB),
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'appVersionReportLatestOnly'.tr,
                  style: TextStyle(
                    color: const Color(0xFF111827),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  loading
                      ? 'loading'.tr
                      : '$platforms ${'appVersionReportPlatforms'.tr} / ${summary.length} ${'appVersionReportVersions'.tr} / $users ${'appVersionReportUsers'.tr}',
                  style: TextStyle(
                    color: const Color(0xFF6B7280),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'refresh'.tr,
            onPressed: loading ? null : onRefresh,
            icon: const Icon(Icons.refresh),
            color: const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }
}

class _PlatformVersionsSection extends StatelessWidget {
  const _PlatformVersionsSection({
    required this.platform,
    required this.summary,
    required this.devices,
  });

  final String platform;
  final List<AppVersionSummaryRow> summary;
  final List<AppVersionDeviceRow> devices;

  @override
  Widget build(BuildContext context) {
    if (summary.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(_platformIcon(platform), color: _platformColor(platform)),
              SizedBox(width: 8.w),
              Text(
                _platformTitle(platform),
                style: TextStyle(
                  color: const Color(0xFF111827),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '(${summary.length})',
                style: TextStyle(
                  color: const Color(0xFF6B7280),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ...summary.map(
            (row) => _VersionExpansionCard(
              row: row,
              devices: _devicesForVersion(row),
            ),
          ),
        ],
      ),
    );
  }

  List<AppVersionDeviceRow> _devicesForVersion(AppVersionSummaryRow row) {
    final matched = devices
        .where(
          (device) =>
              device.platform == row.platform &&
              device.version == row.version &&
              device.build == row.build,
        )
        .toList()
      ..sort((a, b) => b.lastSeenAt.compareTo(a.lastSeenAt));
    return matched;
  }
}

class _VersionExpansionCard extends StatelessWidget {
  const _VersionExpansionCard({
    required this.row,
    required this.devices,
  });

  final AppVersionSummaryRow row;
  final List<AppVersionDeviceRow> devices;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
          childrenPadding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
          leading: CircleAvatar(
            radius: 18.r,
            backgroundColor: const Color(0xFFF3F4F6),
            child: Text(
              row.build.toString(),
              style: TextStyle(
                color: const Color(0xFF111827),
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          title: Text(
            '${row.version}+${row.build}',
            style: TextStyle(
              color: const Color(0xFF111827),
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            '${row.usersCount} ${'appVersionReportUsers'.tr} / ${row.devicesCount} ${'appVersionReportDevicesShort'.tr}',
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: 12.sp,
            ),
          ),
          trailing: SizedBox(
            width: 116.w,
            child: Text(
              row.lastSeenAt.isEmpty ? '-' : row.lastSeenAt,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: const Color(0xFF6B7280),
                fontSize: 11.sp,
              ),
            ),
          ),
          children: [
            if (devices.isEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'appVersionReportEmpty'.tr,
                  style: TextStyle(
                    color: const Color(0xFF6B7280),
                    fontSize: 12.sp,
                  ),
                ),
              )
            else
              ...devices.map((row) => _DeviceRowTile(row: row)),
          ],
        ),
      ),
    );
  }
}

class _DeviceRowTile extends StatelessWidget {
  const _DeviceRowTile({required this.row});

  final AppVersionDeviceRow row;

  @override
  Widget build(BuildContext context) {
    final userName = row.userName.trim().isEmpty ? '-' : row.userName.trim();
    final deviceName =
        row.deviceName.trim().isEmpty ? '-' : row.deviceName.trim();
    final lastSeen = row.lastSeenAt.trim().isEmpty ? '-' : row.lastSeenAt;

    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            color: const Color(0xFF2563EB),
            size: 20.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF111827),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  '${row.userEmail.isEmpty ? deviceName : row.userEmail} - $deviceName',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF6B7280),
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          SizedBox(
            width: 116.w,
            child: Text(
              lastSeen,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: const Color(0xFF374151),
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyReportCard extends StatelessWidget {
  const _EmptyReportCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.devices_other_outlined,
            color: const Color(0xFF9CA3AF),
            size: 38.sp,
          ),
          SizedBox(height: 10.h),
          Text(
            'appVersionReportEmpty'.tr,
            style: TextStyle(
              color: const Color(0xFF374151),
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _platformIcon(String platform) {
  if (platform == 'ios') return Icons.phone_iphone;
  if (platform == 'windows') return Icons.desktop_windows_outlined;
  return Icons.android;
}

Color _platformColor(String platform) {
  if (platform == 'ios') return const Color(0xFF111827);
  if (platform == 'windows') return const Color(0xFF2563EB);
  return const Color(0xFF059669);
}

String _platformTitle(String platform) {
  if (platform == 'ios') return 'appPlatformIos'.tr;
  if (platform == 'windows') return 'appPlatformWindows'.tr;
  return 'appPlatformAndroid'.tr;
}
