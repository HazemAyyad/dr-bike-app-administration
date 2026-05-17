import 'dart:async';
import 'dart:io';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:doctorbike/core/helpers/audio_helper.dart';
import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String url;

  const AudioPlayerWidget({Key? key, required this.url}) : super(key: key);

  @override
  AudioPlayerWidgetState createState() => AudioPlayerWidgetState();
}

class AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final _player = AudioPlayer();
  bool _isPrepared = false;
  bool _isLoading = false;
  StreamSubscription<PlayerState>? _playerSub;

  @override
  void initState() {
    super.initState();
    _playerSub = _player.playerStateStream.listen(_onPlayerState);
  }

  void _onPlayerState(PlayerState state) {
    if (!mounted) return;

    if (state.processingState == ProcessingState.completed) {
      unawaited(_resetAfterPlayback());
      return;
    }

    setState(() {});
  }

  Future<void> _resetAfterPlayback() async {
    await _player.seek(Duration.zero);
    await _player.pause();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_isLoading) return;

    if (_player.playing) {
      await _player.pause();
      if (mounted) setState(() {});
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (!_isPrepared) {
        final uri = resolveAudioPlaybackUri(widget.url);
        if (uri.isEmpty) return;

        if (isNetworkAudioUri(uri)) {
          await _player.setUrl(uri);
        } else {
          final file = File(uri);
          if (!await file.exists()) {
            debugPrint('❌ Audio file not found: $uri');
            return;
          }
          await _player.setFilePath(uri);
        }
        _isPrepared = true;
      }

      await _player.play();
    } catch (e) {
      debugPrint('❌ Error loading audio: $e');
      _isPrepared = false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playing = _player.playing && !_isLoading;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.deepPurple.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _togglePlayPause,
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: _isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(6),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primaryColor,
                          ),
                        )
                      : Icon(
                          playing
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_fill,
                          size: 36,
                          color: AppColors.primaryColor,
                        ),
                ),
              ),
            ),
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
