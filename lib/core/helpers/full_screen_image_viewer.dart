import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:photo_view/photo_view.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'task_media_paths.dart';
import 'video_view.dart';

class FullScreenZoomImage extends StatelessWidget {
  final String imageUrl;
  final VoidCallback? onClose;

  const FullScreenZoomImage({
    Key? key,
    required this.imageUrl,
    this.onClose,
  }) : super(key: key);

  /// يفتح الصورة بملء الشاشة مع إمكانية التكبير بالقرص.
  static void open(BuildContext context, String imageUrl) {
    Get.dialog(
      FullScreenZoomImage(
        imageUrl: imageUrl,
        onClose: () {
          if (Get.isSnackbarOpen) {
            Get.closeAllSnackbars();
          }
          if (Get.isDialogOpen == true) {
            Get.back();
          }
        },
      ),
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.88),
    );
  }

  Future<void> _downloadImage(BuildContext context) async {
    try {
      // ✅ اطلب فقط الأذونات المسموح بها
      if (Platform.isAndroid) {
        await Permission.photos.request(); // Android 13+
        await Permission.storage.request(); // للأنظمة الأقدم
      } else if (Platform.isIOS) {
        await Permission.photosAddOnly.request();
      }
      Get.snackbar(
        "تنبيه",
        "جاري تحميل الصورة...",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      // 🧭 استخدم مجلد مؤقت قبل الحفظ في المعرض
      final tempDir = await getTemporaryDirectory();
      final fileName = imageUrl.split('/').last;
      final tempPath = '${tempDir.path}/$fileName';
      // 🧩 تحميل الصورة مؤقتاً
      await Dio().download(imageUrl, tempPath);
      if (isVideoMediaPath(imageUrl)) {
        await GallerySaver.saveVideo(
          tempPath,
          albumName: "Doctor Bike",
        );
      } else {
        await GallerySaver.saveImage(
          tempPath,
          albumName: "Doctor Bike",
        );
      }
      Get.snackbar(
        "تم",
        "تم حفظ الصورة في المعرض ✅",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        "خطأ",
        "فشل التحميل: $e",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _close(BuildContext context) {
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
    if (onClose != null) {
      onClose!();
      return;
    }
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy > 12) {
              _close(context);
            }
          },
          child: isVideoMediaPath(imageUrl)
              ? VideoView(videoPath: imageUrl, dsibalBack: true)
              : Container(
                  color: Colors.black,
                  width: double.infinity,
                  height: double.infinity,
                  child: PhotoView(
                    imageProvider: NetworkImage(imageUrl),
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 4,
                    initialScale: PhotoViewComputedScale.contained,
                    enableRotation: false,
                    loadingBuilder: (context, event) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 48.sp,
                      ),
                    ),
                  ),
                ),
        ),
        // زرار إغلاق
        Positioned(
          top: 80.h,
          right: 20.w,
          child: IconButton(
            icon: Icon(
              Icons.close,
              color: Colors.red,
              size: 30.sp,
            ),
            onPressed: () => _close(context),
          ),
        ),
        // زرار تحميل
        Positioned(
          top: 80.h,
          left: 20.w,
          child: IconButton(
            icon: Icon(
              Icons.download,
              color: Colors.green,
              size: 30.sp,
            ),
            onPressed: () => _downloadImage(context),
          ),
        ),
      ],
    );
  }
}
