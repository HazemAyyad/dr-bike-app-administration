import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/databases/api/dio_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../../debts/presentation/binding/debts_binding.dart';
import '../../../employee_tasks/presentation/binding/employee_tasks_binding.dart';
import '../../../maintenance/presentation/binding/maintenance_binding.dart';
import '../../../maintenance/presentation/controllers/maintenance_controller.dart';
import '../../../stock/presentation/utils/open_instant_sale_invoice.dart';
import '../../data/datasources/employee_datasource.dart';
import '../../data/models/employee_activity_log_model.dart';
import '../controllers/employee_section_controller.dart';
import '../../domain/entities/employee_details_entity.dart';
import '../widgets/employee_points_tab.dart';

class EmployeeDetailsScreen extends GetView<EmployeeSectionController> {
  const EmployeeDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextStyle theme = Theme.of(context).textTheme.bodyMedium!;
    final showPointsTab = canViewEmployeesPoints;
    return DefaultTabController(
      length: showPointsTab ? 4 : 3,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'employeeDetails',
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(46.h),
            child: Container(
              color: ThemeService.isDark.value
                  ? AppColors.darkColor
                  : Colors.white,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: EdgeInsets.symmetric(horizontal: 10.w),
                labelColor: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
                unselectedLabelColor: AppColors.customGreyColor5,
                indicatorColor: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
                labelStyle: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(text: 'employeeDetails'.tr),
                  if (showPointsTab) Tab(text: 'pointsAndRewardsTab'.tr),
                  const Tab(text: 'سجل الشبكات'),
                  const Tab(text: 'سجل النشاط'),
                ],
              ),
            ),
          ),
          actions: [
            if (canEditEmployeesBasic)
              TextButton.icon(
                icon: Icon(
                  Icons.edit_calendar_outlined,
                  color: ThemeService.isDark.value
                      ? AppColors.primaryColor
                      : AppColors.secondaryColor,
                  size: 25.sp,
                ),
                onPressed: () {
                  Get.toNamed(
                    AppRoutes.ADDNEWEMPLOYEESCREEN,
                    arguments: {'AddNewEmployeeScreen': 'editEmployee'},
                  );
                },
                label: Text(
                  'edit'.tr,
                  style: theme.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: ThemeService.isDark.value
                        ? AppColors.primaryColor
                        : AppColors.secondaryColor,
                  ),
                ),
              ),
          ],
        ),
        body: Obx(
          () {
            if (controller.employeeService.employeeDetails.value == null) {
              return Center(
                child: Text(
                  'noData'.tr,
                  style: theme.copyWith(
                    color: AppColors.customGreyColor,
                  ),
                ),
              );
            }
            if (controller.isDialogLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final employeeId =
                controller.employeeService.employeeDetails.value!.id;
            final children = <Widget>[
              _EmployeeOverviewTab(
                employee: controller.employeeService.employeeDetails.value!,
                isManualCheckoutLoading:
                    controller.isManualCheckoutLoading.value,
                onManualCheckout: () => controller.manualCheckoutEmployee(
                  context,
                ),
              ),
              if (showPointsTab) EmployeePointsTab(employeeId: employeeId),
              EmployeeWifiPresenceTab(employeeId: employeeId),
              EmployeeActivityLogsTab(employeeId: employeeId),
            ];
            return TabBarView(children: children);
          },
        ),
      ),
    );
  }
}

class _EmployeeOverviewTab extends StatelessWidget {
  const _EmployeeOverviewTab({
    required this.employee,
    required this.isManualCheckoutLoading,
    required this.onManualCheckout,
  });

  final EmployeeDetailsEntity employee;
  final bool isManualCheckoutLoading;
  final VoidCallback onManualCheckout;

  String get _phone => employee.phone.replaceAll(' ', '');
  String get _subPhone => employee.subPhone.replaceAll(' ', '');

  String get _workHoursLabel {
    final hours = int.tryParse(employee.numberOfWorkHours.trim());
    if (hours == null) return '—';
    return hours > 10
        ? '${employee.numberOfWorkHours} ${'hour'.tr}'
        : '${employee.numberOfWorkHours} ${'hours'.tr}';
  }

