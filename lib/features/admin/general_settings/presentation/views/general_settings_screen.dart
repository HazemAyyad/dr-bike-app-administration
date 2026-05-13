import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/biometric_auth_service.dart';
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

      final authResult = await service.authenticate(checkReadinessFirst: false);
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
  });

  final bool enabled;
  final bool busy;
  final ValueChanged<bool> onChanged;

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
      child: Row(
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
