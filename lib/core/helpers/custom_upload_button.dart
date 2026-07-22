import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'package:doctorbike/core/helpers/media_permissions.dart';
import 'package:doctorbike/core/utils/assets_manger.dart';

import '../services/theme_service.dart';
import '../utils/app_colors.dart';
import 'dart:typed_data';

class UploadImageButton extends StatefulWidget {
  final Rx<XFile?> selectedFile;
  final double? width;
  final double? height;
  final Color? textColor;
  final String title;
  final TextStyle? titleStyle;
  final bool isVideo;

  const UploadImageButton({
    Key? key,
    this.width,
    this.height,
    this.textColor,
    required this.selectedFile,
    required this.title,
    this.titleStyle,
    this.isVideo = false,
  }) : super(key: key);

  @override
  State<UploadImageButton> createState() => _UploadImageButtonState();

  /// يفتح خيارات التصوير/المعرض (للاستدعاء من Enter في النماذج).
  static Future<void> pickFileFor(
    BuildContext context,
    Rx<XFile?> selectedFile, {
    bool isVideo = false,
  }) async {
    final picker = ImagePicker();

    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text("takeImage".tr),
                onTap: () => Navigator.pop(ctx, 'camera_image'),
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: Text("selectImage".tr),
                onTap: () => Navigator.pop(ctx, 'gallery_image'),
              ),
              if (isVideo)
                ListTile(
                  leading: const Icon(Icons.videocam),
                  title: Text("takeVideo".tr),
                  onTap: () => Navigator.pop(ctx, 'camera_video'),
                ),
              if (isVideo)
                ListTile(
                  leading: const Icon(Icons.video_library),
                  title: Text("selectVideo".tr),
                  onTap: () => Navigator.pop(ctx, 'gallery_video'),
                ),
            ],
          ),
        );
      },
    );

    XFile? pickedFile;

    if (choice == 'camera_image' || choice == 'camera_video') {
      if (!await ensureCameraPermission()) {
        showMediaPermissionDeniedSnackbar();
        return;
      }
    } else if (choice == 'gallery_image' || choice == 'gallery_video') {
      if (!await ensurePhotosPermission()) {
        showMediaPermissionDeniedSnackbar();
        return;
      }
    }

    if (choice == 'camera_image') {
      pickedFile = await picker.pickImage(source: ImageSource.camera);
    } else if (choice == 'gallery_image') {
      pickedFile = await picker.pickImage(source: ImageSource.gallery);
    } else if (choice == 'camera_video') {
      pickedFile = await picker.pickVideo(source: ImageSource.camera);
    } else if (choice == 'gallery_video') {
      pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    }

    if (pickedFile != null) {
      selectedFile.value = XFile(pickedFile.path);
    }
  }
}

class _UploadImageButtonState extends State<UploadImageButton> {
  Uint8List? _videoThumbnail;

  @override
  void didUpdateWidget(covariant UploadImageButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAndGenerateThumbnail();
  }

  Future<void> _checkAndGenerateThumbnail() async {
    final file = widget.selectedFile.value;
    if (file == null) return;

    if (_isVideo(file.path)) {
      final thumb = await VideoThumbnail.thumbnailData(
        video: file.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 400,
        quality: 75,
      );

      if (mounted) {
        setState(() => _videoThumbnail = thumb);
      }
    } else {
      setState(() => _videoThumbnail = null);
    }
  }

  bool _isVideo(String path) =>
      path.toLowerCase().endsWith('.mp4') ||
      path.toLowerCase().endsWith('.mov') ||
      path.toLowerCase().endsWith('.avi') ||
      path.toLowerCase().endsWith('.mkv');

