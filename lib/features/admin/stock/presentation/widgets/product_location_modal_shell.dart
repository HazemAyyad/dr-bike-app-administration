import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';

/// Shared chrome for move / swap location flows — neutral surface, dark text only.
class ProductLocationModalShell extends StatelessWidget {
  const ProductLocationModalShell({
    Key? key,
    required this.title,
    required this.body,
    required this.onCancel,
    this.onConfirm,
    this.confirmLabel,
    this.confirmEnabled = true,
  }) : super(key: key);

  final String title;
  final Widget body;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;
  final String? confirmLabel;
  final bool confirmEnabled;

  static ButtonStyle get actionButtonStyle => FilledButton.styleFrom(
        backgroundColor: AppColors.whiteColor,
        foregroundColor: AppColors.operationalNavy,
        side: const BorderSide(color: AppColors.operationalCardBorder),
        elevation: 0,
      );

  static ButtonStyle get primaryButtonStyle => FilledButton.styleFrom(
        backgroundColor: AppColors.whiteColor,
        foregroundColor: AppColors.operationalNavy,
        disabledBackgroundColor: AppColors.customGreyColor6,
        disabledForegroundColor: AppColors.customGreyColor5,
        side: const BorderSide(color: AppColors.operationalNavy, width: 1.5),
        elevation: 0,
      );

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: AppColors.operationalSurface,
      child: Scaffold(
        backgroundColor: AppColors.operationalSurface,
        appBar: AppBar(
          backgroundColor: AppColors.whiteColor,
          foregroundColor: AppColors.operationalNavy,
          elevation: 0.5,
          surfaceTintColor: Colors.transparent,
          title: Text(
            title,
            style: TextStyle(
              color: AppColors.operationalNavy,
              fontWeight: FontWeight.w700,
              fontSize: 15.sp,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.close, color: AppColors.operationalNavy, size: 22.sp),
            onPressed: onCancel,
          ),
        ),
        body: body,
        bottomNavigationBar: Material(
          color: AppColors.whiteColor,
          elevation: 6,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 10.h),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.operationalNavy,
                        side: const BorderSide(color: AppColors.operationalCardBorder),
                      ),
                      onPressed: onCancel,
                      child: Text('cancel'.tr),
                    ),
                  ),
                  if (onConfirm != null) ...[
                    SizedBox(width: 10.w),
                    Expanded(
                      child: FilledButton(
                        style: primaryButtonStyle,
                        onPressed: confirmEnabled ? onConfirm : null,
                        child: Text(confirmLabel ?? 'confirm'.tr),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProductLocationNeutralCard extends StatelessWidget {
  const ProductLocationNeutralCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accentColor,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.operationalNavy;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.operationalCardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.customGreyColor5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.operationalNavy,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
