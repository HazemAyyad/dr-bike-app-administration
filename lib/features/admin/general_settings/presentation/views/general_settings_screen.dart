import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:flutter/services.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/services/app_settings_service.dart';
import '../../../../../core/services/attendance_settings_service.dart';
import '../../../../../core/services/biometric_auth_service.dart';
import '../../../../../core/services/native_biometric_service.dart';
import '../../../../../core/services/user_data.dart';
import '../../../../../core/databases/api/dio_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../routes/app_routes.dart';

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({Key? key}) : super(key: key);

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  bool _biometricEnabled = false;
  bool _biometricBusy = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
    AppSettingsService.instance.ensureLoaded();
    AttendanceSettingsService.instance.ensureLoaded();
  }

  Future<void> _editSubtaskBonusDefault() async {
    await AppSettingsService.instance.ensureLoaded(force: true);
    final initial = AppSettingsService.instance.subtaskBonusDefault.value;
    final ctrl = TextEditingController(text: '$initial');

    const dialogBg = Color(0xFFF3F4F6);
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF6B7280);
    const actionBg = Color(0xFFE5E7EB);

    if (!mounted) {
      ctrl.dispose();
      return;
    }
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'subtaskBonusDefaultSetting'.tr,
          style: const TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: textPrimary),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'bonusPointsValue'.tr,
            labelStyle: const TextStyle(color: textSecondary),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'cancel'.tr,
              style: const TextStyle(color: textSecondary),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: actionBg,
              foregroundColor: textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('save'.tr),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) {
      ctrl.dispose();
      return;
    }

    final value = int.tryParse(ctrl.text.trim()) ?? initial;
    ctrl.dispose();
    if (value < 0) return;

    final ok =
        await AppSettingsService.instance.updateSubtaskBonusDefault(value);
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
  }

  Future<void> _editAdminFabOptions() async {
    await AppSettingsService.instance.ensureLoaded(force: true);
    final service = AppSettingsService.instance;
    final options = <String, String>{
      'newInvoice': 'newInvoice',
      'newEmployee': 'newEmployee',
      'newExpense': 'newExpense',
      'newCustomer': 'newCustomer',
      'createNewEmployeeTask': 'newTask',
    };
    final selected = service.adminFabOptions.toSet();
    const dialogBg = Color(0xFFF3F4F6);
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF6B7280);
    const actionBg = Color(0xFFE5E7EB);

    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: dialogBg,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'adminFabOptionsSetting'.tr,
            style: const TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.entries
                .map(
                  (entry) => CheckboxListTile(
                    value: selected.contains(entry.key),
                    activeColor: const Color(0xFF059669),
                    checkColor: Colors.white,
                    title: Text(
                      entry.value.tr,
                      style: const TextStyle(color: textPrimary),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          selected.add(entry.key);
                        } else {
                          selected.remove(entry.key);
                        }
                      });
                    },
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'cancel'.tr,
                style: const TextStyle(color: textSecondary),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: actionBg,
                foregroundColor: textPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('save'.tr),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;
    final ok = await service.updateAdminFabOptions(selected);
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
  }

  Future<void> _loadBiometricState() async {
    final enabled =
        await BiometricAuthService.instance.isBiometricLoginEnabled();
    if (mounted) {
      setState(() => _biometricEnabled = enabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageBg = const Color(0xFFF5F5F5);

    final items = <_SettingsItem>[
      _SettingsItem(
        icon: Icons.how_to_reg_outlined,
        iconColor: const Color(0xFFDC2626),
        titleKey: 'attendanceSettings',
        descriptionKey: 'attendanceSettingsDesc',
        onTap: () => _openAttendanceSettingsSheet(context),
      ),
      _SettingsItem(
        icon: Icons.people_outline,
        iconColor: const Color(0xFF059669),
        titleKey: 'manageCustomers',
        descriptionKey: 'manageCustomersDesc',
        onTap: () => Get.toNamed(
          AppRoutes.GENERALDATALISTSCREEN,
          arguments: {'initialTab': 1},
        ),
      ),
      _SettingsItem(
        icon: Icons.storefront_outlined,
        iconColor: const Color(0xFF7C3AED),
        titleKey: 'manageMerchants',
        descriptionKey: 'manageMerchantsDesc',
        onTap: () => Get.toNamed(
          AppRoutes.GENERALDATALISTSCREEN,
          arguments: {'initialTab': 0},
        ),
      ),
      _SettingsItem(
        icon: Icons.category_outlined,
        iconColor: const Color(0xFF6B65BD),
        titleKey: 'contactCategoriesSettings',
        descriptionKey: 'contactCategoriesSettingsDesc',
        onTap: () => Get.toNamed(AppRoutes.CONTACTCATEGORIESSETTINGSSCREEN),
      ),
      _SettingsItem(
        icon: Icons.account_balance_outlined,
        iconColor: const Color(0xFF0D9488),
        titleKey: 'banksManagement',
        descriptionKey: 'banksManagementDesc',
        onTap: () => Get.toNamed(AppRoutes.BANKSSETTINGSSCREEN),
      ),
      _SettingsItem(
        icon: Icons.tune_rounded,
        iconColor: const Color(0xFF2563EB),
        titleKey: 'pointCategoriesSetting',
        descriptionKey: 'pointCategoriesSettingDesc',
        onTap: () => Get.toNamed(AppRoutes.EMPLOYEEPOINTCATEGORIESSCREEN),
      ),
      _SettingsItem(
        icon: Icons.stars_rounded,
        iconColor: const Color(0xFFEA580C),
        titleKey: 'subtaskBonusDefaultSetting',
        descriptionKey: 'subtaskBonusDefaultSettingDesc',
        onTap: _editSubtaskBonusDefault,
      ),
      _SettingsItem(
        icon: Icons.emoji_events_outlined,
        iconColor: const Color(0xFFB45309),
        titleKey: 'rewardRulesSetting',
        descriptionKey: 'rewardRulesSettingDesc',
        onTap: () => Get.toNamed(AppRoutes.EMPLOYEEREWARDRULESSCREEN),
      ),
      _SettingsItem(
        icon: Icons.add_circle_outline,
        iconColor: const Color(0xFF0F766E),
        titleKey: 'adminFabOptionsSetting',
        descriptionKey: 'adminFabOptionsSettingDesc',
        onTap: _editAdminFabOptions,
      ),
    ];

    return Scaffold(
      backgroundColor: pageBg,
      appBar: CustomAppBar(
        title: 'generalSettings',
        action: false,
        backgroundColor: pageBg,
      ),
      body: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        itemBuilder: (_, i) {
          if (i == 0) {
            return _BiometricSettingsCard(
              enabled: _biometricEnabled,
              busy: _biometricBusy,
              onChanged: _toggleBiometricLogin,
              onTestPressed: _testBiometricPrompt,
            );
          }
          return _SettingsCard(item: items[i - 1]);
        },
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
        itemCount: items.length + 1,
      ),
    );
  }

  Future<void> _toggleBiometricLogin(bool value) async {
    if (_biometricBusy) return;

    setState(() => _biometricBusy = true);
    try {
      final service = BiometricAuthService.instance;

      if (!value) {
        await service.setBiometricLoginEnabled(false);
        await service.clearLoginData();
        if (mounted) setState(() => _biometricEnabled = false);
        _showMessage('تم تعطيل الدخول بالبصمة بنجاح');
        return;
      }

      final token = await UserData.getUserToken();
      final userDataJson = await service.readCurrentUserData();
      if (token.isEmpty || userDataJson == null || userDataJson.isEmpty) {
        if (mounted) setState(() => _biometricEnabled = false);
        _showMessage(
          'يرجى تسجيل الدخول مرة أخرى لتفعيل الدخول بالبصمة',
          isError: true,
        );
        return;
      }

      final readiness = await service.checkReadiness(
        requireCurrentSession: true,
      );
      if (!readiness.ready) {
        if (mounted) setState(() => _biometricEnabled = false);
        _showMessage(
          readiness.message ?? 'تم إلغاء عملية التحقق',
          isError: true,
        );
        return;
      }

      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;
      final authResult = await service.authenticate(
        checkReadinessFirst: false,
        context: context,
        source: 'general_settings_toggle',
      );
      if (!authResult.success) {
        if (mounted) setState(() => _biometricEnabled = false);
        _showMessage(
          authResult.message ?? 'تم إلغاء المصادقة بالبصمة',
          isError: true,
        );
        return;
      }

      await service.saveLoginData(
        token: token,
        userDataJson: userDataJson,
      );
      await service.setBiometricLoginEnabled(true);
      if (mounted) setState(() => _biometricEnabled = true);
      _showMessage('تم تفعيل الدخول بالبصمة بنجاح');
    } catch (e) {
      debugPrint('Biometric settings toggle error: $e');
      if (mounted) setState(() => _biometricEnabled = false);
      _showMessage(
        'تعذر تفعيل الدخول بالبصمة، حاول مرة أخرى',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _biometricBusy = false);
    }
  }

  Future<void> _testBiometricPrompt(String method, String label) async {
    if (_biometricBusy) return;

    setState(() => _biometricBusy = true);
    try {
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }
      if (method == 'openSecuritySettings') {
        final result =
            await NativeBiometricService.instance.openSecuritySettings();
        _showMessage(
          result.success
              ? 'تم فتح إعدادات الأمان'
              : result.message ?? 'تعذر فتح إعدادات الأمان',
          isError: !result.success,
        );
        return;
      }
      if (method == 'authenticateKeyguard' ||
          method == 'authenticateKeyguardDirect') {
        _showMessage(
          'سيتم فتح شاشة قفل الجهاز. أكمل التحقق بالبصمة أو رمز القفل ثم ارجع للتطبيق.',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));

      debugPrint('Biometric native test: starting $method');
      final result = await NativeBiometricService.instance.authenticate(
        method: method,
        timeout: method == 'authenticateKeyguard' ||
                method == 'authenticateKeyguardDirect'
            ? const Duration(seconds: 180)
            : const Duration(seconds: 90),
      );
      debugPrint(
        'Biometric native test: success=${result.success} '
        'available=${result.available} code=${result.code} '
        'codeText=${result.codeText} '
        'mode=${result.mode} message=${result.message}',
      );
      _showMessage(
        result.success ? '$label نجح' : result.message ?? '$label لم ينجح',
        isError: !result.success,
      );
    } catch (e) {
      debugPrint('Biometric raw test error: $e');
      _showMessage(
        'فشل اختبار نافذة البصمة',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _biometricBusy = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    Get.snackbar(
      isError ? 'تنبيه' : 'تم',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      colorText: Colors.white,
    );
  }

  Future<void> _openAttendanceSettingsSheet(BuildContext context) async {
    final s = AttendanceSettingsService.instance;
    await s.ensureLoaded(force: true);
    if (!context.mounted) return;

    final isBusy = false.obs;
    final devices = <Map<String, dynamic>>[].obs;

    final api = Get.isRegistered<DioConsumer>() ? Get.find<DioConsumer>() : null;
    if (api != null) {
      try {
        final res = await api.get(EndPoints.attendanceDevices);
        final data = res.data;
        if (data is Map && data['status']?.toString() == 'success') {
          final list = data['devices'];
          if (list is List) {
            devices.assignAll(list.map((e) => Map<String, dynamic>.from(e)));
          }
        }
      } catch (_) {}
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
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
          child: Obx(() {
            final fpEnabled = s.fingerprintEnabled.value;
            return Column(
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
                        'attendanceSettings'.tr,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                    Obx(() {
                      return TextButton(
                        onPressed: isBusy.value
                            ? null
                            : () async {
                                isBusy.value = true;
                                try {
                                  final ok = await s.save();
                                  if (!ctx.mounted) return;
                                  if (ok) {
                                    Navigator.pop(ctx);
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
                                  isBusy.value = false;
                                }
                              },
                        child: isBusy.value
                            ? SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('save'.tr),
                      );
                    }),
                  ],
                ),
                SizedBox(height: 8.h),
                _SwitchRow(
                  title: 'qrAttendance'.tr,
                  value: s.qrEnabled.value,
                  onChanged: (v) => s.qrEnabled.value = v,
                ),
                SizedBox(height: 8.h),
                _SwitchRow(
                  title: 'fingerprintAttendance'.tr,
                  value: fpEnabled,
                  onChanged: (v) => s.fingerprintEnabled.value = v,
                ),
                SizedBox(height: 10.h),
                _DropdownRow<String>(
                  title: 'fingerprintSyncMode'.tr,
                  enabled: fpEnabled,
                  value: s.fingerprintSyncMode.value,
                  items: const [
                    'disabled',
                    'pull',
                    'push',
                  ],
                  itemLabel: (v) {
                    if (v == 'pull') return 'fingerprintSyncModePull'.tr;
                    if (v == 'push') return 'fingerprintSyncModePush'.tr;
                    return 'fingerprintSyncModeDisabled'.tr;
                  },
                  onChanged: (v) {
                    if (v == null) return;
                    s.fingerprintSyncMode.value = v;
                  },
                ),
                SizedBox(height: 10.h),
                _DropdownRow<int>(
                  title: 'fingerprintSyncInterval'.tr,
                  enabled: fpEnabled && s.fingerprintSyncMode.value == 'pull',
                  value: s.syncIntervalMinutes.value,
                  items: const [1, 5, 10, 15],
                  itemLabel: (v) => '$v ${'minutesLabel'.tr}',
                  onChanged: (v) {
                    if (v == null) return;
                    s.syncIntervalMinutes.value = v;
                  },
                ),
                SizedBox(height: 10.h),
                _ActionRow(
                  title: 'fingerprintDevices'.tr,
                  enabled: fpEnabled,
                  onTap: () {
                    Navigator.pop(ctx);
                    Get.toNamed(AppRoutes.ATTENDANCEDEVICESSCREEN);
                  },
                ),
                SizedBox(height: 10.h),
                Obx(() {
                  final fpOn = s.fingerprintEnabled.value;
                  final list = devices;
                  final selected = s.defaultDeviceId.value;

                  final validIds = list
                      .map((d) => int.tryParse(d['id']?.toString() ?? ''))
                      .whereType<int>()
                      .toSet();
                  final safeSelected = (selected != null && validIds.contains(selected))
                      ? selected
                      : null;
                  if (safeSelected != selected) {
                    s.defaultDeviceId.value = safeSelected;
                  }

                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'fingerprintDefaultDevice'.tr,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: fpOn
                                ? const Color(0xFF111827)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        DropdownButtonFormField<int?>(
                          value: safeSelected,
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
                          onChanged: fpOn ? (v) => s.defaultDeviceId.value = v : null,
                          decoration: InputDecoration(
                            isDense: true,
                            border: const OutlineInputBorder(),
                            hintText: 'fingerprintDefaultDeviceHint'.tr,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (fpEnabled && s.fingerprintSyncMode.value == 'push') ...[
                  SizedBox(height: 10.h),
                  _PushEndpointCard(),
                ],
              ],
            );
          }),
        );
      },
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              title,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _DropdownRow<T> extends StatelessWidget {
  const _DropdownRow({
    required this.title,
    required this.enabled,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String title;
  final bool enabled;
  final T value;
  final List<T> items;
  final String Function(T v) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final textColor = enabled ? const Color(0xFF111827) : const Color(0xFF9CA3AF);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          IgnorePointer(
            ignoring: !enabled,
            child: Opacity(
              opacity: enabled ? 1 : 0.55,
              child: DropdownButtonFormField<T>(
                value: value,
                items: items
                    .map(
                      (v) => DropdownMenuItem<T>(
                        value: v,
                        child: Text(itemLabel(v)),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.title,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = enabled ? const Color(0xFF111827) : const Color(0xFF9CA3AF);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              Icon(
                Get.locale?.languageCode == 'ar'
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: enabled ? const Color(0xFF9CA3AF) : const Color(0xFFD1D5DB),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PushEndpointCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // This is a best-effort: base URL is currently static in EndPoints.
    // When backend is self-hosted, we still show the relative API path.
    final endpoint = '${EndPoints.baserUrl}fingerprint/push/attendance';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'pushEndpoint'.tr,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  endpoint,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              OutlinedButton(
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
                child: Text('copy'.tr),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BiometricSettingsCard extends StatelessWidget {
  const _BiometricSettingsCard({
    required this.enabled,
    required this.busy,
    required this.onChanged,
    required this.onTestPressed,
  });

  final bool enabled;
  final bool busy;
  final ValueChanged<bool> onChanged;
  final void Function(String method, String label) onTestPressed;

  @override
  Widget build(BuildContext context) {
    const cardColor = Colors.white;
    const borderColor = Color(0xFFE5E7EB);
    const titleColor = Color(0xFF111827);
    const descColor = Color(0xFF6B7280);
    final disabled = kIsWeb || busy;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.fingerprint,
                  color: const Color(0xFF059669),
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تفعيل الدخول بالبصمة',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      kIsWeb
                          ? 'الدخول بالبصمة غير متاح على الويب'
                          : 'استخدم بصمة الإصبع أو الوجه لتسجيل الدخول على هذا الجهاز',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: descColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              busy
                  ? SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Switch(
                      value: enabled && !kIsWeb,
                      onChanged: disabled ? null : onChanged,
                    ),
            ],
          ),
          if (!kIsWeb) ...[
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                if (kDebugMode) ...[
                  _BiometricTestButton(
                    label: 'اختبار بصمة قوية',
                    busy: busy,
                    onPressed: () => onTestPressed(
                      'authenticateStrong',
                      'اختبار بصمة قوية',
                    ),
                  ),
                  _BiometricTestButton(
                    label: 'اختبار بصمة ضعيفة',
                    busy: busy,
                    onPressed: () => onTestPressed(
                      'authenticateWeak',
                      'اختبار بصمة ضعيفة',
                    ),
                  ),
                  _BiometricTestButton(
                    label: 'اختبار قفل الجهاز القديم',
                    busy: busy,
                    onPressed: () => onTestPressed(
                      'authenticateDeviceCredential',
                      'اختبار قفل الجهاز القديم',
                    ),
                  ),
                  _BiometricTestButton(
                    label: 'اختبار بصمة أو قفل الجهاز',
                    busy: busy,
                    onPressed: () => onTestPressed(
                      'authenticateStrongOrCredential',
                      'اختبار بصمة أو قفل الجهاز',
                    ),
                  ),
                  _BiometricTestButton(
                    label: 'اختبار Keyguard مباشر',
                    busy: busy,
                    onPressed: () => onTestPressed(
                      'authenticateKeyguardDirect',
                      'اختبار Keyguard مباشر',
                    ),
                  ),
                ],
                _BiometricTestButton(
                  label: 'اختبار قفل الجهاز عبر النظام',
                  busy: busy,
                  onPressed: () => onTestPressed(
                    'authenticateKeyguard',
                    'اختبار قفل الجهاز عبر النظام',
                  ),
                ),
                _BiometricTestButton(
                  label: 'فتح إعدادات الأمان',
                  busy: busy,
                  onPressed: () => onTestPressed(
                    'openSecuritySettings',
                    'فتح إعدادات الأمان',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BiometricTestButton extends StatelessWidget {
  const _BiometricTestButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: busy ? null : onPressed,
      icon: const Icon(Icons.bug_report_outlined),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF374151),
        side: const BorderSide(color: Color(0xFFD1D5DB)),
        backgroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }
}

class _SettingsItem {
  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.titleKey,
    required this.descriptionKey,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String titleKey;
  final String descriptionKey;
  final VoidCallback onTap;
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.item});

  final _SettingsItem item;

  @override
  Widget build(BuildContext context) {
    const cardColor = Colors.white;
    const borderColor = Color(0xFFE5E7EB);
    const titleColor = Color(0xFF111827);
    const descColor = Color(0xFF6B7280);
    const chevronColor = Color(0xFF9CA3AF);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: item.onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: item.iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.titleKey.tr,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      item.descriptionKey.tr,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: descColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Get.locale?.languageCode == 'ar'
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: chevronColor,
                size: 24.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
