import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/helpers/show_net_image.dart';

void openProductImageViewer(
  BuildContext context,
  String imageUrl, {
  List<String>? imageUrls,
  List<String>? downloadFolderSegments,
  String? title,
  int initialIndex = 0,
}) {
  final original = ShowNetImage.getPhoto(imageUrl);
  final galleryImages = (imageUrls ?? <String>[])
      .map(ShowNetImage.getPhoto)
      .where((url) => url.trim().isNotEmpty && url != 'no image')
      .toList();

  if (original.isEmpty || imageUrl.trim().isEmpty || imageUrl == 'no image') {
    return;
  }

  Get.dialog(
    FullScreenZoomImage(
      imageUrl: original,
      imageUrls: galleryImages.isEmpty ? null : galleryImages,
      downloadFolderSegments: downloadFolderSegments,
      title: title,
      initialIndex: initialIndex,
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
