import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/helpers/app_failure_notice.dart';
import '../../../../../core/media/product_photo_watermark.dart';
import '../../../whatsapp_center/presentation/views/whatsapp_camera_screen.dart';

enum ProductPhotoSource { camera, gallery }

Future<ProductPhotoSource?> showProductPhotoSourceSheet(BuildContext context) {
  return showModalBottomSheet<ProductPhotoSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.camera_alt_outlined),
          title: const Text('الكاميرا'),
          subtitle: const Text('التقاط صورة مع شعار دكتور بايك'),
          onTap: () => Navigator.pop(ctx, ProductPhotoSource.camera),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: const Text('المعرض'),
          onTap: () => Navigator.pop(ctx, ProductPhotoSource.gallery),
        ),
      ]),
    ),
  );
}

Future<List<XFile>> pickProductPhotos({bool multiple = true}) async {
  final context = Get.context;
  if (context == null) return [];
  final source = await showProductPhotoSourceSheet(context);
  if (source == null) return [];
  try {
    if (source == ProductPhotoSource.camera) {
      final capture = await Get.to<WhatsAppCapture>(() =>
          const WhatsAppCameraScreen(allowVideo: false, allowGallery: false));
      if (capture == null) return [];
      return [await watermarkProductCameraPhoto(capture.path)];
    }
    final picker = ImagePicker();
    if (multiple) return await picker.pickMultiImage();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    return picked == null ? [] : [picked];
  } catch (e) {
    AppFailureNotice.show(title: 'خطأ', message: 'تعذر تجهيز صورة المنتج: $e');
    return [];
  }
}
