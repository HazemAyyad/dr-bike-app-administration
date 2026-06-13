import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';

/// Dialogs for suspended invoices — gray header, white title, light gray body.
class SuspendedInvoiceDialog {
  static const Color _headerGray = Color(0xFF6B7280);
  static const Color _bodyGray = Color(0xFFF5F6F8);
  static const Color _bodyText = Color(0xFF374151);

  static Future<bool?> showConfirm({
    required BuildContext context,
    required String titleKey,
    required String messageKey,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: const Color(0xFFD9D9D9).withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                color: _headerGray,
                child: Text(
                  titleKey.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                color: ThemeService.isDark.value
                    ? const Color(0xFF1F1F23)
                    : _bodyGray,
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      messageKey.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.sp,
                        height: 1.45,
                        color: ThemeService.isDark.value
                            ? Colors.white70
                            : _bodyText,
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text('cancel'.tr),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: Text('confirm'.tr),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Confirm dialogs only — gray header, white title (matches suspended-invoice UX).
}
