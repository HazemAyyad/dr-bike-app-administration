import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../../core/helpers/audio_helper.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';

class AudioRecorderButton extends StatefulWidget {
  const AudioRecorderButton({
    Key? key,
    required this.label,
    required this.recordedPath,
  }) : super(key: key);

  final String label;
  final RxString recordedPath;

  @override
  State<AudioRecorderButton> createState() => AudioRecorderButtonState();
}

class AudioRecorderButtonState extends State<AudioRecorderButton> {
  late final RecorderController _recorderController;
  final ja.AudioPlayer _previewPlayer = ja.AudioPlayer();

  final RxBool isRecording = false.obs;
  final RxBool isPlaying = false.obs;
  final RxBool isLoadingPlay = false.obs;

  String? _activeRecordPath;
  StreamSubscription<ja.PlayerState>? _playerSub;

  @override
  void initState() {
    super.initState();
    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 48000
      ..bitRate = 192000;

    _playerSub = _previewPlayer.playerStateStream.listen(_onPlayerState);
  }

  void _onPlayerState(ja.PlayerState state) {
    if (state.processingState == ja.ProcessingState.completed) {
      _resetPreviewAfterPlayback();
      return;
    }
    isPlaying.value =
        state.playing && state.processingState != ja.ProcessingState.completed;
  }

  Future<void> _resetPreviewAfterPlayback() async {
    await _previewPlayer.seek(Duration.zero);
    await _previewPlayer.pause();
    isPlaying.value = false;
    isLoadingPlay.value = false;
  }

  Future<bool> _ensureMicPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    if (!status.isGranted) {
      Get.snackbar('error'.tr, 'microphonePermissionRequired'.tr);
      return false;
    }
    return true;
  }

  Future<void> _startRecording() async {
    if (!await _ensureMicPermission()) return;

    await _previewPlayer.stop();
    isPlaying.value = false;

    final dir = await getTemporaryDirectory();
    _activeRecordPath =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

    try {
      await _recorderController.record(path: _activeRecordPath!);
      isRecording.value = true;
    } catch (e) {
      Get.snackbar('error'.tr, 'audioRecordFailed'.tr);
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorderController.stop();
      final finalPath = path ?? _activeRecordPath;
      if (finalPath != null) {
        final file = File(finalPath);
        if (await file.exists() && await file.length() > 0) {
          widget.recordedPath.value = finalPath;
          _activeRecordPath = finalPath;
        }
      }
    } catch (_) {}
    isRecording.value = false;
  }

  Future<void> _playRecording() async {
    final path = widget.recordedPath.value;
    if (path.isEmpty || isLoadingPlay.value) return;

    if (isPlaying.value) {
      await _previewPlayer.pause();
      isPlaying.value = false;
      return;
    }

    isLoadingPlay.value = true;

    try {
      await _previewPlayer.stop();
      final uri = resolveAudioPlaybackUri(path);
      if (uri.isEmpty) {
        Get.snackbar('error'.tr, 'audioPlayFailed'.tr);
        return;
      }

      if (isNetworkAudioUri(uri)) {
        await _previewPlayer.setUrl(uri);
      } else {
        final file = File(uri);
        if (!await file.exists()) {
          Get.snackbar('error'.tr, 'audioPlayFailed'.tr);
          return;
        }
        await _previewPlayer.setFilePath(uri);
      }

      await _previewPlayer.play();
      isPlaying.value = true;
    } catch (e) {
      debugPrint('audio play error: $e');
      isPlaying.value = false;
      Get.snackbar('error'.tr, 'audioPlayFailed'.tr);
    } finally {
      isLoadingPlay.value = false;
    }
  }

  Future<void> _resetRecording() async {
    if (isRecording.value) await _stopRecording();
    await _previewPlayer.stop();

    final path = widget.recordedPath.value;
    if (path.isNotEmpty && !path.startsWith('http')) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }

    widget.recordedPath.value = '';
    _activeRecordPath = null;
    isPlaying.value = false;
    isLoadingPlay.value = false;
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _recorderController.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  Widget _playControl({required bool hasFile}) {
    if (!hasFile) {
      return IconButton(
        onPressed: _startRecording,
        icon: const Icon(Icons.mic, color: AppColors.primaryColor),
      );
    }

    return Obx(() {
      final loading = isLoadingPlay.value;
      final playing = isPlaying.value && !loading;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : _playRecording,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: EdgeInsets.all(8.w),
            child: SizedBox(
              width: 28.w,
              height: 28.w,
              child: loading
                  ? const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primaryColor,
                    )
                  : Icon(
                      playing
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      color: AppColors.primaryColor,
                      size: 32.sp,
                    ),
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasFile = hasPlayableAudio(widget.recordedPath.value);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label.tr,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor6
                      : AppColors.customGreyColor,
                  fontSize: 15.sp,
                ),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.whiteColor2,
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: Row(
              children: [
                if (isRecording.value)
                  Expanded(
                    child: AudioWaveforms(
                      recorderController: _recorderController,
                      size: Size(double.infinity, 48.h),
                      waveStyle: const WaveStyle(
                        showMiddleLine: false,
                        extendWaveform: true,
                      ),
                    ),
                  )
                else if (hasFile)
                  Expanded(
                    child: Obx(() {
                      final playing = isPlaying.value;
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Text(
                          playing ? 'playingAudio'.tr : 'tapPlayToListen'.tr,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: playing
                                ? AppColors.primaryColor
                                : Colors.grey.shade600,
                            fontWeight:
                                playing ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      );
                    }),
                  )
                else
                  Expanded(
                    child: Text(
                      'tapToRecordAudio'.tr,
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                    ),
                  ),
                if (isRecording.value)
                  IconButton(
                    onPressed: _stopRecording,
                    icon: const Icon(Icons.stop_circle, color: Colors.red),
                  )
                else if (hasFile) ...[
                  IconButton(
                    onPressed: _resetRecording,
                    icon: const Icon(Icons.refresh, color: Colors.red),
                  ),
                  _playControl(hasFile: true),
                ] else
                  _playControl(hasFile: false),
              ],
            ),
          ),
        ],
      );
    });
  }
}