  String get _workingTimeLabel =>
      '${'from'.tr} ${formatTimeTo12Hour(employee.startWorkTime)} ${'to'.tr} ${formatTimeTo12Hour(employee.endWorkTime)}';

  String get _weeklyDaysOffLabel => employee.weeklyDaysOff.isEmpty
      ? 'noWeeklyDaysOff'.tr
      : employee.weeklyDaysOff
          .map((d) => ('day_${d.toLowerCase()}').tr)
          .join('، ');

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final pageBg = isDark ? AppColors.darkColor : const Color(0xFFF4F6FA);

    return ColoredBox(
      color: pageBg,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 28.h),
        children: [
          _EmployeeHeaderCard(
            employee: employee,
            phone: _phone,
            subPhone: _subPhone,
            workHoursLabel: _workHoursLabel,
            workingTimeLabel: _workingTimeLabel,
            weeklyDaysOffLabel: _weeklyDaysOffLabel,
            onCopyEmail: () => _copyEmail(context, employee.email),
          ),
          if (employee.currentlyInToday && canManageEmployeesAttendance) ...[
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isManualCheckoutLoading ? null : onManualCheckout,
                icon: isManualCheckoutLoading
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded),
                label: Text('manualCheckout'.tr),
              ),
            ),
          ],
          SizedBox(height: 12.h),
          _ImageGallerySection(
            title: 'documentsImages'.tr,
            images: employee.documentImg,
          ),
        ],
      ),
    );
  }

  Future<void> _copyEmail(BuildContext context, String email) async {
    await Clipboard.setData(ClipboardData(text: email));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${'copied'.tr}: $email'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _EmployeeHeaderCard extends StatelessWidget {
  const _EmployeeHeaderCard({
    required this.employee,
    required this.phone,
    required this.subPhone,
    required this.workHoursLabel,
    required this.workingTimeLabel,
    required this.weeklyDaysOffLabel,
    required this.onCopyEmail,
  });

  final EmployeeDetailsEntity employee;
  final String phone;
  final String subPhone;
  final String workHoursLabel;
  final String workingTimeLabel;
  final String weeklyDaysOffLabel;
  final VoidCallback onCopyEmail;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final bg = isDark ? AppColors.customGreyColor4 : Colors.white;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EmployeeAvatar(employee: employee),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: titleColor,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      employee.email.isEmpty ? '—' : employee.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.sp, color: subColor),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 6.h,
                      children: [
                        _MetricChip(
                          icon: Icons.copy_rounded,
                          label: 'copy'.tr,
                          color: AppColors.secondaryColor,
                          onTap: onCopyEmail,
                        ),
                        if (canViewEmployeesPermissions)
                          _MetricChip(
                            icon: Icons.admin_panel_settings_outlined,
                            label: 'permissions'.tr,
                            color: AppColors.primaryColor,
                            onTap: () => _showPermissionsDialog(
                              context,
                              employee.permissions,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _CompactInfoChip(
                icon: Icons.phone_outlined,
                label: 'phoneNumber'.tr,
                value: phone.isEmpty ? '—' : phone,
              ),
              _CompactInfoChip(
                icon: Icons.phone_android_outlined,
                label: 'alternatePhone'.tr,
                value: subPhone.isEmpty ? '—' : subPhone,
              ),
              _CompactInfoChip(
                icon: Icons.timelapse_outlined,
                label: 'workHoursOfDay'.tr,
                value: workHoursLabel,
              ),
              _CompactInfoChip(
                icon: Icons.access_time_outlined,
                label: 'regularWorkingHours'.tr,
                value: workingTimeLabel,
              ),
              _CompactInfoChip(
                icon: Icons.event_busy_outlined,
                label: 'weeklyDaysOffTitle'.tr,
                value: weeklyDaysOffLabel,
              ),
              _CompactInfoChip(
                icon: Icons.payments_outlined,
                label: 'hourlyRate'.tr,
                value: '${employee.hourWorkPrice} ${'currency'.tr}',
              ),
              _CompactInfoChip(
                icon: Icons.more_time_outlined,
                label: 'overTimeRate'.tr,
                value: '${employee.overtimeWorkPrice} ${'currency'.tr}',
              ),
            ],
          ),
          SizedBox(height: 10.h),
          _FingerprintCompactRow(
            enabled: employee.fingerprintEnabled,
            deviceUserId: employee.deviceUserId,
            lastScan: employee.lastFingerprintScanAt,
            lastAttendance: employee.lastFingerprintAttendanceAt,
          ),
        ],
      ),
    );
  }

  void _showPermissionsDialog(
    BuildContext context,
    List<PermissionEntity> permissions,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final isDark = ThemeService.isDark.value;
        return AlertDialog(
          title: Text('permissions'.tr),
          content: SizedBox(
            width: double.maxFinite,
            child: permissions.isEmpty
                ? Text('noData'.tr)
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 7.w,
                      runSpacing: 7.h,
                      children: permissions
                          .map(
                            (permission) => _PermissionChip(
                              label: permission.permissionName,
                            ),
                          )
                          .toList(),
                    ),
                  ),
          ),
          backgroundColor: isDark ? AppColors.customGreyColor4 : Colors.white,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('close'.tr),
            ),
          ],
        );
      },
    );
  }
}

