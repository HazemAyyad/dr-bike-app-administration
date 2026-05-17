import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/biometric_auth_service.dart';
import '../../../../../core/services/native_biometric_service.dart';
import '../../../../../core/services/user_data.dart';
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
        icon: Icons.emoji_events_outlined,
        iconColor: const Color(0xFFB45309),
        titleKey: 'rewardRulesSetting',
        descriptionKey: 'rewardRulesSettingDesc',
        onTap: () => Get.toNamed(AppRoutes.EMPLOYEEREWARDRULESSCREEN),
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
        result.success
            ? '$label نجح'
            : result.message ?? '$label لم ينجح',
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
