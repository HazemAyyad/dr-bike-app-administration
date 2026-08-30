import 'dart:io';

import 'package:get/get.dart';

import '../../../whatsapp_center/presentation/views/whatsapp_camera_screen.dart';

Future<File?> captureFinancialMedia({
  bool allowPhoto = true,
  bool allowVideo = true,
}) async {
  final capture = await Get.to<WhatsAppCapture>(
    () => WhatsAppCameraScreen(
      allowPhoto: allowPhoto,
      allowVideo: allowVideo,
    ),
  );
  if (capture == null || capture.path.trim().isEmpty) return null;
  return File(capture.path);
}
