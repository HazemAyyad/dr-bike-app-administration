import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

String _fmtDuration(Duration d) {
  final t = d.inSeconds;
  final h = t ~/ 3600;
  final m = (t % 3600) ~/ 60;
  final s = t % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// تشغيل فيديو المنتج داخل الصفحة مع كتم وشريط تقدّم.
class ProductInlineVideo extends StatefulWidget {
  const ProductInlineVideo({Key? key, required this.videoUrl}) : super(key: key);

  final String videoUrl;

  @override
  State<ProductInlineVideo> createState() => _ProductInlineVideoState();
}

class _ProductInlineVideoState extends State<ProductInlineVideo> {
  VideoPlayerController? _controller;
  bool _initFailed = false;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    final ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _controller = ctrl
      ..addListener(() {
        if (mounted) setState(() {});
      })
      ..initialize().then((_) {
        if (mounted) {
          ctrl.setVolume(_muted ? 0 : 1);
          setState(() {});
        }
      }).catchError((_) {
        if (mounted) {
          setState(() {
            _initFailed = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggleMute() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    setState(() {
      _muted = !_muted;
      c.setVolume(_muted ? 0 : 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initFailed) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Text(
          'videoLoadFailed'.tr,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.red),
        ),
      );
    }
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final pos = c.value.position;
    final dur = c.value.duration;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: ColoredBox(
        color: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 140.h,
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: c.value.size.width,
                  height: c.value.size.height,
                  child: VideoPlayer(c),
                ),
              ),
            ),
            VideoProgressIndicator(
              c,
              allowScrubbing: true,
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
              colors: const VideoProgressColors(
                playedColor: Colors.deepPurpleAccent,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white10,
              ),
            ),
            Material(
              color: Colors.black87,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        c.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 30.sp,
                      ),
                      onPressed: () {
                        if (c.value.isPlaying) {
                          c.pause();
                        } else {
                          c.play();
                        }
                        setState(() {});
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.replay,
                        color: Colors.white70,
                        size: 24.sp,
                      ),
                      onPressed: () async {
                        await c.seekTo(Duration.zero);
                        await c.play();
                        setState(() {});
                      },
                    ),
                    Expanded(
                      child: Text(
                        '${_fmtDuration(pos)} / ${_fmtDuration(dur)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _muted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                      onPressed: _toggleMute,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
