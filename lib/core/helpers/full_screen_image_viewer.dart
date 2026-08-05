import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:photo_view/photo_view.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'sweet_success_dialog.dart';
import 'task_media_paths.dart';
import 'video_view.dart';

class FullScreenZoomImage extends StatelessWidget {
  final String imageUrl;
  final List<String>? imageUrls;
  final List<String>? downloadFolderSegments;
  final String? title;
  final int initialIndex;
  final VoidCallback? onClose;

  const FullScreenZoomImage({
    Key? key,
    required this.imageUrl,
    this.imageUrls,
    this.downloadFolderSegments,
    this.title,
    this.initialIndex = 0,
    this.onClose,
  }) : super(key: key);

  /// يفتح الصورة بملء الشاشة مع إمكانية التكبير بالقرص.
  static void open(
    BuildContext context,
    String imageUrl, {
    List<String>? imageUrls,
    List<String>? downloadFolderSegments,
    String? title,
    int initialIndex = 0,
  }) {
    Get.dialog(
      FullScreenZoomImage(
        imageUrl: imageUrl,
        imageUrls: imageUrls,
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
      barrierColor: Colors.black.withValues(alpha: 0.88),
    );
  }

  Future<bool> _downloadMedia(
    BuildContext context,
    String mediaUrl, {
    bool showFeedback = true,
  }) async {
    try {
      await _requestSavePermission();
      final sourceFile = File(mediaUrl);
      String savePath;
      // ✅ اطلب فقط الأذونات المسموح بها
      if (showFeedback) {
        Get.snackbar(
          "تنبيه",
          "جاري تحميل الملف...",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
      // 🧭 استخدم مجلد مؤقت قبل الحفظ في المعرض
      final tempDir = await getTemporaryDirectory();
      final fileName = mediaUrl.split('/').last;
      final tempPath = '${tempDir.path}/$fileName';
      // 🧩 تحميل الصورة مؤقتاً
      if (_isNetworkMedia(mediaUrl)) {
        await Dio().download(mediaUrl, tempPath);
        savePath = tempPath;
      } else if (await sourceFile.exists()) {
        savePath = sourceFile.path;
      } else {
        throw Exception('file not found');
      }
      if (isVideoMediaPath(mediaUrl)) {
        await GallerySaver.saveVideo(
          savePath,
          albumName: "Doctor Bike",
        );
      } else {
        await GallerySaver.saveImage(
          savePath,
          albumName: "Doctor Bike",
        );
      }
      if (showFeedback) {
        showSweetSuccessDialog(
          title: "تم",
          message: "تم حفظ الملف في المعرض ✅",
        );
      }
      return true;
    } catch (e) {
      if (showFeedback) {
        Get.snackbar(
          "خطأ",
          "فشل التحميل: $e",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
      return false;
    }
  }

  Future<void> _downloadAllMedia(
    BuildContext context,
    List<String> mediaUrls,
  ) async {
    final files = _normalizeMediaList(mediaUrls);
    if (files.isEmpty) return;

    var savedCount = 0;
    Directory? targetDir;
    await _requestSavePermission();
    Get.snackbar(
      "تنبيه",
      "جاري تحميل كل الملفات...",
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );

    try {
      targetDir = await _prepareDownloadDirectory(downloadFolderSegments);
      for (var i = 0; i < files.length; i++) {
        final mediaUrl = files[i];
        final file = File(
          '${targetDir.path}/${_downloadFileName(mediaUrl, i + 1)}',
        );
        if (_isNetworkMedia(mediaUrl)) {
          await Dio().download(mediaUrl, file.path);
        } else {
          final sourceFile = File(mediaUrl);
          if (!await sourceFile.exists()) {
            throw Exception('file not found');
          }
          await sourceFile.copy(file.path);
        }
        savedCount++;
      }
    } catch (e) {
      Get.snackbar(
        "خطأ",
        "فشل تحميل بعض الملفات: $e",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }

    showSweetSuccessDialog(
      title: "تم",
      message: "تم حفظ $savedCount من ${files.length} ملف",
      subtitle: targetDir?.path,
    );
  }

  Future<void> _printImage(BuildContext context) async {
    await _printMedia(context, imageUrl);
  }

  Future<void> _printMedia(BuildContext context, String mediaUrl) async {
    if (isVideoMediaPath(mediaUrl)) {
      Get.snackbar(
        "تنبيه",
        "الطباعة متاحة للصور فقط",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    try {
      Get.snackbar(
        "تنبيه",
        "جاري تجهيز الصورة للطباعة...",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      final response = await Dio().get<List<int>>(
        mediaUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data == null || data.isEmpty) {
        throw Exception('empty image');
      }

      final bytes = Uint8List.fromList(data);
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(18),
          build: (context) {
            return pw.Center(
              child: pw.Image(
                pw.MemoryImage(bytes),
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (_) async => doc.save());
    } catch (e) {
      Get.snackbar(
        "خطأ",
        "فشل تجهيز الطباعة: $e",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _close(BuildContext context) {
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
    if (onClose != null) {
      onClose!();
      return;
    }
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  List<String> _normalizeMediaList(List<String> rawItems) {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in rawItems) {
      final value = raw.trim();
      if (value.isEmpty) continue;
      final lower = value.toLowerCase();
      if (lower == 'no image' || lower == 'no img' || lower == 'null') {
        continue;
      }
      if (seen.add(value)) out.add(value);
    }
    return out;
  }

  Future<void> _requestSavePermission() async {
    if (Platform.isAndroid) {
      await Permission.photos.request();
      await Permission.storage.request();
    } else if (Platform.isIOS) {
      await Permission.photosAddOnly.request();
    }
  }

  bool _isNetworkMedia(String mediaUrl) {
    final lower = mediaUrl.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  Future<Directory> _prepareDownloadDirectory(List<String>? rawSegments) async {
    final segments = [
      'Doctor Bike',
      ...(rawSegments ?? const <String>[]),
    ].map(_safePathSegment).where((segment) => segment.isNotEmpty).toList();

    Directory directory;
    if (Platform.isAndroid) {
      directory =
          Directory('/storage/emulated/0/Download/${segments.join('/')}');
    } else {
      final appDocDir = await getApplicationDocumentsDirectory();
      directory = Directory('${appDocDir.path}/${segments.join('/')}');
    }

    try {
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    } catch (_) {
      final appDocDir = await getApplicationDocumentsDirectory();
      final fallbackDir = Directory('${appDocDir.path}/${segments.join('/')}');
      if (!await fallbackDir.exists()) {
        await fallbackDir.create(recursive: true);
      }
      return fallbackDir;
    }
  }

  String _safePathSegment(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '-')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  String _downloadFileName(String mediaUrl, int index) {
    final uri = Uri.tryParse(mediaUrl);
    final lastSegment = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : mediaUrl.split('/').last;
    final decoded = Uri.decodeComponent(lastSegment.split('?').first).trim();
    final safeName = _safePathSegment(decoded);
    if (safeName.isNotEmpty && safeName.contains('.')) {
      return '${index.toString().padLeft(2, '0')}_$safeName';
    }

    final extension = isVideoMediaPath(mediaUrl) ? '.mp4' : '.jpg';
    return '${index.toString().padLeft(2, '0')}_media$extension';
  }

  @override
  Widget build(BuildContext context) {
    final mediaUrls = _normalizeMediaList(imageUrls ?? [imageUrl]);
    if (mediaUrls.length <= 1) {
      return _SingleFullScreenMedia(
        imageUrl: mediaUrls.isEmpty ? imageUrl : mediaUrls.first,
        title: title ?? _fallbackTitle(downloadFolderSegments),
        onClose: () => _close(context),
        onDownload: () => _downloadMedia(
          context,
          mediaUrls.isEmpty ? imageUrl : mediaUrls.first,
        ),
        onPrint: () => _printImage(context),
      );
    }

    final safeInitialIndex = initialIndex.clamp(0, mediaUrls.length - 1);
    return _FullScreenMediaGallery(
      mediaUrls: mediaUrls,
      initialIndex: safeInitialIndex,
      title: title ?? _fallbackTitle(downloadFolderSegments),
      onClose: () => _close(context),
      onDownload: (url) => _downloadMedia(context, url),
      onDownloadAll: () => _downloadAllMedia(context, mediaUrls),
      onPrint: _printMedia,
    );
  }

  String? _fallbackTitle(List<String>? segments) {
    if (segments == null || segments.isEmpty) return null;
    for (final segment in segments.reversed) {
      final value = segment.trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }
}

class _SingleFullScreenMedia extends StatefulWidget {
  const _SingleFullScreenMedia({
    required this.imageUrl,
    required this.title,
    required this.onClose,
    required this.onDownload,
    required this.onPrint,
  });

  final String imageUrl;
  final String? title;
  final VoidCallback onClose;
  final VoidCallback onDownload;
  final Future<void> Function() onPrint;

  @override
  State<_SingleFullScreenMedia> createState() => _SingleFullScreenMediaState();
}

class _SingleFullScreenMediaState extends State<_SingleFullScreenMedia> {
  Timer? _hideControlsTimer;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _scheduleHideControls();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHideControls();
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(
      const Duration(seconds: 3),
      () {
        if (mounted) setState(() => _showControls = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = isVideoMediaPath(widget.imageUrl);

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(0, 112.h, 0, 96.h),
          child: isVideo
              ? VideoView(videoPath: widget.imageUrl)
              : Container(
                  color: Colors.black,
                  width: double.infinity,
                  height: double.infinity,
                  child: PhotoView(
                    imageProvider: _mediaImageProvider(widget.imageUrl),
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 4,
                    initialScale: PhotoViewComputedScale.contained,
                    enableRotation: false,
                    enablePanAlways: true,
                    gestureDetectorBehavior: HitTestBehavior.opaque,
                    onTapUp: (_, __, ___) => _toggleControls(),
                    loadingBuilder: (context, event) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 48.sp,
                      ),
                    ),
                  ),
                ),
        ),
        _ViewerChrome(
          visible: _showControls,
          title: widget.title,
          counterText: null,
          showDownloadAll: false,
          showPrint: !isVideo,
          onClose: widget.onClose,
          onDownload: widget.onDownload,
          onDownloadAll: null,
          onPrint: widget.onPrint,
        ),
      ],
    );
  }
}

class _ViewerChrome extends StatelessWidget {
  const _ViewerChrome({
    required this.visible,
    required this.title,
    required this.counterText,
    required this.showDownloadAll,
    required this.showPrint,
    required this.onClose,
    required this.onDownload,
    required this.onDownloadAll,
    required this.onPrint,
  });

  final bool visible;
  final String? title;
  final String? counterText;
  final bool showDownloadAll;
  final bool showPrint;
  final VoidCallback onClose;
  final VoidCallback onDownload;
  final VoidCallback? onDownloadAll;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      child: IgnorePointer(
        ignoring: !visible,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(14.w, 54.h, 14.w, 12.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.74),
                      Colors.black.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    _GalleryArrowButton(
                      icon: Icons.close,
                      tooltip: 'إغلاق',
                      onPressed: onClose,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        title?.isNotEmpty == true ? title! : 'عرض الصور',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (counterText != null) ...[
                      SizedBox(width: 8.w),
                      _ViewerCounter(text: counterText!),
                    ],
                  ],
                ),
              ),
            ),
            Positioned(
              left: 14.w,
              right: 14.w,
              bottom: 18.h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ViewerActionButton(
                    icon: Icons.download,
                    label: 'الحالي',
                    onPressed: onDownload,
                  ),
                  if (showDownloadAll) ...[
                    SizedBox(width: 8.w),
                    _ViewerActionButton(
                      icon: Icons.download_for_offline_outlined,
                      label: 'الكل',
                      onPressed: onDownloadAll!,
                    ),
                  ],
                  if (showPrint) ...[
                    SizedBox(width: 8.w),
                    _ViewerActionButton(
                      icon: Icons.print,
                      label: 'طباعة',
                      onPressed: onPrint,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenMediaGallery extends StatefulWidget {
  const _FullScreenMediaGallery({
    required this.mediaUrls,
    required this.initialIndex,
    required this.title,
    required this.onClose,
    required this.onDownload,
    required this.onDownloadAll,
    required this.onPrint,
  });

  final List<String> mediaUrls;
  final int initialIndex;
  final String? title;
  final VoidCallback onClose;
  final ValueChanged<String> onDownload;
  final VoidCallback onDownloadAll;
  final Future<void> Function(BuildContext context, String mediaUrl) onPrint;

  @override
  State<_FullScreenMediaGallery> createState() =>
      _FullScreenMediaGalleryState();
}

class _FullScreenMediaGalleryState extends State<_FullScreenMediaGallery> {
  late final PageController _pageController;
  late int _currentIndex;
  Timer? _hideControlsTimer;
  bool _showControls = true;

  String get _currentUrl => widget.mediaUrls[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _scheduleHideControls();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHideControls();
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(
      const Duration(seconds: 3),
      () {
        if (mounted) setState(() => _showControls = false);
      },
    );
  }

  void _goTo(int delta) {
    final next = (_currentIndex + delta) % widget.mediaUrls.length;
    final target = next < 0 ? widget.mediaUrls.length - 1 : next;
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
    setState(() => _showControls = true);
    _scheduleHideControls();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(0, 104.h, 0, 152.h),
          child: Container(
            color: Colors.black,
            width: double.infinity,
            height: double.infinity,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.mediaUrls.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                final url = widget.mediaUrls[index];
                return isVideoMediaPath(url)
                    ? VideoView(videoPath: url)
                    : PhotoView(
                        key: ValueKey(url),
                        imageProvider: _mediaImageProvider(url),
                        backgroundDecoration: const BoxDecoration(
                          color: Colors.black,
                        ),
                        minScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 4,
                        initialScale: PhotoViewComputedScale.contained,
                        enableRotation: false,
                        enablePanAlways: true,
                        gestureDetectorBehavior: HitTestBehavior.opaque,
                        onTapUp: (_, __, ___) => _toggleControls(),
                        loadingBuilder: (context, event) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 48.sp,
                          ),
                        ),
                      );
              },
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: _showControls ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: IgnorePointer(
            ignoring: !_showControls,
            child: Stack(
              children: [
                Positioned(
                  left: 10.w,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _GalleryArrowButton(
                      icon: Icons.chevron_right,
                      tooltip: 'التالي',
                      onPressed: () => _goTo(1),
                    ),
                  ),
                ),
                Positioned(
                  right: 10.w,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _GalleryArrowButton(
                      icon: Icons.chevron_left,
                      tooltip: 'السابق',
                      onPressed: () => _goTo(-1),
                    ),
                  ),
                ),
                Positioned(
                  left: 12.w,
                  right: 12.w,
                  bottom: 76.h,
                  child: _ThumbnailStrip(
                    mediaUrls: widget.mediaUrls,
                    currentIndex: _currentIndex,
                    onSelected: (index) {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      );
                      setState(() => _showControls = true);
                      _scheduleHideControls();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        _ViewerChrome(
          visible: _showControls,
          title: widget.title,
          counterText: '${_currentIndex + 1} / ${widget.mediaUrls.length}',
          showDownloadAll: true,
          showPrint: !isVideoMediaPath(_currentUrl),
          onClose: widget.onClose,
          onDownload: () => widget.onDownload(_currentUrl),
          onDownloadAll: widget.onDownloadAll,
          onPrint: () => widget.onPrint(context, _currentUrl),
        ),
      ],
    );
  }
}

class _GalleryArrowButton extends StatelessWidget {
  const _GalleryArrowButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: Tooltip(
        message: tooltip ?? '',
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 34.sp),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _ViewerActionButton extends StatelessWidget {
  const _ViewerActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 19.sp),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewerCounter extends StatelessWidget {
  const _ViewerCounter({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ThumbnailStrip extends StatelessWidget {
  const _ThumbnailStrip({
    required this.mediaUrls,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<String> mediaUrls;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: mediaUrls.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final url = mediaUrls[index];
          final selected = index == currentIndex;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 58.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: selected ? Colors.white : Colors.white30,
                  width: selected ? 2 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: isVideoMediaPath(url)
                  ? const ColoredBox(
                      color: Colors.black54,
                      child: Icon(
                        Icons.play_circle_outline_rounded,
                        color: Colors.white,
                      ),
                    )
                  : Image(
                      image: _mediaImageProvider(url),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

ImageProvider _mediaImageProvider(String mediaUrl) {
  final lower = mediaUrl.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return CachedNetworkImageProvider(mediaUrl);
  }
  return FileImage(File(mediaUrl));
}
