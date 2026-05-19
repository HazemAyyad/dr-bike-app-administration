import 'dart:io';

import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

/// Returns true when the user granted camera access (or it was already granted).
Future<bool> ensureCameraPermission() async {
  var status = await Permission.camera.status;
  if (status.isGranted) return true;
  status = await Permission.camera.request();
  return status.isGranted;
}

/// Returns true when gallery / photo library access is available.
Future<bool> ensurePhotosPermission() async {
  if (Platform.isAndroid) {
    var status = await Permission.photos.status;
    if (status.isGranted) return true;
    status = await Permission.photos.request();
    if (status.isGranted) return true;

    status = await Permission.storage.status;
    if (status.isGranted) return true;
    status = await Permission.storage.request();
    return status.isGranted;
  }

  var status = await Permission.photos.status;
  if (status.isGranted) return true;
  status = await Permission.photos.request();
  return status.isGranted;
}

void showMediaPermissionDeniedSnackbar() {
  Get.snackbar(
    'error'.tr,
    'cameraPermissionDenied'.tr,
    snackPosition: SnackPosition.BOTTOM,
    duration: const Duration(seconds: 2),
  );
}
