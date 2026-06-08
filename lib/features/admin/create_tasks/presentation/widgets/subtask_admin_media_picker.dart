import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/helpers/audio_helper.dart';
import '../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../core/helpers/task_media_paths.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../employee_tasks/presentation/widgets/subtask_voice_note_tile.dart';
import '../../../employee_tasks/presentation/widgets/task_media_thumbnail_row.dart';
import '../controllers/create_task_controller.dart';
import 'audio_recorder.dart';

/// Admin attachments for a subtask (photos / video / voice) visible to employees.
class SubtaskAdminMediaPicker extends GetView<CreateTaskController> {
  const SubtaskAdminMediaPicker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final paths = controller.subTaskMediaPaths;
      final images = <String>[];
      final videos = <String>[];
      final localFiles = <File>[];
      for (final p in paths) {
        if (isAudioMediaPath(p)) continue;
        if (p.startsWith('http')) {
          if (localFileIsVideo(p) || isVideoMediaPath(p)) {
            videos.add(p);
          } else {
            images.add(p);
          }
        } else {
          localFiles.add(File(p));
        }
      }
      final hasAudio = hasPlayableAudio(controller.subTaskAdminAudio.value);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'subtaskAdminMaterialsForEmployee'.tr,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.customGreyColor5,
            ),
          ),
          SizedBox(height: 6.h),
          if (images.isNotEmpty || videos.isNotEmpty || localFiles.isNotEmpty)
            TaskMediaThumbnailRow(
              images: images,
              videos: videos,
              localFiles: localFiles,
              thumbHeight: 56,
              thumbWidth: 56,
            ),
          if (hasAudio) ...[
            SizedBox(height: 8.h),
            SubtaskVoiceNoteTile(url: controller.subTaskAdminAudio.value),
          ],
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickImage(context, video: false),
                icon: const Icon(Icons.photo_outlined, size: 18),
                label: Text('uploadImage'.tr, style: TextStyle(fontSize: 11.sp)),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickImage(context, video: true),
                icon: const Icon(Icons.videocam_outlined, size: 18),
                label: Text('uploadVideo'.tr, style: TextStyle(fontSize: 11.sp)),
              ),
              if (paths.isNotEmpty)
                TextButton(
                  onPressed: controller.clearSubTaskMedia,
                  child: Text('clearMedia'.tr, style: TextStyle(fontSize: 11.sp)),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          AudioRecorderButton(
            label: 'subtaskAdminVoiceNote'.tr,
            recordedPath: controller.subTaskAdminAudio,
          ),
        ],
      );
    });
  }

  Future<void> _pickImage(BuildContext context, {required bool video}) async {
    final picked = Rx<XFile?>(null);
    await UploadImageButton.pickFileFor(context, picked, isVideo: video);
    if (picked.value != null) {
      controller.addSubTaskMediaPath(picked.value!.path);
    }
  }
}
