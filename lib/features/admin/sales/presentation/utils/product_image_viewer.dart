import 'package:flutter/material.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/helpers/show_net_image.dart';

void openProductImageViewer(BuildContext context, String imageUrl) {
  final original = ShowNetImage.getPhoto(imageUrl);
  if (original.isEmpty || imageUrl.trim().isEmpty || imageUrl == 'no image') {
    return;
  }

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withAlpha(128),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, anim1, anim2) {
      return FullScreenZoomImage(imageUrl: original);
    },
  );
}
