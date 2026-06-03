import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/databases/api/dio_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/services/attendance_settings_service.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';

class AttendanceSettingsScreen extends StatefulWidget {
  const AttendanceSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceSettingsScreen> createState() =>
      _AttendanceSettingsScreenState();
}

class _AttendanceSettingsScreenState extends State<AttendanceSettingsScreen> {
  final AttendanceSettingsService _s = AttendanceSettingsService.instance;
  final RxBool _pageLoading = true.obs;
  final RxBool _isSaving = false.obs;
  final RxList<Map<String, dynamic>> _devices = <Map<String, dynamic>>[].obs;

  DioConsumer? get _api =>
      Get.isRegistered<DioConsumer>() ? Get.find<DioConsumer>() : null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _pageLoading.value = true;
    try {
      final futures = <Future<void>>[_s.ensureLoaded(force: true)];
      final api = _api;
      if (api != null) {
        futures.add(() async {
          try {
            final res = await api.get(
              EndPoints.attendanceDevices,
              queryParameters: const {'minimal': 1},
            );
            final data = res.data;
            if (data is Map && data['status']?.toString() == 'success') {
              final list = data['devices'];
              if (list is List) {
                _devices.assignAll(
                  list.map((e) => Map<String, dynamic>.from(e)),
                );
              }
            }
          } catch (_) {}
        }());
      }
      await Future.wait(futures);
    } finally {
      _pageLoading.value = false;
    }
  }

  Future<void> _save() async {
    _isSaving.value = true;
    try {
      final ok = await _s.save();
      if (!mounted) return;
      if (ok) {
        Helpers.showCustomDialogSuccess(
          context: context,
          title: 'success'.tr,
          message: 'settingsUpdated'.tr,
        );
      } else {
        Helpers.showCustomDialogError(
          context: context,
          title: 'error'.tr,
          message: 'settingsUpdateFailed'.tr,
        );
      }
    } finally {
      _isSaving.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final pageBg = isDark ? AppColors.darkColor : const Color(0xFFF5F5F5);
    final cardBg = isDark ? const Color(0xFF1F2937) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final textPrimary =
        isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: CustomAppBar(
        title: 'attendanceSettings',
        backgroundColor: pageBg,
        surfaceTintColor: Colors.transparent,
        actions: [
          Obx(() {
            final busy = _isSaving.value || _pageLoading.value;
            return TextButton(
              onPressed: busy ? null : _save,
              child: busy
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'save'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.sp,
                        color: AppColors.primaryColor,
                      ),
                    ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (_pageLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: _load,
          child: Obx(() {
            return ListView(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
              children: [
                _SectionTitle(
                  title: 'attendanceMethodsSection'.tr,
                  textColor: textSecondary,
                ),
                SizedBox(height: 10.h),
                _ToggleCard(
                  cardBg: cardBg,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  icon: Icons.qr_code_scanner_rounded,
                  iconColor: const Color(0xFF2563EB),
                  iconBg: const Color(0xFFEFF6FF),
                  title: 'qrAttendance'.tr,
                  subtitle: 'qrAttendanceDesc'.tr,
                  value: _s.qrEnabled.value,
                  onChanged: (v) => _s.qrEnabled.value = v,
                ),
                SizedBox(height: 10.h),
                _ToggleCard(
                  cardBg: cardBg,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  icon: Icons.fingerprint_rounded,
                  iconColor: const Color(0xFF059669),
                  iconBg: const Color(0xFFECFDF5),
                  title: 'fingerprintAttendance'.tr,
                  subtitle: 'fingerprintAttendanceDesc'.tr,
                  value: _s.fingerprintEnabled.value,
                  onChanged: (v) => _s.fingerprintEnabled.value = v,
                ),
                if (_s.fingerprintEnabled.value) ...[
                  SizedBox(height: 24.h),
                  _SectionTitle(
                    title: 'fingerprintOptionsSection'.tr,
                    textColor: textSecondary,
                  ),
                  SizedBox(height: 10.h),
                  _SettingsCard(
                    cardBg: cardBg,
                    borderColor: borderColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'fingerprintSyncMode'.tr,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        _SyncModeChips(
                          value: _s.fingerprintSyncMode.value,
                          onChanged: (v) => _s.fingerprintSyncMode.value = v,
                        ),
                      ],
                    ),
                  ),
                  if (_s.fingerprintSyncMode.value == 'pull') ...[
                    SizedBox(height: 10.h),
                    _SettingsCard(
                      cardBg: cardBg,
                      borderColor: borderColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'fingerprintSyncInterval'.tr,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          _IntervalChips(
                            value: _s.syncIntervalMinutes.value,
                            onChanged: (v) => _s.syncIntervalMinutes.value = v,
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 10.h),
                  _SettingsCard(
                    cardBg: cardBg,
                    borderColor: borderColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'fingerprintDefaultDevice'.tr,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'fingerprintDefaultDeviceHint'.tr,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: textSecondary,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        _DefaultDeviceDropdown(
                          devices: _devices,
                          onChanged: (v) => _s.defaultDeviceId.value = v,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _NavCard(
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    icon: Icons.devices_other_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    iconBg: const Color(0xFFF5F3FF),
                    title: 'fingerprintDevices'.tr,
                    subtitle: 'fingerprintDevicesDesc'.tr,
                    onTap: () => Get.toNamed(AppRoutes.ATTENDANCEDEVICESSCREEN),
                  ),
                  if (_s.fingerprintSyncMode.value == 'push') ...[
                    SizedBox(height: 10.h),
                    _PushEndpointCard(
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                ],
                SizedBox(height: 24.h),
                Obx(() {
                  final busy = _isSaving.value;
                  return SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: busy ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: busy
                          ? SizedBox(
                              width: 22.w,
                              height: 22.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'save'.tr,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  );
                }),
              ],
            );
          }),
        );
      }),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.textColor});

  final String title;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: textColor,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.cardBg,
    required this.borderColor,
    required this.child,
  });

  final Color cardBg;
  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 46.w,
            height: 46.w,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(13.r),
            ),
            child: Icon(icon, color: iconColor, size: 24.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.primaryColor.withValues(alpha: 0.45),
            activeThumbColor: AppColors.primaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SyncModeChips extends StatelessWidget {
  const _SyncModeChips({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const modes = ['disabled', 'pull', 'push'];
    String label(String v) {
      if (v == 'pull') return 'fingerprintSyncModePull'.tr;
      if (v == 'push') return 'fingerprintSyncModePush'.tr;
      return 'fingerprintSyncModeDisabled'.tr;
    }

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: modes.map((mode) {
        final selected = value == mode;
        return ChoiceChip(
          label: Text(
            label(mode),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF374151),
            ),
          ),
          selected: selected,
          selectedColor: AppColors.primaryColor,
          backgroundColor: const Color(0xFFF3F4F6),
          side: BorderSide(
            color: selected ? AppColors.primaryColor : const Color(0xFFE5E7EB),
          ),
          onSelected: (_) => onChanged(mode),
        );
      }).toList(),
    );
  }
}

class _IntervalChips extends StatelessWidget {
  const _IntervalChips({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [1, 5, 10, 15].map((mins) {
        final selected = value == mins;
        return ChoiceChip(
          label: Text(
            '$mins ${'minutesLabel'.tr}',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF374151),
            ),
          ),
          selected: selected,
          selectedColor: const Color(0xFF059669),
          backgroundColor: const Color(0xFFF3F4F6),
          side: BorderSide(
            color: selected ? const Color(0xFF059669) : const Color(0xFFE5E7EB),
          ),
          onSelected: (_) => onChanged(mins),
        );
      }).toList(),
    );
  }
}

