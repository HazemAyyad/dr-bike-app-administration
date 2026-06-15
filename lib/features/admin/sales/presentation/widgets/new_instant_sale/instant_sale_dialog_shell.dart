import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../../core/utils/app_colors.dart';

/// Neutral dialog shell for instant-sale modals (no lilac tint / white outline).
class InstantSaleDialogShell extends StatelessWidget {
  const InstantSaleDialogShell({
    Key? key,
    required this.child,
    this.insetPadding,
  }) : super(key: key);

  final Widget child;
  final EdgeInsets? insetPadding;

  static InputDecoration fieldDecoration(
    BuildContext context, {
    required String labelText,
    String? hintText,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: AdminUiColors.inputFill(context),
      labelText: labelText,
      hintText: hintText,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: AppColors.primaryColor, width: 1.4),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    // Lift the whole dialog above the keyboard — do not pad inside (avoids
    // a white band covering action buttons when the keyboard opens).
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: Dialog(
          backgroundColor: AdminUiColors.cardBackground(context),
          surfaceTintColor: Colors.transparent,
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.18),
          insetPadding: insetPadding ??
              EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: child,
        ),
      ),
    );
  }
}
