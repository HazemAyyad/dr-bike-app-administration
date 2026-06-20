import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/helpers/show_net_image.dart';

void openProductImageViewer(BuildContext context, String imageUrl) {
  final original = ShowNetImage.getPhoto(imageUrl);
  if (original.isEmpty || imageUrl.trim().isEmpty || imageUrl == 'no image') {
    return;
  }

  Get.dialog(
    FullScreenZoomImage(
      imageUrl: original,
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
    barrierColor: Get.theme.colorScheme.scrim.withAlpha(128),
  );
}
