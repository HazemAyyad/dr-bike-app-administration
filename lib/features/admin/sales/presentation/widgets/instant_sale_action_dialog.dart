import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';

/// Dialogs for instant-sale cancel / edit — light gray surface, dark text (employees section style).
class InstantSaleActionDialog {
  static Color _dialogBg(bool isDark) =>
      isDark ? const Color(0xFF1F1F23) : const Color(0xFFF5F6F8);

  static Color _titleColor(bool isDark) =>
      isDark ? Colors.white : const Color(0xFF111827);

  static Color _bodyColor(bool isDark) =>
      isDark ? Colors.white70 : const Color(0xFF6B7280);

  static InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: ThemeService.isDark.value ? Colors.white70 : const Color(0xFF6B7280),
      ),
      filled: true,
      fillColor: ThemeService.isDark.value
          ? const Color(0xFF26262B)
          : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
    );
  }

  static Future<bool?> showCancelConfirm(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final bg = _dialogBg(isDark);

    return showDialog<bool>(
      context: context,
      barrierColor: const Color(0xFFD9D9D9).withOpacity(0.55),
      builder: (ctx) => Dialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'cancelInstantSale'.tr,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: _titleColor(isDark),
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'confirmCancelInstantSale'.tr,
                style: TextStyle(
                  fontSize: 13.sp,
                  height: 1.4,
                  color: _bodyColor(isDark),
                ),
              ),
              SizedBox(height: 18.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(
                        'cancel'.tr,
                        style: TextStyle(
                          color: _bodyColor(isDark),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                      child: Text('yes'.tr),
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

  static Future<bool?> showEdit({
    required BuildContext context,
    required TextEditingController costCtrl,
    required TextEditingController qtyCtrl,
    required TextEditingController totalCtrl,
    required TextEditingController notesCtrl,
  }) {
    final isDark = ThemeService.isDark.value;
    final bg = _dialogBg(isDark);
    final fieldStyle = TextStyle(
      color: _titleColor(isDark),
      fontSize: 14.sp,
    );

    return showDialog<bool>(
      context: context,
      barrierColor: const Color(0xFFD9D9D9).withOpacity(0.55),
      builder: (ctx) => Dialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'editInstantSale'.tr,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: _titleColor(isDark),
                  ),
                ),
                SizedBox(height: 14.h),
                TextField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  style: fieldStyle,
                  decoration: _fieldDecoration('price'.tr),
                ),
                SizedBox(height: 10.h),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  style: fieldStyle,
                  decoration: _fieldDecoration('quantity'.tr),
                ),
                SizedBox(height: 10.h),
                TextField(
                  controller: totalCtrl,
                  keyboardType: TextInputType.number,
                  style: fieldStyle,
                  decoration: _fieldDecoration('total'.tr),
                ),
                SizedBox(height: 10.h),
                TextField(
                  controller: notesCtrl,
                  style: fieldStyle,
                  decoration: _fieldDecoration('notes'.tr),
                ),
                SizedBox(height: 18.h),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(
                          'cancel'.tr,
                          style: TextStyle(
                            color: _bodyColor(isDark),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text('save'.tr),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