class _DefaultDeviceDropdown extends StatelessWidget {
  const _DefaultDeviceDropdown({
    required this.devices,
    required this.onChanged,
  });

  final RxList<Map<String, dynamic>> devices;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final svc = AttendanceSettingsService.instance;

    return Obx(() {
      final list = devices;
      final selected = svc.defaultDeviceId.value;
      final validIds = list
          .map((d) => int.tryParse(d['id']?.toString() ?? ''))
          .whereType<int>()
          .toSet();
      final safeSelected =
          (selected != null && validIds.contains(selected)) ? selected : null;

      if (safeSelected != selected) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (svc.defaultDeviceId.value == selected) {
            svc.defaultDeviceId.value = safeSelected;
          }
        });
      }

      return DropdownButtonFormField<int?>(
        key: ValueKey<int?>(safeSelected),
        initialValue: safeSelected,
        isExpanded: true,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        items: [
          DropdownMenuItem<int?>(
            value: null,
            child: Text('fingerprintDefaultDeviceNone'.tr),
          ),
          ...list.map((d) {
            final id = int.tryParse(d['id']?.toString() ?? '');
            final name = d['name']?.toString() ?? '';
            if (id == null) return null;
            return DropdownMenuItem<int?>(
              value: id,
              child: Text(name.isEmpty ? '#$id' : name),
            );
          }).whereType<DropdownMenuItem<int?>>(),
        ],
        onChanged: onChanged,
      );
    });
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(13.r),
                ),
                child: Icon(icon, color: iconColor, size: 24.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Get.locale?.languageCode == 'ar'
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: const Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PushEndpointCard extends StatelessWidget {
  const _PushEndpointCard({
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final endpoint = '${EndPoints.baserUrl}fingerprint/push/attendance';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link_rounded, size: 18.sp, color: const Color(0xFF2563EB)),
              SizedBox(width: 6.w),
              Text(
                'pushEndpoint'.tr,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: SelectableText(
              endpoint,
              style: TextStyle(fontSize: 11.sp, color: textSecondary, height: 1.4),
            ),
          ),
          SizedBox(height: 10.h),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: endpoint));
              if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
              Get.snackbar(
                'success'.tr,
                'copied'.tr,
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green.shade700,
                colorText: Colors.white,
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text('copy'.tr),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(double.infinity, 40.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
