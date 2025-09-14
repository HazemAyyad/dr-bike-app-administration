import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenZoomImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenZoomImage({Key? key, required this.imageUrl})
      : super(key: key);

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
      ],
    );
  }
}
