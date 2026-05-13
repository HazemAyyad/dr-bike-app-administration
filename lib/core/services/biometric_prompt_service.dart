import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../utils/app_colors.dart';
import 'biometric_auth_service.dart';

class BiometricPromptService {
  BiometricPromptService._();

  static final BiometricPromptService instance = BiometricPromptService._();

  bool _promptShownThisSession = false;
  bool _promptBusy = false;

  Future<void> showPostLoginPromptIfNeeded() async {
    if (kIsWeb || _promptShownThisSession || _promptBusy) return;

    final service = BiometricAuthService.instance;
    final enabled = await service.isBiometricLoginEnabled();
    if (enabled) {
      final savedData = await service.getSavedLoginData();
      if (savedData != null) {
        await service.saveCurrentSessionForBiometricLogin();
        return;
      }
    }

    final token = await service.readCurrentToken();
    final userData = await service.readCurrentUserData();
    if (token.isEmpty || userData == null || userData.isEmpty) return;

    final readiness = await service.checkReadiness(requireCurrentSession: true);
    if (!readiness.ready) return;

    _promptShownThisSession = true;

    final shouldEnable = await Get.dialog<bool>(
      const _BiometricEnableDialog(),
      barrierDismissible: true,
    );

    if (shouldEnable != true) return;

    _promptBusy = true;
    try {
      final authResult = await service.authenticate(checkReadinessFirst: false);
      if (!authResult.success) {
        _showMessage(
          authResult.message ?? 'تم إلغاء عملية التحقق',
          isError: true,
        );
        return;
      }

      await service.saveCurrentSessionForBiometricLogin();
      final saved = await service.getSavedLoginData();
      if (saved == null) {
        await service.setBiometricLoginEnabled(false);
        _showMessage(
          'يرجى تسجيل الدخول مرة أخرى لتفعيل الدخول بالبصمة',
          isError: true,
        );
        return;
      }

      await service.setBiometricLoginEnabled(true);
      _showMessage('تم تفعيل الدخول بالبصمة بنجاح');
    } finally {
      _promptBusy = false;
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

class _BiometricEnableDialog extends StatelessWidget {
  const _BiometricEnableDialog();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 58.w,
                  height: 58.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: Icon(
                    Icons.fingerprint,
                    color: AppColors.secondaryColor,
                    size: 34.sp,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'هل تريد تفعيل الدخول بالبصمة لهذا الجهاز؟',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF111827),
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'يمكنك استخدام بصمة الإصبع أو الوجه للدخول بسرعة في المرات القادمة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF6B7280),
                  fontSize: 13.sp,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 18.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      child: const Text('لاحقاً'),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: AppColors.secondaryColor,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      child: const Text('تفعيل'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