class _CompactInfoChip extends StatelessWidget {
  const _CompactInfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final labelColor = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final valueColor = isDark ? Colors.white : const Color(0xFF111827);

    return Container(
      constraints: BoxConstraints(minWidth: 138.w, maxWidth: 230.w),
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: AppColors.primaryColor),
          SizedBox(width: 7.w),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                  ),
                ),
                Text(
                  value.isEmpty ? '—' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                    height: 1.2,
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

class _FingerprintCompactRow extends StatelessWidget {
  const _FingerprintCompactRow({
    required this.enabled,
    required this.deviceUserId,
    this.lastScan,
    this.lastAttendance,
  });

  final bool enabled;
  final String? deviceUserId;
  final String? lastScan;
  final String? lastAttendance;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final badgeColor =
        enabled ? const Color(0xFF059669) : const Color(0xFF6B7280);
    final badgeText = enabled ? 'enabledLabel'.tr : 'disabledLabel'.tr;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: badgeColor.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.fingerprint_rounded, color: badgeColor, size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'fingerprintAttendance'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w900,
                          color: titleColor,
                        ),
                      ),
                    ),
                    Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  [
                    '${'deviceUserId'.tr}: ${deviceUserId == null || deviceUserId!.isEmpty ? '—' : deviceUserId}',
                    '${'lastFingerprintScan'.tr}: ${formatApiDateTime12(lastScan)}',
                    '${'lastFingerprintAttendance'.tr}: ${formatApiDateTime12(lastAttendance)}',
                  ].join('  |  '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.sp, color: subColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeAvatar extends StatelessWidget {
  const _EmployeeAvatar({required this.employee});

  final EmployeeDetailsEntity employee;

  @override
  Widget build(BuildContext context) {
    final firstImage =
        employee.employeeImg.isEmpty ? null : employee.employeeImg.first;
    final initials = employee.name.trim().isEmpty
        ? '?'
        : employee.name.trim().characters.first;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        width: 64.w,
        height: 64.w,
        color: AppColors.primaryColor.withValues(alpha: 0.12),
        alignment: Alignment.center,
        child: firstImage == null
            ? Text(
                initials,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryColor,
                ),
              )
            : CachedNetworkImage(
                imageUrl: firstImage,
                width: 64.w,
                height: 64.w,
                fit: BoxFit.cover,
                cacheManager: _employeeImageCacheManager(),
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.person_outline),
              ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15.sp, color: color),
            SizedBox(width: 5.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final bg = isDark ? AppColors.customGreyColor4 : Colors.white;
    final border = isDark ? Colors.white12 : const Color(0xFFE5E7EB);
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18.sp, color: AppColors.primaryColor),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ...children,
        ],
      ),
    );
  }
}

