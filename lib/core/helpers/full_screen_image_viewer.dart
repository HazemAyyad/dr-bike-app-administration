import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenZoomImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenZoomImage({Key? key, required this.imageUrl})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy > 12) {
          Navigator.of(context).pop();
        }
      },
      child: Dismissible(
        key: const Key('dismiss'),
        direction: DismissDirection.down,
        onDismissed: (_) => Navigator.of(context).pop(),
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
    );
  }
}
