import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/employee_section_controller.dart';
import '../../domain/entities/employee_details_entity.dart';
import '../widgets/employee_points_tab.dart';

class EmployeeDetailsScreen extends GetView<EmployeeSectionController> {
  const EmployeeDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextStyle theme = Theme.of(context).textTheme.bodyMedium!;
    final String points = Get.arguments;
    return DefaultTabController(
      length: 2,
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
                labelColor: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
                unselectedLabelColor: AppColors.customGreyColor5,
                indicatorColor: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
                labelStyle: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
                tabs: [
                  Tab(text: 'employeeDetails'.tr),
                  Tab(text: 'pointsAndRewardsTab'.tr),
                ],
              ),
            ),
          ),
          actions: [
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
            return TabBarView(
              children: [
                _EmployeeOverviewTab(
                  employee: controller.employeeService.employeeDetails.value!,
                  points: points,
                  isManualCheckoutLoading:
                      controller.isManualCheckoutLoading.value,
                  onManualCheckout: () => controller.manualCheckoutEmployee(
                    context,
                  ),
                ),
                EmployeePointsTab(employeeId: employeeId),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmployeeOverviewTab extends StatelessWidget {
  const _EmployeeOverviewTab({
    required this.employee,
    required this.points,
    required this.isManualCheckoutLoading,
    required this.onManualCheckout,
  });

  final EmployeeDetailsEntity employee;
  final String points;
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
            points: points,
            onCopyEmail: () => _copyEmail(context, employee.email),
            onShowPoints: () => _showPointsHistory(context, employee),
          ),
          SizedBox(height: 12.h),
          _DetailSection(
            title: 'contactInfo'.tr,
            icon: Icons.contact_phone_outlined,
            children: [
              _InfoTile(
                icon: Icons.email_outlined,
                label: 'email'.tr,
                value: employee.email,
                trailing: IconButton(
                  tooltip: 'copy'.tr,
                  onPressed: () => _copyEmail(context, employee.email),
                  icon: const Icon(Icons.copy_rounded),
                ),
              ),
              _InfoTile(
                icon: Icons.phone_outlined,
                label: 'phoneNumber'.tr,
                value: _phone.isEmpty ? '—' : _phone,
              ),
              _InfoTile(
                icon: Icons.phone_android_outlined,
                label: 'alternatePhone'.tr,
                value: _subPhone.isEmpty ? '—' : _subPhone,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _DetailSection(
            title: 'attendanceTimesCard'.tr,
            icon: Icons.schedule_outlined,
            children: [
              _InfoTile(
                icon: Icons.payments_outlined,
                label: 'hourlyRate'.tr,
                value: '${employee.hourWorkPrice} ${'currency'.tr}',
              ),
              _InfoTile(
                icon: Icons.more_time_outlined,
                label: 'overTimeRate'.tr,
                value: '${employee.overtimeWorkPrice} ${'currency'.tr}',
              ),
              _InfoTile(
                icon: Icons.timelapse_outlined,
                label: 'workHoursOfDay'.tr,
                value: _workHoursLabel,
              ),
              _InfoTile(
                icon: Icons.access_time_outlined,
                label: 'regularWorkingHours'.tr,
                value: _workingTimeLabel,
              ),
              _InfoTile(
                icon: Icons.event_busy_outlined,
                label: 'weeklyDaysOffTitle'.tr,
                value: _weeklyDaysOffLabel,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _FingerprintInfoCard(
            enabled: employee.fingerprintEnabled,
            deviceUserId: employee.deviceUserId,
            lastScan: employee.lastFingerprintScanAt,
            lastAttendance: employee.lastFingerprintAttendanceAt,
          ),
          if (employee.currentlyInToday) ...[
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
            title: 'employeeImage'.tr,
            images: employee.employeeImg,
          ),
          SizedBox(height: 12.h),
          _ImageGallerySection(
            title: 'documentsImages'.tr,
            images: employee.documentImg,
          ),
          SizedBox(height: 12.h),
          _PermissionsSection(permissions: employee.permissions),
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

  void _showPointsHistory(
    BuildContext context,
    EmployeeDetailsEntity employee,
  ) {
    final isDark = ThemeService.isDark.value;
    Get.dialog(
      Dialog(
        backgroundColor: isDark ? AppColors.darkColor : AppColors.whiteColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 0.72.sh),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(14.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'pointsHistory'.tr,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: 10.h),
                if (employee.rewardPunishment.isEmpty)
                  Text(
                    'noData'.tr,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    ),
                  )
                else
                  ...employee.rewardPunishment.map(
                    (e) => _PointHistoryRow(item: e),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmployeeHeaderCard extends StatelessWidget {
  const _EmployeeHeaderCard({
    required this.employee,
    required this.points,
    required this.onCopyEmail,
    required this.onShowPoints,
  });

  final EmployeeDetailsEntity employee;
  final String points;
  final VoidCallback onCopyEmail;
  final VoidCallback onShowPoints;

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
      child: Row(
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
                SizedBox(height: 4.h),
                Text(
                  employee.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.sp, color: subColor),
                ),
                SizedBox(height: 10.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 6.h,
                  children: [
                    _MetricChip(
                      icon: Icons.stars_rounded,
                      label: '${'points'.tr}: $points',
                      color: AppColors.primaryColor,
                      onTap: onShowPoints,
                    ),
                    _MetricChip(
                      icon: Icons.copy_rounded,
                      label: 'copy'.tr,
                      color: AppColors.secondaryColor,
                      onTap: onCopyEmail,
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final labelColor = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final valueColor = isDark ? Colors.white : const Color(0xFF111827);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 7.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 17.sp, color: AppColors.primaryColor),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value.isEmpty ? '—' : value,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
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

class _PermissionsSection extends StatelessWidget {
  const _PermissionsSection({required this.permissions});

  final List<PermissionEntity> permissions;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'permissions'.tr,
      icon: Icons.admin_panel_settings_outlined,
      children: [
        if (permissions.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Text('noData'.tr),
          )
        else
          Wrap(
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
      ],
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

class _PointHistoryRow extends StatelessWidget {
  const _PointHistoryRow({required this.item});

  final RewardPunishmentEntity item;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${item.type.tr}: ${item.points} ${'point'.tr}',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          if (item.notes.trim().isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              item.notes,
              style: TextStyle(fontSize: 12.sp, color: subColor),
            ),
          ],
        ],
      ),
    );
  }
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

class _FingerprintInfoCard extends StatelessWidget {
  const _FingerprintInfoCard({
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
    final border = isDark ? Colors.white12 : const Color(0xFFE5E7EB);
    final bg = isDark ? AppColors.customGreyColor4 : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final badgeColor =
        enabled ? const Color(0xFF059669) : const Color(0xFF6B7280);
    final badgeText = enabled ? 'enabledLabel'.tr : 'disabledLabel'.tr;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'fingerprintAttendance'.tr,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            '${'deviceUserId'.tr}: ${deviceUserId == null || deviceUserId!.isEmpty ? '—' : deviceUserId}',
            style: TextStyle(fontSize: 12.sp, color: subColor),
          ),
          SizedBox(height: 4.h),
          Text(
            '${'lastFingerprintScan'.tr}: ${formatApiDateTime12(lastScan)}',
            style: TextStyle(fontSize: 12.sp, color: subColor),
          ),
          SizedBox(height: 4.h),
          Text(
            '${'lastFingerprintAttendance'.tr}: ${formatApiDateTime12(lastAttendance)}',
            style: TextStyle(fontSize: 12.sp, color: subColor),
          ),
        ],
      ),
    );
  }
}