class _ImageGallerySection extends StatelessWidget {
  const _ImageGallerySection({
    required this.title,
    required this.images,
  });

  final String title;
  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: title,
      icon: Icons.image_outlined,
      children: [
        if (images.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Text(
              'noData'.tr,
              style: TextStyle(
                fontSize: 12.sp,
                color: ThemeService.isDark.value
                    ? Colors.white70
                    : const Color(0xFF6B7280),
              ),
            ),
          )
        else
          SizedBox(
            height: 104.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => SizedBox(width: 10.w),
              itemBuilder: (context, index) {
                return _ImageThumb(imageUrl: images[index]);
              },
            ),
          ),
      ],
    );
  }
}

class _ImageThumb extends StatelessWidget {
  const _ImageThumb({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'Dismiss',
          barrierColor: Colors.black.withAlpha(128),
          transitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (context, anim1, anim2) {
            return FullScreenZoomImage(imageUrl: imageUrl);
          },
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          cacheManager: _employeeImageCacheManager(),
          imageBuilder: (context, imageProvider) => Container(
            width: 104.w,
            height: 104.h,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          placeholder: (context, url) => Container(
            width: 104.w,
            height: 104.h,
            alignment: Alignment.center,
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (context, url, error) => Container(
            width: 104.w,
            height: 104.h,
            alignment: Alignment.center,
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
    );
  }
}

class _PermissionChip extends StatelessWidget {
  const _PermissionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.secondaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.secondaryColor.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryColor,
        ),
      ),
    );
  }
}

class EmployeeWifiPresenceTab extends StatefulWidget {
  const EmployeeWifiPresenceTab({Key? key, required this.employeeId})
      : super(key: key);

  final int employeeId;

  @override
  State<EmployeeWifiPresenceTab> createState() =>
      _EmployeeWifiPresenceTabState();
}

