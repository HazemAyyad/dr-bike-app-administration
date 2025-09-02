import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'package:doctorbike/core/utils/assets_manger.dart';

import '../services/theme_service.dart';
import '../utils/app_colors.dart';
import 'dart:typed_data';

class UploadImageButton extends StatelessWidget {
  final Rx<XFile?> selectedFile;
  final double? width;
  final double? height;
  final Color? textColor;
  final String title;
  final TextStyle? titleStyle;

  const UploadImageButton({
    Key? key,
    this.width,
    this.height,
    this.textColor,
    required this.selectedFile,
    required this.title,
    this.titleStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (selectedFile.value == null) {
          pickFile();
        }
      },
      child: Obx(
        () => SizedBox(
          width: double.infinity,
          height: selectedFile.value != null ? 350.h : 130.h,
          child: DashedBorderContainer(
            dashWidth: 5,
            dashSpace: 5,
            strokeWidth: 1,
            radius: 4,
            child: Obx(
              () {
                if (selectedFile.value != null) {
                  return _buildUploadedState();
                } else {
                  return buildInitialState(context);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pickFile() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      selectedFile.value = XFile(pickedFile.path);
    }
  }

  Widget buildInitialState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 15.h),
        Image.asset(
          AssetsManger.upLoadIcon,
          height: 32.h,
          width: 37.w,
        ),
        SizedBox(height: 8),
        Text(
          title.tr,
          style: titleStyle ??
              Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor2
                        : AppColors.secondaryColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
        SizedBox(height: 15.h),
      ],
    );
  }

  Widget _buildUploadedState() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: selectedFile.value!.path.startsWith('http')
                ? Image.network(
                    selectedFile.value!.path,
                    fit: BoxFit.fill,
                  )
                : Image.file(
                    File(selectedFile.value!.path),
                    fit: BoxFit.fill,
                  ),
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: GestureDetector(
            onTap: () => selectedFile.value = null,
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =========================================================================================================
enum MediaType { image, video, both }

class MediaUploadButton extends StatefulWidget {
  final double? width;
  final double? height;
  final String title;
  final TextStyle? titleStyle;
  final void Function(List<File> files) onFilesChanged;
  final MediaType allowedType;

  const MediaUploadButton({
    Key? key,
    this.width,
    this.height,
    required this.title,
    this.titleStyle,
    required this.onFilesChanged,
    this.allowedType = MediaType.both,
  }) : super(key: key);

  @override
  State<MediaUploadButton> createState() => _MediaUploadButtonState();
}

class _MediaUploadButtonState extends State<MediaUploadButton> {
  final List<File> _files = [];
  final Map<String, Uint8List?> _videoThumbnails = {};
  final Map<String, double> _progress = {};

  Future<void> _pickFiles() async {
    final picker = ImagePicker();
    List<XFile>? picked = [];

    switch (widget.allowedType) {
      case MediaType.image:
        picked = await picker.pickMultiImage();
        break;
      case MediaType.video:
        final video = await picker.pickVideo(source: ImageSource.gallery);
        if (video != null) picked.add(video);
        break;
      case MediaType.both:
        final choice = await showModalBottomSheet<MediaType>(
          context: context,
          builder: (_) => _buildSourceOptions(),
        );
        if (choice == MediaType.image) {
          picked = await picker.pickMultiImage();
        } else if (choice == MediaType.video) {
          final video = await picker.pickVideo(source: ImageSource.gallery);
          if (video != null) picked.add(video);
        }
        break;
    }

    if (picked.isNotEmpty) {
      setState(() {
        _files.addAll(picked!.map((e) => File(e.path)));
      });
      widget.onFilesChanged(_files);
      _generateThumbnails();
    }
  }

  Widget _buildSourceOptions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.image),
          title: Text(
            "selectImage".tr,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
          ),
          onTap: () => Navigator.pop(context, MediaType.image),
        ),
        ListTile(
          leading: const Icon(Icons.video_collection),
          title: Text(
            "selectVideo".tr,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
          ),
          onTap: () => Navigator.pop(context, MediaType.video),
        ),
      ],
    );
  }

  void _generateThumbnails() {
    for (final file in _files) {
      if (_isImage(file.path) || _videoThumbnails.containsKey(file.path)) {
        continue;
      }

      _progress[file.path] = 0;
      _videoThumbnails[file.path] = null;

      // simulate progress loading
      Future(() async {
        for (int i = 1; i <= 10; i++) {
          await Future.delayed(const Duration(milliseconds: 100));
          setState(() => _progress[file.path] = i / 10);
        }

        final thumb = await VideoThumbnail.thumbnailData(
          video: file.path,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 128,
          quality: 50,
        );

        setState(() {
          _videoThumbnails[file.path] = thumb;
          _progress.remove(file.path);
        });
      });
    }
  }

  bool _isImage(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith(".png") ||
        ext.endsWith(".jpg") ||
        ext.endsWith(".jpeg");
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickFiles,
      child: SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height ?? 150,
        child: DashedBorderContainer(
          dashWidth: 5,
          dashSpace: 5,
          strokeWidth: 1,
          radius: 4,
          child: _files.isEmpty
              ? buildInitialState(widget.title)
              : _buildPreviewList(),
        ),
      ),
    );
  }

  Widget buildInitialState(String title) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 15.h),
        Image.asset(
          AssetsManger.upLoadIcon,
          height: 32.h,
          width: 37.w,
        ),
        SizedBox(height: 8),
        Text(
          title.tr,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor2
                    : AppColors.secondaryColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
        SizedBox(height: 15.h),
      ],
    );
  }

  Widget _buildPreviewList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${"filesSelected".tr} : ${_files.length}',
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor2
                    : AppColors.secondaryColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
              ),
        ),
        const SizedBox(height: 8),
        Flexible(
          child: SizedBox(
            height: 100.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _files.length,
              itemBuilder: (context, i) {
                final file = _files[i];
                final path = file.path;

                Widget preview;

                if (_isImage(path)) {
                  preview = Image.file(file,
                      width: 80.w, height: 80.h, fit: BoxFit.cover);
                } else if (_videoThumbnails[path] != null) {
                  preview = Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.memory(_videoThumbnails[path]!,
                          width: 80.w, height: 80.h, fit: BoxFit.cover),
                      const Icon(Icons.play_circle_fill,
                          size: 32, color: Colors.white),
                    ],
                  );
                } else {
                  final progress = _progress[path] ?? 0;
                  preview = Container(
                    width: 80.w,
                    height: 80.h,
                    color: Colors.grey[300],
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(value: progress),
                        ),
                        Text('${(progress * 100).toInt()}%',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: Stack(
                    children: [
                      preview,
                      Positioned(
                        right: 2,
                        top: 2,
                        child: GestureDetector(
                          onTap: () {
                            setState(
                              () {
                                _files.removeAt(i);
                                _progress.remove(path);
                                _videoThumbnails.remove(path);
                              },
                            );
                            widget.onFilesChanged(_files);
                          },
                          child: const Icon(Icons.close, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class DashedBorderContainer extends StatelessWidget {
  final Widget child;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;
  final double radius;

  const DashedBorderContainer({
    Key? key,
    required this.child,
    this.dashWidth = 5,
    this.dashSpace = 5,
    this.strokeWidth = 1,
    this.radius = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: Colors.grey,
        dashWidth: dashWidth,
        dashSpace: dashSpace,
        strokeWidth: strokeWidth,
        radius: radius,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: child,
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;
  final double radius;

  DashedBorderPainter({
    this.color = Colors.grey,
    this.dashWidth = 5,
    this.dashSpace = 5,
    this.strokeWidth = 1,
    this.radius = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (radius > 0) {
      path.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));
    } else {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    final dashPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0;
      while (distance < pathMetric.length) {
        final nextDistance = distance + dashWidth;
        final extractPath = pathMetric.extractPath(
          distance,
          nextDistance > pathMetric.length ? pathMetric.length : nextDistance,
        );
        canvas.drawPath(extractPath, dashPaint);
        distance = nextDistance + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}
