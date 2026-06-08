import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/audio_helper.dart';
import '../../../../../core/utils/app_colors.dart';
import 'audio_player.dart';

/// Compact voice-note row for subtasks (mic icon + optional expand to player).
class SubtaskVoiceNoteTile extends StatelessWidget {
  const SubtaskVoiceNoteTile({
    Key? key,
    required this.url,
    this.compact = true,
    this.label,
  }) : super(key: key);

  final String url;
  final bool compact;
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (!hasPlayableAudio(url)) {
      return const SizedBox.shrink();
    }

    if (!compact) {
      return AudioPlayerWidget(url: url);
    }

    return Material(
      color: AppColors.operationalPurple.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: () => _openPlayer(context),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          child: Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: const BoxDecoration(
                  color: AppColors.operationalPurple,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mic_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  label ?? 'subtaskAdminVoiceNote'.tr,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.operationalNavy,
                  ),
                ),
              ),
              Icon(
                Icons.play_circle_outline,
                color: AppColors.operationalPurple,
                size: 26.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void openPlayer(
    BuildContext context, {
    required String url,
    String? label,
  }) {
    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                label ?? 'subtaskAdminVoiceNote'.tr,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.operationalNavy,
                ),
              ),
              SizedBox(height: 12.h),
              AudioPlayerWidget(url: url),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      isScrollControlled: true,
    );
  }

  void _openPlayer(BuildContext context) {
    openPlayer(context, url: url, label: label);
  }
}
