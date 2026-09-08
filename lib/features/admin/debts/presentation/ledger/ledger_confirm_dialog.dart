import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';

/// Neutral confirm dialog for debt ledger (archive / delete).
Future<bool?> showLedgerConfirmDialog({
  required String title,
  required String body,
  required String confirmLabel,
  required Color confirmColor,
}) {
  return Get.dialog<bool>(
    AlertDialog(
      backgroundColor: ThemeService.isDark.value
          ? const Color(0xFF242430)
          : const Color(0xFFF0F0F0),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: ThemeService.isDark.value ? Colors.white : Colors.black87,
        ),
      ),
      content: Text(
        body,
        style: TextStyle(
          fontSize: 14.sp,
          color: ThemeService.isDark.value ? Colors.white70 : Colors.black87,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text(
            'cancel'.tr,
            style: TextStyle(
              fontSize: 14.sp,
              color: ThemeService.isDark.value
                  ? Colors.white70
                  : Colors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: Text(
            confirmLabel,
            style: TextStyle(
              fontSize: 14.sp,
              color: confirmColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
    barrierDismissible: true,
  );
}
