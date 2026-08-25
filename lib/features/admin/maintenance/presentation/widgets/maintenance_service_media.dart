import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/helpers/show_net_image.dart';
import '../../../../../core/helpers/video_view.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/maintenance_service_model.dart';

bool isMaintenanceServiceVideoPath(String path) {
  final clean = path.toLowerCase().split('?').first;
  return const [
    '.mp4',
    '.mov',
    '.qt',
    '.avi',
    '.wmv',
    '.mkv',
    '.webm',
    '.m4v',
    '.3gp',
    '.3g2',
  ].any(clean.endsWith);
}

void openMaintenanceServiceMedia(
  BuildContext context, {
  required String path,
  required bool isVideo,
}) {
  final resolvedPath = path.startsWith('http://') || path.startsWith('https://')
      ? path
      : File(path).existsSync()
          ? path
          : ShowNetImage.getPhoto(path);

  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'إغلاق',
    barrierColor: Colors.black.withValues(alpha: .78),
    pageBuilder: (_, __, ___) => isVideo
        ? VideoView(videoPath: resolvedPath)
        : FullScreenZoomImage(imageUrl: resolvedPath),
  );
}

Future<void> showMaintenanceServiceDetails(
  BuildContext context,
  MaintenanceServiceModel service, {
  VoidCallback? onAdd,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 18.h),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.home_repair_service_outlined,
                    color: AppColors.primaryColor,
                    size: 24.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      service.name,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                '${service.price.toStringAsFixed(2)} شيكل',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (service.description.trim().isNotEmpty) ...[
                SizedBox(height: 12.h),
                Text(
                  'شرح الخدمة',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  service.description.trim(),
                  style: TextStyle(fontSize: 13.sp, height: 1.5),
                ),
              ],
              if (service.media.isNotEmpty) ...[
                SizedBox(height: 14.h),
                Text(
                  'الصور والفيديو',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  height: 112.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: service.media.length,
                    separatorBuilder: (_, __) => SizedBox(width: 8.w),
                    itemBuilder: (_, index) => MaintenanceServiceMediaPreview(
                      networkMedia: service.media[index],
                      width: 112.w,
                      height: 112.h,
                    ),
                  ),
                ),
              ],
              if (service.description.trim().isEmpty &&
                  service.media.isEmpty) ...[
                SizedBox(height: 14.h),
                Text(
                  'لا يوجد شرح أو وسائط مضافة لهذه الخدمة.',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
              ],
              if (onAdd != null) ...[
                SizedBox(height: 18.h),
                ElevatedButton.icon(
                  onPressed: () {
                    onAdd();
                    Navigator.pop(sheetContext);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('إضافة الخدمة لطلب الصيانة'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class MaintenanceServiceMediaPreview extends StatelessWidget {
  const MaintenanceServiceMediaPreview({
    Key? key,
    this.networkMedia,
    this.localFile,
    this.onRemove,
    this.width,
    this.height,
  })  : assert(networkMedia != null || localFile != null),
        super(key: key);

  final MaintenanceServiceMediaModel? networkMedia;
  final File? localFile;
  final VoidCallback? onRemove;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final rawPath = localFile?.path ?? networkMedia!.url;
    final isVideo = networkMedia?.isVideo ??
        isMaintenanceServiceVideoPath(localFile?.path ?? '');
    final networkUrl =
        networkMedia == null ? null : ShowNetImage.getPhoto(networkMedia!.url);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => openMaintenanceServiceMedia(
            context,
            path: networkUrl ?? rawPath,
            isVideo: isVideo,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9.r),
            child: SizedBox(
              width: width ?? 86.w,
              height: height ?? 86.h,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isVideo)
                    ColoredBox(
                      color: AppColors.primaryColor.withValues(alpha: .13),
                      child: Icon(
                        Icons.videocam_outlined,
                        color: AppColors.primaryColor,
                        size: 32.sp,
                      ),
                    )
                  else if (localFile != null)
                    Image.file(
                      localFile!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image_outlined),
                    )
                  else
                    CachedNetworkImage(
                      imageUrl: networkUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.broken_image_outlined),
                    ),
                  if (isVideo)
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (onRemove != null)
          PositionedDirectional(
            top: -7.h,
            end: -7.w,
            child: InkWell(
              onTap: onRemove,
              child: Container(
                padding: EdgeInsets.all(3.w),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 15, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
