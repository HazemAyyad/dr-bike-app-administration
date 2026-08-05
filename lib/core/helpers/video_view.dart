import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

import 'sweet_success_dialog.dart';

class VideoView extends StatefulWidget {
  const VideoView({
    Key? key,
    required this.videoPath,
    this.dsibalBack,
  }) : super(key: key);

  final String videoPath;
  final bool? dsibalBack;

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  VideoPlayerController? _controller;
  Timer? _hideControlsTimer;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isLocalPlayback = false;
  bool _isFastForwarding = false;
  int _renderedSecond = -1;

  static const int _skipSeconds = 10;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final path = widget.videoPath.isEmpty
          ? 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4'
          : widget.videoPath.trim();

      final VideoPlayerController controller;
      var isLocalPlayback = false;
      if (path.startsWith('http://') || path.startsWith('https://')) {
        final cachedVideo = await _networkCachedVideoController(path);
        controller = cachedVideo.controller;
        isLocalPlayback = cachedVideo.isLocalFile;
      } else {
        final file = File(path);
        if (!file.existsSync()) return;
        controller = VideoPlayerController.file(file);
        isLocalPlayback = true;
      }

      await controller.initialize();
      controller.addListener(_videoListener);

      if (!mounted) {
        controller.removeListener(_videoListener);
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isPlaying = controller.value.isPlaying;
        _isLocalPlayback = isLocalPlayback;
      });
    } catch (_) {
      if (mounted) setState(() => _controller = null);
    }
  }

  Future<_CachedVideoController> _networkCachedVideoController(
      String url) async {
    final cacheManager = _videoCacheManager;
    final cacheKey = _videoCacheKey(url);

    try {
      final cached = await cacheManager.getFileFromCache(cacheKey);
      final file = cached?.file;
      if (file != null && await file.exists()) {
        return _CachedVideoController(
          VideoPlayerController.file(file),
          isLocalFile: true,
        );
      }
    } catch (_) {
      // Fall back to streaming if the cache lookup fails.
    }

    _cacheVideoInBackground(url, cacheKey);
    return _CachedVideoController(
      VideoPlayerController.networkUrl(Uri.parse(Uri.encodeFull(url))),
      isLocalFile: false,
    );
  }

  Future<void> _cacheVideoInBackground(String url, String cacheKey) async {
    try {
      await _videoCacheManager.downloadFile(url, key: cacheKey);
    } catch (_) {
      // Streaming should keep working even if background caching fails.
    }
  }

  String _videoCacheKey(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return url;

    final normalized = uri.replace(query: '', fragment: '');
    return normalized.toString();
  }

  void _videoListener() {
    final controller = _controller;
    if (controller == null || !mounted) return;

    final value = controller.value;
    final second = value.position.inSeconds;
    final playingChanged = _isPlaying != value.isPlaying;
    final secondChanged = _renderedSecond != second;

    if (value.position >= value.duration && value.duration > Duration.zero) {
      controller.pause();
    }

    if (playingChanged || secondChanged) {
      setState(() {
        _isPlaying = value.isPlaying;
        _renderedSecond = second;
      });
    }
  }

  void _handleSurfaceTap() {
    _hideControlsTimer?.cancel();
    if (!_showControls) {
      setState(() => _showControls = true);
      return;
    }

    _hideControlsTimer = Timer(
      const Duration(seconds: 1),
      () {
        if (mounted) setState(() => _showControls = false);
      },
    );
  }

  void _showControlsNow() {
    _hideControlsTimer?.cancel();
    if (mounted) setState(() => _showControls = true);
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
        _isPlaying = false;
        _showControls = true;
      } else {
        controller.play();
        _isPlaying = true;
      }
    });
  }

  void _skipBy(int seconds) {
    final controller = _controller;
    if (controller == null) return;

    final duration = controller.value.duration;
    final target = controller.value.position + Duration(seconds: seconds);
    final bounded = target < Duration.zero
        ? Duration.zero
        : target > duration
            ? duration
            : target;

    controller.seekTo(bounded);
    setState(() => _showControls = true);
  }

  void _handleDoubleTap(TapDownDetails details, BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (details.globalPosition.dx < width / 2) {
      _skipBy(_skipSeconds);
    } else {
      _skipBy(-_skipSeconds);
    }
  }

  Future<void> _setFastForwarding(bool enabled) async {
    final controller = _controller;
    if (controller == null) return;

    try {
      await controller.setPlaybackSpeed(enabled ? 2.0 : 1.0);
      if (mounted) {
        setState(() {
          _isFastForwarding = enabled;
          _showControls = true;
        });
      }
    } catch (_) {
      // Some platforms may not support speed changes for every source.
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _downloadVideo(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        await Permission.photos.request();
        await Permission.storage.request();
      } else if (Platform.isIOS) {
        await Permission.photosAddOnly.request();
      }

      Get.snackbar(
        "تنبيه",
        "جاري التحميل... سيتم إعلامك عند الانتهاء",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      final dir = await getTemporaryDirectory();
      final fileName = widget.videoPath.split('/').last;
      final tempPath = "${dir.path}/$fileName";

      await Dio().download(widget.videoPath, tempPath);

      final success = await GallerySaver.saveVideo(
        tempPath,
        albumName: "Doctor Bike",
      );

      if (success == true) {
        showSweetSuccessDialog(
          title: "تم",
          message: "تم حفظ الفيديو في المعرض ✅",
        );
      } else {
        throw Exception("فشل الحفظ في المعرض");
      }
    } catch (e) {
      Get.snackbar(
        "خطأ",
        "فشل التحميل: $e",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final showTopChrome = widget.dsibalBack != true;

    return Scaffold(
      backgroundColor: Colors.black,
      body: controller == null || !controller.value.isInitialized
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _handleSurfaceTap,
              onDoubleTapDown: (details) => _handleDoubleTap(details, context),
              onLongPressStart: (_) => _setFastForwarding(true),
              onLongPressEnd: (_) => _setFastForwarding(false),
              onLongPressCancel: () => _setFastForwarding(false),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _showControls ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: IgnorePointer(
                      ignoring: !_showControls,
                      child: _VideoControlsOverlay(
                        controller: controller,
                        isPlaying: _isPlaying,
                        isLocalPlayback: _isLocalPlayback,
                        isFastForwarding: _isFastForwarding,
                        showTopChrome: showTopChrome,
                        title: _videoDisplayTitle(widget.videoPath),
                        current: _formatDuration(controller.value.position),
                        duration: _formatDuration(controller.value.duration),
                        onBack: () => Navigator.of(context).maybePop(),
                        onDownload: () => _downloadVideo(context),
                        onUserInteraction: _showControlsNow,
                        onTogglePlay: _togglePlay,
                        onBackward: () => _skipBy(-_skipSeconds),
                        onForward: () => _skipBy(_skipSeconds),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

String _videoDisplayTitle(String value) {
  final trimmed = value.trim();
  final uri = Uri.tryParse(trimmed);
  final lastSegment = uri?.pathSegments.isNotEmpty == true
      ? uri!.pathSegments.last
      : trimmed.split('/').last;
  final withoutQuery = lastSegment.split('?').first.split('#').first;
  return _safeDecodeComponent(withoutQuery.isEmpty ? trimmed : withoutQuery);
}

String _safeDecodeComponent(String value) {
  try {
    return Uri.decodeComponent(value);
  } catch (_) {
    return value;
  }
}

class _CachedVideoController {
  const _CachedVideoController(
    this.controller, {
    required this.isLocalFile,
  });

  final VideoPlayerController controller;
  final bool isLocalFile;
}

final CacheManager _videoCacheManager = CacheManager(
  Config(
    'doctorBikeVideoCache',
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 80,
  ),
);

class _VideoControlsOverlay extends StatelessWidget {
  const _VideoControlsOverlay({
    required this.controller,
    required this.isPlaying,
    required this.isLocalPlayback,
    required this.isFastForwarding,
    required this.showTopChrome,
    required this.title,
    required this.current,
    required this.duration,
    required this.onBack,
    required this.onDownload,
    required this.onUserInteraction,
    required this.onTogglePlay,
    required this.onBackward,
    required this.onForward,
  });

  final VideoPlayerController controller;
  final bool isPlaying;
  final bool isLocalPlayback;
  final bool isFastForwarding;
  final bool showTopChrome;
  final String title;
  final String current;
  final String duration;
  final VoidCallback onBack;
  final VoidCallback onDownload;
  final VoidCallback onUserInteraction;
  final VoidCallback onTogglePlay;
  final VoidCallback onBackward;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.72),
            Colors.black.withValues(alpha: 0.08),
            Colors.black.withValues(alpha: 0.72),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (showTopChrome)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: onBack,
                    ),
                    Expanded(
                      child: Text(
                        _safeDecodeComponent(title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download, color: Colors.white),
                      onPressed: onDownload,
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 12),
            const Spacer(),
            if (isFastForwarding)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'x2',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            if (isFastForwarding) const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoundVideoButton(
                  icon: Icons.replay_10,
                  onPressed: onBackward,
                ),
                const SizedBox(width: 26),
                _RoundVideoButton(
                  icon: isPlaying ? Icons.pause : Icons.play_arrow,
                  onPressed: onTogglePlay,
                  large: true,
                ),
                const SizedBox(width: 26),
                _RoundVideoButton(
                  icon: Icons.forward_10,
                  onPressed: onForward,
                ),
              ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                children: [
                  _RtlVideoProgressBar(
                    controller: controller,
                    isLocalPlayback: isLocalPlayback,
                    onInteraction: onUserInteraction,
                  ),
                  Row(
                    children: [
                      Text(
                        current,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        duration,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RtlVideoProgressBar extends StatelessWidget {
  const _RtlVideoProgressBar({
    required this.controller,
    required this.isLocalPlayback,
    required this.onInteraction,
  });

  final VideoPlayerController controller;
  final bool isLocalPlayback;
  final VoidCallback onInteraction;

  void _seekFromLocalPosition(BuildContext context, Offset localPosition) {
    final box = context.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 0;
    final duration = controller.value.duration;
    if (width <= 0 || duration <= Duration.zero) return;

    final clampedX = localPosition.dx.clamp(0.0, width);
    final rtlFraction = 1 - (clampedX / width);
    final target = duration * rtlFraction;
    controller.seekTo(target);
    onInteraction();
  }

  double _fraction(Duration value, Duration duration) {
    if (duration <= Duration.zero) return 0;
    return (value.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    final duration = value.duration;
    final positionFraction = _fraction(value.position, duration);
    final bufferedEnd =
        value.buffered.isEmpty ? Duration.zero : value.buffered.last.end;
    final bufferedFraction =
        isLocalPlayback ? 1.0 : _fraction(bufferedEnd, duration);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (details) => _seekFromLocalPosition(
        context,
        details.localPosition,
      ),
      onHorizontalDragStart: (details) => _seekFromLocalPosition(
        context,
        details.localPosition,
      ),
      onHorizontalDragUpdate: (details) => _seekFromLocalPosition(
        context,
        details.localPosition,
      ),
      child: SizedBox(
        height: 24,
        child: Center(
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              FractionallySizedBox(
                alignment: Alignment.centerRight,
                widthFactor: bufferedFraction,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isLocalPlayback ? Colors.white24 : Colors.white38,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              FractionallySizedBox(
                alignment: Alignment.centerRight,
                widthFactor: positionFraction,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A00),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Positioned(
                right: (MediaQuery.sizeOf(context).width - 32) *
                    positionFraction.clamp(0.0, 1.0),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF8A00),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundVideoButton extends StatelessWidget {
  const _RoundVideoButton({
    required this.icon,
    required this.onPressed,
    this.large = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 72.0 : 54.0;
    final iconSize = large ? 42.0 : 30.0;

    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }
}
