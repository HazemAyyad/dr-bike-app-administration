import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../views/whatsapp_camera_screen.dart';

/// Reusable media picker that opens the same photo/video camera used by the
/// WhatsApp conversation screen.
class WhatsAppCameraMediaPicker extends StatelessWidget {
  const WhatsAppCameraMediaPicker({
    Key? key,
    required this.media,
    required this.onChanged,
    required this.title,
    this.isBusy = false,
    this.busyLabel,
  }) : super(key: key);

  final WhatsAppCapture? media;
  final ValueChanged<WhatsAppCapture?> onChanged;
  final String title;
  final bool isBusy;
  final String? busyLabel;

  Future<void> _capture() async {
    final capture = await Get.to<WhatsAppCapture>(
      () => const WhatsAppCameraScreen(),
      fullscreenDialog: true,
    );
    if (capture != null) onChanged(capture);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final border = isDark ? Colors.white24 : const Color(0xFFD1D5DB);

    if (media == null) {
      return InkWell(
        onTap: isBusy ? null : _capture,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          height: 92.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt_rounded,
                  color: AppColors.primaryColor, size: 28.sp),
              SizedBox(height: 6.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 150.h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (media!.mediaKind == 'video')
              Container(
                color: Colors.black87,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle_fill_rounded,
                        color: Colors.white, size: 48.sp),
                    SizedBox(height: 6.h),
                    Text(
                      'فيديو مرفق',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            else
              Image.file(File(media!.path), fit: BoxFit.cover),
            PositionedDirectional(
              top: 7.h,
              start: 7.w,
              child: Material(
                color: Colors.black.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(18.r),
                child: InkWell(
                  onTap: isBusy ? null : _capture,
                  borderRadius: BorderRadius.circular(18.r),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 15.sp),
                        SizedBox(width: 4.w),
                        Text(
                            media!.mediaKind == 'video'
                                ? 'إعادة التصوير'
                                : 'retakePhoto'.tr,
                            style: TextStyle(
                                color: Colors.white, fontSize: 10.sp)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: 7.h,
              end: 7.w,
              child: Material(
                color: Colors.black.withValues(alpha: 0.58),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'remove'.tr,
                  onPressed: isBusy ? null : () => onChanged(null),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
            if (isBusy)
              Container(
                color: Colors.black.withValues(alpha: 0.50),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 8.h),
                    Text(
                      busyLabel ?? 'saving'.tr,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
