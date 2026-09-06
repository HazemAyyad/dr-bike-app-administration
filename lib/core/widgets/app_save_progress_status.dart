import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum AppSaveProgressState { idle, saving, success, error }

/// Compact reusable status for full-form saves, auto-save, and media uploads.
class AppSaveProgressStatus extends StatelessWidget {
  const AppSaveProgressStatus({
    Key? key,
    required this.state,
    required this.message,
  }) : super(key: key);

  final AppSaveProgressState state;
  final String message;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final Widget indicator;
    switch (state) {
      case AppSaveProgressState.saving:
        color = const Color(0xFF2563EB);
        indicator = SizedBox(
          width: 17.w,
          height: 17.w,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: color,
          ),
        );
        break;
      case AppSaveProgressState.success:
        color = const Color(0xFF16A34A);
        indicator =
            Icon(Icons.check_circle_outline_rounded, color: color, size: 19.sp);
        break;
      case AppSaveProgressState.error:
        color = const Color(0xFFDC2626);
        indicator =
            Icon(Icons.error_outline_rounded, color: color, size: 19.sp);
        break;
      case AppSaveProgressState.idle:
        color = const Color(0xFF6B7280);
        indicator = Icon(Icons.cloud_done_outlined, color: color, size: 19.sp);
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          indicator,
          SizedBox(width: 7.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