  Future<void> pickFile(BuildContext context) async {
    await UploadImageButton.pickFileFor(
      context,
      widget.selectedFile,
      isVideo: widget.isVideo,
    );
    _checkAndGenerateThumbnail();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.selectedFile.value == null) {
          pickFile(context);
        }
      },
      child: Obx(
        () => SizedBox(
          width: double.infinity,
          height: widget.selectedFile.value != null ? 350.h : 130.h,
          child: DashedBorderContainer(
            dashWidth: 5,
            dashSpace: 5,
            strokeWidth: 1,
            radius: 4,
            child: widget.selectedFile.value != null
                ? _buildUploadedState()
                : buildInitialState(context),
          ),
        ),
      ),
    );
  }

  Widget buildInitialState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_upload, size: 40, color: AppColors.primaryColor),
        const SizedBox(height: 8),
        Text(
          widget.title.tr,
          style: widget.titleStyle ??
              Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: AppColors.primaryColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUploadedState() {
    final file = widget.selectedFile.value!;
    final isVideo = _isVideo(file.path);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (isVideo)
          (_videoThumbnail != null)
              ? Image.memory(
                  _videoThumbnail!,
                  fit: BoxFit.cover,
                )
              : const Center(child: CircularProgressIndicator())
        else
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: widget.selectedFile.value!.path.startsWith('http')
                  ? Image.network(
                      widget.selectedFile.value!.path,
                      fit: BoxFit.fill,
                    )
                  : Image.file(
                      File(widget.selectedFile.value!.path),
                      fit: BoxFit.fill,
                    ),
            ),
          ),
        if (isVideo)
          const Center(
            child: Icon(
              Icons.play_circle_fill,
              color: Colors.white,
              size: 70,
            ),
          ),
        Positioned(
          right: 4,
          top: 4,
          child: GestureDetector(
            onTap: () {
              widget.selectedFile.value = null;
              setState(() => _videoThumbnail = null);
            },
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}

// =========================================================================================================
enum MediaType { image, video, both, cameraOnly }

class MediaUploadButton extends StatefulWidget {
  final double? width;
  final double? height;
  final String title;
  final TextStyle? titleStyle;
  final void Function(List<File> files) onFilesChanged;
  final MediaType allowedType;
  final bool isShowPreview;
  final List<File> initialFiles;

  const MediaUploadButton({
    Key? key,
    this.width,
    this.height,
    required this.title,
    this.titleStyle,
    required this.onFilesChanged,
    this.allowedType = MediaType.both,
    this.isShowPreview = true,
    this.initialFiles = const [],
  }) : super(key: key);

  @override
  State<MediaUploadButton> createState() => _MediaUploadButtonState();
}

class _MediaUploadButtonState extends State<MediaUploadButton> {
  final List<File> _files = [];
  final Map<String, Uint8List?> _videoThumbnails = {};
  final Map<String, double> _progress = {};

  @override
  void initState() {
    super.initState();
    _syncInitialFiles();
    _generateThumbnails();
  }

  @override
  void didUpdateWidget(covariant MediaUploadButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_samePaths(oldWidget.initialFiles, widget.initialFiles) &&
        !_samePaths(_files, widget.initialFiles)) {
      _syncInitialFiles();
      _generateThumbnails();
    }
  }

  bool _samePaths(List<File> a, List<File> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].path != b[i].path) return false;
    }
    return true;
  }

  void _syncInitialFiles() {
    _files
      ..clear()
      ..addAll(widget.initialFiles);
  }

  void _emitFiles() {
    widget.onFilesChanged(List<File>.unmodifiable(_files));
  }

  Future<void> _pickFiles() async {
    final picker = ImagePicker();
    List<XFile> picked = [];

    switch (widget.allowedType) {
      case MediaType.image:
        final choice = await showModalBottomSheet<String>(
          context: context,
          builder: (_) => _buildImageOptions(),
        );
        if (choice == 'camera') {
          if (!await ensureCameraPermission()) {
            showMediaPermissionDeniedSnackbar();
            return;
          }
          final image = await picker.pickImage(source: ImageSource.camera);
          if (image != null) picked.add(image);
        } else if (choice == 'gallery') {
          if (!await ensurePhotosPermission()) {
            showMediaPermissionDeniedSnackbar();
            return;
          }
          final images = await picker.pickMultiImage();
          picked.addAll(images);
        }
        break;

      case MediaType.video:
        final choice = await showModalBottomSheet<String>(
          context: context,
          builder: (_) => _buildVideoOptions(),
        );
        if (choice == 'camera') {
          if (!await ensureCameraPermission()) {
            showMediaPermissionDeniedSnackbar();
            return;
          }
          final video = await picker.pickVideo(source: ImageSource.camera);
          if (video != null) picked.add(video);
        } else if (choice == 'gallery') {
          if (!await ensurePhotosPermission()) {
            showMediaPermissionDeniedSnackbar();
            return;
          }
          final video = await picker.pickVideo(source: ImageSource.gallery);
          if (video != null) picked.add(video);
        }
        break;

      case MediaType.both:
        final choice = await showModalBottomSheet<String>(
          context: context,
          builder: (_) => _buildSourceOptionsBoth(),
        );

        if (choice == 'camera_image' || choice == 'camera_video') {
          if (!await ensureCameraPermission()) {
            showMediaPermissionDeniedSnackbar();
            return;
          }
        } else if (choice == 'gallery_image' || choice == 'gallery_video') {
          if (!await ensurePhotosPermission()) {
            showMediaPermissionDeniedSnackbar();
            return;
          }
        }

        if (choice == 'camera_image') {
          final image = await picker.pickImage(source: ImageSource.camera);
          if (image != null) picked.add(image);
        } else if (choice == 'gallery_image') {
          final images = await picker.pickMultiImage();
          picked.addAll(images);
        } else if (choice == 'camera_video') {
          final video = await picker.pickVideo(source: ImageSource.camera);
          if (video != null) picked.add(video);
        } else if (choice == 'gallery_video') {
          final video = await picker.pickVideo(source: ImageSource.gallery);
          if (video != null) picked.add(video);
        }
        break;

      case MediaType.cameraOnly:
        final choice = await showModalBottomSheet<String>(
          context: context,
          builder: (_) => _buildCameraOnlyOptions(),
        );
        if (choice == 'camera_image' || choice == 'camera_video') {
          if (!await ensureCameraPermission()) {
            showMediaPermissionDeniedSnackbar();
            return;
          }
        }
        if (choice == 'camera_image') {
          final image = await picker.pickImage(source: ImageSource.camera);
          if (image != null) picked.add(image);
        } else if (choice == 'camera_video') {
          final video = await picker.pickVideo(source: ImageSource.camera);
          if (video != null) picked.add(video);
        }
        break;
    }

    if (picked.isNotEmpty) {
      setState(() {
        _files.addAll(picked.map((e) => File(e.path)));
      });
      _emitFiles();
      _generateThumbnails();
    }
  }

  Widget _buildImageOptions() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: Text("takeImage".tr),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: Text("selectImage".tr),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoOptions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.videocam),
          title: Text("takeVideo".tr),
          onTap: () => Navigator.pop(context, 'camera'),
        ),
        ListTile(
          leading: const Icon(Icons.video_library),
          title: Text("selectVideo".tr),
          onTap: () => Navigator.pop(context, 'gallery'),
        ),
      ],
    );
  }

  Widget _buildSourceOptionsBoth() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.camera_alt),
          title: Text("takeImage".tr),
          onTap: () => Navigator.pop(context, 'camera_image'),
        ),
        ListTile(
          leading: const Icon(Icons.image),
          title: Text("selectImage".tr),
          onTap: () => Navigator.pop(context, 'gallery_image'),
        ),
        ListTile(
          leading: const Icon(Icons.videocam),
          title: Text("takeVideo".tr),
          onTap: () => Navigator.pop(context, 'camera_video'),
        ),
        ListTile(
          leading: const Icon(Icons.video_library),
          title: Text("selectVideo".tr),
          onTap: () => Navigator.pop(context, 'gallery_video'),
        ),
      ],
    );
  }

  Widget _buildCameraOnlyOptions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.camera_alt),
          title: Text('takeImage'.tr),
          onTap: () => Navigator.pop(context, 'camera_image'),
        ),
        ListTile(
          leading: const Icon(Icons.videocam),
          title: Text('takeVideo'.tr),
          onTap: () => Navigator.pop(context, 'camera_video'),
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

      Future(() async {
        for (int i = 1; i <= 10; i++) {
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) setState(() => _progress[file.path] = i / 10);
        }

        final thumb = await VideoThumbnail.thumbnailData(
          video: file.path,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 128,
          quality: 50,
        );

        if (mounted) {
          setState(() {
            _videoThumbnails[file.path] = thumb;
            _progress.remove(file.path);
          });
        }
      });
    }
  }

  bool _isImage(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith(".png") ||
        ext.endsWith(".jpg") ||
        ext.endsWith(".jpeg") ||
        ext.startsWith('http');
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.height ?? (_files.isEmpty ? 122.h : 116.h);
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: height,
      child: _files.isEmpty || !widget.isShowPreview
          ? GestureDetector(
              onTap: _pickFiles,
              child: DashedBorderContainer(
                dashWidth: 5,
                dashSpace: 5,
                strokeWidth: 1,
                radius: 8,
                child: buildInitialState(widget.title),
              ),
            )
          : _buildPreviewList(),
    );
  }

  Widget buildInitialState(String title) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          AssetsManager.upLoadIcon,
          height: 26.h,
          width: 30.w,
        ),
        SizedBox(height: 6.h),
        Text(
          title.tr,
          style: widget.titleStyle ??
              Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor2
                        : AppColors.secondaryColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPreviewList() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _files.length + 1,
      separatorBuilder: (_, __) => SizedBox(width: 8.w),
      itemBuilder: (context, i) {
        if (i == _files.length) {
          return GestureDetector(
            onTap: _pickFiles,
            child: SizedBox(
              width: 104.w,
              child: DashedBorderContainer(
                dashWidth: 5,
                dashSpace: 5,
                strokeWidth: 1,
                radius: 8,
                child: buildInitialState(widget.title),
              ),
            ),
          );
        }

        final file = _files[i];
        final path = file.path;
        return SizedBox(
          width: 104.w,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: _buildPreview(file),
              ),
              Positioned(
                right: 4.w,
                top: 4.h,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _files.removeAt(i);
                      _progress.remove(path);
                      _videoThumbnails.remove(path);
                    });
                    _emitFiles();
                  },
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .55),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 15.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreview(File file) {
    final path = file.path;
    if (_isImage(path)) {
      if (path.startsWith('http')) {
        return Image.network(path, fit: BoxFit.cover);
      }
      return Image.file(file, fit: BoxFit.cover);
    }
    if (_videoThumbnails[path] != null) {
      return Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          Image.memory(_videoThumbnails[path]!, fit: BoxFit.cover),
          const Icon(Icons.play_circle_fill, size: 32, color: Colors.white),
        ],
      );
    }
    final progress = _progress[path] ?? 0;
    return Container(
      color: Colors.grey[300],
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: CircularProgressIndicator(value: progress),
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
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
