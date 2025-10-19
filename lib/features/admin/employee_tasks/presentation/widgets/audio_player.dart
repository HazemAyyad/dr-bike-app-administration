import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String url; // رابط الصوت من الإنترنت

  const AudioPlayerWidget({Key? key, required this.url}) : super(key: key);

  @override
  AudioPlayerWidgetState createState() => AudioPlayerWidgetState();
}

class AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final _player = AudioPlayer();
  bool _isPrepared = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (!_isPrepared) {
      try {
        await _player.setUrl(widget.url); // تحميل الصوت أول مرة بس
        _isPrepared = true;
      } catch (e) {
        debugPrint("❌ Error loading audio: $e");
        return;
      }
    }

    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.deepPurple.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final state = snapshot.data;
              final playing = state?.playing ?? false;

              return IconButton(
                icon: Icon(
                  playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  size: 36,
                  color: AppColors.primaryColor,
                ),
                onPressed: _togglePlayPause, // بدل ما كان مباشر
              );
            },
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: StreamBuilder<Duration>(
                stream: _player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final total = _player.duration ?? Duration.zero;

                  return ProgressBar(
                    progress: position,
                    total: total,
                    progressBarColor: AppColors.primaryColor,
                    baseBarColor: Colors.grey[300]!,
                    thumbColor: AppColors.primaryColor,
                    onSeek: (duration) {
                      _player.seek(duration);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
