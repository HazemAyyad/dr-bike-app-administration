import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FullScreenZoomImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenZoomImage({Key? key, required this.imageUrl})
      : super(key: key);

  Future<void> _downloadImage(BuildContext context) async {
    try {
      // اطلب صلاحيات
      if (Platform.isAndroid) {
        await Permission.storage.request();
        await Permission.manageExternalStorage.request(); // Android 11+
      }
      Get.snackbar(
        "تنبية",
        "جاري التحميل سيتم اخبارك عند الانتهاء",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 1500),
      );
      Directory dir;
      if (Platform.isAndroid) {
        // خزن الصورة داخل Pictures/اسم_التطبيق
        dir = Directory("/storage/emulated/0/Download/Doctor Bike/photos");
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      String fileName = imageUrl.split('/').last;
      String savePath = "${dir.path}/$fileName";

      await Dio().download(imageUrl, savePath);

      Get.snackbar(
        "success".tr,
        "تم التحميل في $savePath".tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 1500),
      );
    } catch (e) {
      Get.snackbar(
        "error".tr,
        "فشل التحميل: $e",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 1500),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy > 12) {
              Navigator.of(context).pop();
            }
          },
          child: Container(
            color: Colors.transparent,
            child: Center(
              child: PhotoView(
                imageProvider: NetworkImage(imageUrl),
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2.5,
                enableRotation: false,
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
            onPressed: () => Navigator.of(context).pop(),
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
            onPressed: () => _downloadImage(context)
                // ignore: use_build_context_synchronously
                .then((value) => Navigator.of(context).pop()),
          ),
        ),
      ],
    );
  }
}
