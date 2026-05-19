import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Neutral confirm dialog for debt ledger (archive / delete).
Future<bool?> showLedgerConfirmDialog({
  required String title,
  required String body,
  required String confirmLabel,
  required Color confirmColor,
}) {
  return Get.dialog<bool>(
    AlertDialog(
      backgroundColor: const Color(0xFFF0F0F0),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
      content: Text(
        body,
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.black87,
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
              color: Colors.grey.shade800,
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