class _EmployeeWifiPresenceTabState extends State<EmployeeWifiPresenceTab> {
  bool _loading = true;
  String? _error;
  _EmployeeWifiCurrent? _current;
  List<_EmployeeWifiPeriod> _periods = const [];

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
        queryParameters: {
          'employee_id': widget.employeeId,
          'limit': 80,
        },
      );
      final data = response.data;
      if (data is! Map || data['status']?.toString() != 'success') {
        throw Exception(data is Map ? data['message'] : null);
      }
      final currentRaw = data['current'];
      final logsRaw = data['logs'];
      setState(() {
        _current = currentRaw is List && currentRaw.isNotEmpty
            ? _EmployeeWifiCurrent.fromJson(
                Map<String, dynamic>.from(currentRaw.first as Map),
              )
            : null;
        _periods = logsRaw is List
            ? logsRaw
                .whereType<Map>()
                .map((e) => _EmployeeWifiPeriod.fromJson(
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
    final bg = isDark ? AppColors.darkColor : const Color(0xFFF4F6FA);
    return ColoredBox(
      color: bg,
      child: RefreshIndicator(
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
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 28.h),
                    children: [
                      _WifiCurrentCard(current: _current),
                      SizedBox(height: 12.h),
                      Text(
                        'فترات الاتصال',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w900,
                          color:
                              isDark ? Colors.white : AppColors.operationalNavy,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      if (_periods.isEmpty)
                        const _WifiEmptyCard(text: 'لا يوجد سجل شبكات بعد')
                      else
                        ..._periods.map((period) {
                          return _WifiPeriodTile(period: period);
                        }),
                    ],
                  ),
      ),
    );
  }
}

class _WifiCurrentCard extends StatelessWidget {
  const _WifiCurrentCard({required this.current});

  final _EmployeeWifiCurrent? current;

  @override
  Widget build(BuildContext context) {
    final c = current;
    if (c == null) {
      return const _WifiEmptyCard(text: 'لا توجد حالة حالية');
    }
    return _WifiPresenceBox(
      title: 'الحالة الحالية',
      displayName: c.displayName,
      state: c.state,
      label: c.label,
      icon: _connectionIcon(c.connectionType),
      lines: [
        'آخر تحديث: ${_formatWifiDate(c.updatedAt)}',
      ],
    );
  }
}

class _WifiPeriodTile extends StatelessWidget {
  const _WifiPeriodTile({required this.period});

  final _EmployeeWifiPeriod period;

  @override
  Widget build(BuildContext context) {
    return _WifiPresenceBox(
      title: period.displayName,
      displayName: period.label,
      state: period.state,
      label: _formatWifiDuration(period.durationSeconds),
      icon: _connectionIcon(period.connectionType),
      lines: [
        'من: ${_formatWifiDate(period.startedAt)}',
        'إلى: ${period.endedAt == null ? 'حالياً' : _formatWifiDate(period.endedAt)}',
      ],
    );
  }
}

class _WifiPresenceBox extends StatelessWidget {
  const _WifiPresenceBox({
    required this.title,
    required this.displayName,
    required this.state,
    required this.label,
    required this.icon,
    required this.lines,
  });

  final String title;
  final String displayName;
  final String state;
  final String label;
  final IconData icon;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final color = _wifiStateColor(state);
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.customGreyColor4 : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 20.sp, color: color),
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
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                SizedBox(height: 6.h),
                ...lines.map(
                  (line) => Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: Text(
                      line,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color:
                            isDark ? Colors.white70 : const Color(0xFF6B7280),
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

class _WifiEmptyCard extends StatelessWidget {
  const _WifiEmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor4
            : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      alignment: Alignment.center,
      child: Text(text),
    );
  }
}

class _EmployeeWifiCurrent {
  const _EmployeeWifiCurrent({
    required this.state,
    required this.displayName,
    required this.label,
    required this.connectionType,
    this.updatedAt,
  });

  factory _EmployeeWifiCurrent.fromJson(Map<String, dynamic> json) {
    final wifi = json['wifi_status'] is Map
        ? Map<String, dynamic>.from(json['wifi_status'] as Map)
        : <String, dynamic>{};
    return _EmployeeWifiCurrent(
      state: wifi['state']?.toString() ?? 'red',
      displayName: _nonEmpty(wifi['display_name']) ?? 'بدون إنترنت',
      label: _nonEmpty(wifi['label']) ?? _wifiStateLabel(wifi['state']),
      connectionType: _nonEmpty(wifi['connection_type']) ?? 'none',
      updatedAt: _parseWifiDate(wifi['updated_at']),
    );
  }

  final String state;
  final String displayName;
  final String label;
  final String connectionType;
  final DateTime? updatedAt;
}

class _EmployeeWifiPeriod {
  const _EmployeeWifiPeriod({
    required this.state,
    required this.displayName,
    required this.label,
    required this.connectionType,
    required this.durationSeconds,
    this.startedAt,
    this.endedAt,
  });

  factory _EmployeeWifiPeriod.fromJson(Map<String, dynamic> json) {
    return _EmployeeWifiPeriod(
      state: json['state']?.toString() ?? 'red',
      displayName: _nonEmpty(json['display_name']) ?? 'بدون إنترنت',
      label: _nonEmpty(json['label']) ?? _wifiStateLabel(json['state']),
      connectionType: _nonEmpty(json['connection_type']) ?? 'none',
      durationSeconds:
          int.tryParse(json['duration_seconds']?.toString() ?? '') ?? 0,
      startedAt: _parseWifiDate(json['started_at']),
      endedAt: _parseWifiDate(json['ended_at']),
    );
  }

  final String state;
  final String displayName;
  final String label;
  final String connectionType;
  final int durationSeconds;
  final DateTime? startedAt;
  final DateTime? endedAt;
}

String? _nonEmpty(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _parseWifiDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}

String _formatWifiDate(DateTime? date) {
  if (date == null) return 'لا يوجد';
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.year}-$month-$day $hour:$minute';
}

String _formatWifiDuration(int seconds) {
  final duration = Duration(seconds: seconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0) return '$hours ساعة و $minutes دقيقة';
  if (minutes > 0) return '$minutes دقيقة';
  return 'أقل من دقيقة';
}

