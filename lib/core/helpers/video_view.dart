import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

import 'custom_app_bar.dart';

class VideoView extends StatefulWidget {
  const VideoView({Key? key, required this.videoPath, this.dsibalBack})
      : super(key: key);
  final String videoPath;
  final bool? dsibalBack;

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _showControls = true;

  static const int skipDuration = 10;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final videoUrl = widget.videoPath.isEmpty
        ? 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4'
        : widget.videoPath;

    final encodedUrl = Uri.encodeFull(videoUrl);

    final controller = VideoPlayerController.networkUrl(Uri.parse(encodedUrl));

    await controller.initialize();

    if (mounted) {
      setState(() {
        _controller = controller;
      });

      controller.addListener(_videoListener);
    }
  }

  void _videoListener() {
    if (_controller?.value.position == _controller?.value.duration) {
      setState(() => _isPlaying = false);
    }
  }

  void _skipForward() {
    if (_controller == null) return;
    final current = _controller!.value.position;
    final target = current + const Duration(seconds: skipDuration);
    final duration = _controller!.value.duration;

    _controller!.seekTo(target > duration ? duration : target);
  }

  void _skipBackward() {
    if (_controller == null) return;
    final current = _controller!.value.position;
    final target = current - const Duration(seconds: skipDuration);

    _controller!.seekTo(target < Duration.zero ? Duration.zero : target);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _downloadImage(BuildContext context) async {
    try {
      // ✅ اطلب الصلاحيات المسموح بها فقط
      if (Platform.isAndroid) {
        await Permission.photos.request(); // Android 13+
        await Permission.storage.request(); // Android < 13
      } else if (Platform.isIOS) {
        await Permission.photosAddOnly.request();
      }

      Get.snackbar(
        "تنبيه",
        "جاري التحميل... سيتم إعلامك عند الانتهاء",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      // 🧭 احفظ مؤقتاً داخل كاش التطبيق
      final dir = await getTemporaryDirectory();
      final fileName = widget.videoPath.split('/').last;
      final tempPath = "${dir.path}/$fileName";

      // 💾 التحميل المؤقت
      await Dio().download(widget.videoPath, tempPath);

      // 📸 احفظ في المعرض حسب نوع الملف
      bool? success;
      if (widget.videoPath.toLowerCase().endsWith('.mp4')) {
        success = await GallerySaver.saveVideo(
          tempPath,
          albumName: "Doctor Bike",
        );
      } else {
        success = await GallerySaver.saveImage(
          tempPath,
          albumName: "Doctor Bike",
        );
      }

      if (success == true) {
        Get.snackbar(
          "تم",
          "تم الحفظ في المعرض ✅",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
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
    return Scaffold(
      appBar: widget.dsibalBack != true
          ? CustomAppBar(
              title: '',
              // action: false,
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.download,
                    color: Colors.green,
                    size: 30,
                  ),
                  onPressed: () => _downloadImage(context)
                      // ignore: use_build_context_synchronously
                      .then((value) => Navigator.of(context).pop()),
                ),
              ],
            )
          : null,
      body: Center(
        child: _controller == null || !_controller!.value.isInitialized
            ? const CircularProgressIndicator()
            : GestureDetector(
                onTap: () => setState(() => _showControls = !_showControls),
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_controller!),
                      if (_showControls) ...[
                        Container(color: Colors.black26),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.replay_10,
                                  color: Colors.white, size: 40),
                              onPressed: _skipForward,
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_controller!.value.isPlaying) {
                                    _controller!.pause();
                                    _isPlaying = false;
                                  } else {
                                    _controller!.play();
                                    _isPlaying = true;
                                  }
                                });
                              },
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.black54,
                                child: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.forward_10,
                                  color: Colors.white, size: 40),
                              onPressed: _skipBackward,
                            ),
                          ],
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Column(
                            children: [
                              VideoProgressIndicator(
                                _controller!,
                                allowScrubbing: true,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(
                                          _controller!.value.position),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      _formatDuration(
                                          _controller!.value.duration),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

            // SizedBox(
            //   width: double.infinity,
            //   child: ClipRRect(
            //     borderRadius: BorderRadius.circular(16),
            //     child: ElevatedButton.icon(
            //       onPressed: _downloadVideo,
            //       icon: const Icon(
            //         Icons.download,
            //         color: Colors.white,
            //       ),
            //       label: const Text(
            //         'تنزيل الفيديو',
            //         style: TextStyle(
            //             color: Colors.white, fontWeight: FontWeight.bold),
            //       ),
            //       style: ElevatedButton.styleFrom(
            //         backgroundColor: AppColors.kprimaryColor,
            //         padding: const EdgeInsets.symmetric(
            //             horizontal: 24, vertical: 12),
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(8),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),

  
  // Future<void> _requestPermission() async {
  //   final status = await Permission.manageExternalStorage.status;

  //   if (status.isDenied) {
  //     // طلب الإذن من المستخدم
  //     final result = await Permission.manageExternalStorage.request();

  //     if (!result.isGranted) {
  //       throw 'تم رفض إذن التخزين. يرجى تمكينه من الإعدادات.';
  //     }
  //   } else if (status.isPermanentlyDenied) {
  //     // إذا رفض المستخدم الإذن نهائياً، وجهه إلى الإعدادات
  //     throw 'إذن التخزين مرفوض بشكل دائم. يرجى تمكينه من إعدادات الجهاز.';
  //   }
  // }

  // Future<void> _downloadVideo() async {
  //   try {
  //     await _requestPermission();
  //     // اختر المجلد باستخدام FilePicker
  //     final outputDirectory = await FilePicker.platform.getDirectoryPath();

  //     if (outputDirectory == null) {
  //       // المستخدم لم يحدد مجلدًا
  //       return;
  //     }

  //     final videoName = widget.item.videoPath.split('/').last;
  //     final savePath = '$outputDirectory/$videoName';

  //     final dio = Dio();
  //     await dio.download(widget.item.videoPath, savePath);
  //     Get.snackbar('تنبيه', 'تم تنزيل الفيديو بنجاح إلى $savePath');
  //   } catch (e) {
  //     Get.snackbar('خطأ',
  //         'فشل في تحميل الملف برجاء اعطاء صلاحيات التخزين من الاعدادات: $e');
  //   }
  // }

