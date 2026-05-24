import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'media_permissions.dart';

/// Camera-only capture for task proof (no gallery / studio).
class CameraCaptureHelper {
  static Future<File?> captureProof(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text('takeImage'.tr),
              onTap: () => Navigator.pop(ctx, 'camera_image'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: Text('takeVideo'.tr),
              onTap: () => Navigator.pop(ctx, 'camera_video'),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return null;

    if (!await ensureCameraPermission()) {
      showMediaPermissionDeniedSnackbar();
      return null;
    }

    final picker = ImagePicker();
    XFile? picked;
    if (choice == 'camera_image') {
      picked = await picker.pickImage(source: ImageSource.camera);
    } else if (choice == 'camera_video') {
      picked = await picker.pickVideo(source: ImageSource.camera);
    }

    return picked != null ? File(picked.path) : null;
  }
}