Color _wifiStateColor(String state) {
  switch (state) {
    case 'green':
      return const Color(0xFF16A34A);
    case 'orange':
      return const Color(0xFFF59E0B);
    default:
      return const Color(0xFFDC2626);
  }
}

String _wifiStateLabel(dynamic state) {
  switch (state?.toString()) {
    case 'green':
      return 'شبكة مسموحة';
    case 'orange':
      return 'متصل';
    default:
      return 'بدون إنترنت';
  }
}

IconData _connectionIcon(String type) {
  switch (type) {
    case 'mobile':
      return Icons.signal_cellular_alt_rounded;
    case 'wifi':
      return Icons.wifi_rounded;
    default:
      return Icons.wifi_off_rounded;
  }
}

class EmployeeActivityLogsTab extends StatefulWidget {
  const EmployeeActivityLogsTab({Key? key, required this.employeeId})
      : super(key: key);

  final int employeeId;

  @override
  State<EmployeeActivityLogsTab> createState() =>
      _EmployeeActivityLogsTabState();
}

class _EmployeeActivityLogsTabState extends State<EmployeeActivityLogsTab> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _logs = <EmployeeActivityLogModel>[];
  EmployeeActivitySummary? _summary;
  String _module = 'all';
  int _page = 1;
  int _lastPage = 1;
  bool _loading = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _page = 1;
      });
    } else {
      if (_loadingMore || _page >= _lastPage) return;
      setState(() => _loadingMore = true);
      _page += 1;
    }

    try {
      final result =
          await Get.find<EmployeeDatasource>().getEmployeeActivityLogs(
        employeeId: widget.employeeId,
        module: _module,
        search: _searchController.text,
        page: _page,
      );
      setState(() {
        if (reset) _logs.clear();
        _logs.addAll(result.logs);
        _summary = result.summary;
        _lastPage = result.pagination.lastPage;
      });
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 180) {
      _load(reset: false);
    }
  }

  Future<void> _openNavigation(
    BuildContext context,
    EmployeeActivityNavigation nav,
  ) async {
    switch (nav.type) {
      case 'sales_order':
        Get.toNamed(AppRoutes.SALESORDERDETAILSCREEN, arguments: nav.id);
        return;
      case 'instant_sale':
        await openInstantSaleInvoiceFromStock(
          context: context,
          saleId: nav.id.toString(),
        );
        return;
      case 'maintenance':
        MaintenanceBinding().dependencies();
        final c = Get.find<MaintenanceController>();
        c.clearControllers();
        c.getMaintenancesDetails(maintenanceId: nav.id.toString());
        Get.toNamed(AppRoutes.NEWMAINTENANCESCREEN);
        return;
      case 'debt':
        DebtsBinding().dependencies();
        Get.toNamed(AppRoutes.DEBTSSCREEN);
        return;
      case 'employee_task':
        EmployeeTasksBinding().dependencies();
        Get.toNamed(
          AppRoutes.TASKDETAILS,
          arguments: {'taskId': nav.id.toString()},
        );
        return;
      case 'employee_task_occurrence':
        EmployeeTasksBinding().dependencies();
        Get.toNamed(
          AppRoutes.TASKDETAILS,
          arguments: {'occurrence_id': nav.id.toString()},
        );
        return;
      default:
        Get.snackbar('info'.tr, 'لا يوجد رابط جاهز لهذه الحركة');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final pageBg = isDark ? AppColors.darkColor : const Color(0xFFF4F6FA);

    return ColoredBox(
      color: pageBg,
      child: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 28.h),
          children: [
            _ActivitySummaryRow(summary: _summary),
            SizedBox(height: 10.h),
            _ActivityFilters(
              selected: _module,
              searchController: _searchController,
              onModuleChanged: (value) {
                setState(() => _module = value);
                _load(reset: true);
              },
              onSearch: () => _load(reset: true),
            ),
            SizedBox(height: 10.h),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_logs.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 60.h),
                child: Center(child: Text('noData'.tr)),
              )
            else
              ..._logs.map(
                (log) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: _ActivityTile(
                    log: log,
                    onOpen: log.navigation == null
                        ? null
                        : () => _openNavigation(context, log.navigation!),
                  ),
                ),
              ),
            if (_loadingMore)
              const Padding(
                padding: EdgeInsets.all(14),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActivitySummaryRow extends StatelessWidget {
  const _ActivitySummaryRow({required this.summary});

  final EmployeeActivitySummary? summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return Row(
      children: [
        Expanded(
            child:
                _ActivityStat(title: 'الحركات', value: '${s?.totalLogs ?? 0}')),
        SizedBox(width: 8.w),
        Expanded(
            child: _ActivityStat(
                title: 'المبيعات', value: '${_money(s?.salesAmount ?? 0)} ₪')),
        SizedBox(width: 8.w),
        Expanded(
            child: _ActivityStat(
                title: 'الديون', value: '${_money(s?.debtsAmount ?? 0)} ₪')),
      ],
    );
  }
}

