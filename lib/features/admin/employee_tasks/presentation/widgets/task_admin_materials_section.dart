import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/audio_helper.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/task_details_model.dart';
import 'audio_player.dart';
import 'task_media_thumbnail_row.dart';
import 'task_operational_shared.dart';

/// Admin instructions: photos, videos, and voice note visible to employee and admin.
class TaskAdminMaterialsSection extends StatelessWidget {
  const TaskAdminMaterialsSection({
    Key? key,
    required this.data,
    this.compact = true,
  }) : super(key: key);

  final TaskDetailsModel data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasMedia = (data.adminImg?.isNotEmpty ?? false) ||
        (data.adminVideos?.isNotEmpty ?? false);
    final hasAudio = hasPlayableAudio(data.audio);
    if (!hasMedia && !hasAudio) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TaskSectionTitle('adminTaskMaterials', compact: compact),
        TaskOpCard(
          compact: compact,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasMedia) ...[
                Text(
                  'adminAttachedMedia'.tr,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.customGreyColor5,
                  ),
                ),
                SizedBox(height: 6.h),
                TaskMediaThumbnailRow(
                  images: data.adminImg ?? [],
                  videos: data.adminVideos ?? [],
                ),
              ],
              if (hasAudio) ...[
                if (hasMedia) SizedBox(height: 10.h),
                Text(
                  'adminVoiceNote'.tr,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.customGreyColor5,
                  ),
                ),
                SizedBox(height: 6.h),
                AudioPlayerWidget(url: data.audio!),
              ],
            ],
          ),
        ),
        SizedBox(height: 6.h),
      ],
    );
  }
}