class _ActivityStat extends StatelessWidget {
  const _ActivityStat({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.customGreyColor4 : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
          SizedBox(height: 4.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _ActivityFilters extends StatelessWidget {
  const _ActivityFilters({
    required this.selected,
    required this.searchController,
    required this.onModuleChanged,
    required this.onSearch,
  });

  final String selected;
  final TextEditingController searchController;
  final ValueChanged<String> onModuleChanged;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    const modules = {
      'all': 'الكل',
      'sales': 'مبيعات',
      'debts': 'ديون',
      'maintenance': 'صيانة',
      'tasks': 'مهام',
      'stock': 'مخزون',
    };
    return Column(
      children: [
        TextField(
          controller: searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSearch(),
          decoration: InputDecoration(
            hintText: 'بحث في السجل',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onSearch,
            ),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
            isDense: true,
          ),
        ),
        SizedBox(height: 8.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: modules.entries
                .map(
                  (e) => Padding(
                    padding: EdgeInsetsDirectional.only(end: 6.w),
                    child: FilterChip(
                      label: Text(e.value),
                      selected: selected == e.key,
                      onSelected: (_) => onModuleChanged(e.key),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.log, required this.onOpen});

  final EmployeeActivityLogModel log;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final icon = _activityIcon(log.module);
    final color = _activityColor(log.module);
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.customGreyColor4 : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 19.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900),
                ),
                if (log.description.isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  Text(
                    log.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11.5.sp, color: Colors.grey.shade600),
                  ),
                ],
                SizedBox(height: 6.h),
                Text(
                  [
                    formatApiDateTime12(log.createdAt),
                    if (log.amount != null) '${_money(log.amount!)} ₪',
                  ].join(' • '),
                  style:
                      TextStyle(fontSize: 10.5.sp, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (onOpen != null)
            IconButton(
              tooltip: log.navigation?.label ?? 'فتح',
              icon: const Icon(Icons.open_in_new_outlined),
              onPressed: onOpen,
            ),
        ],
      ),
    );
  }
}

IconData _activityIcon(String module) {
  switch (module) {
    case 'sales':
      return Icons.receipt_long_outlined;
    case 'debts':
      return Icons.account_balance_wallet_outlined;
    case 'maintenance':
      return Icons.build_outlined;
    case 'tasks':
      return Icons.task_alt_outlined;
    case 'stock':
      return Icons.inventory_2_outlined;
    default:
      return Icons.history;
  }
}

Color _activityColor(String module) {
  switch (module) {
    case 'sales':
      return const Color(0xFF2563EB);
    case 'debts':
      return const Color(0xFF059669);
    case 'maintenance':
      return const Color(0xFFEA580C);
    case 'tasks':
      return const Color(0xFF7C3AED);
    case 'stock':
      return const Color(0xFF0891B2);
    default:
      return AppColors.primaryColor;
  }
}

String _money(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}

CacheManager _employeeImageCacheManager() {
  return CacheManager(
    Config(
      'imagesCache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
    ),
  );
}
