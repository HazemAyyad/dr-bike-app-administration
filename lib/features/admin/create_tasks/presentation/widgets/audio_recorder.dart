import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  final RxBool _isRecording = false.obs;
  final RxBool _isPlaying = false.obs;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _recorder.openRecorder();
    _player.openPlayer();
  }

  Future<void> _startRecording() async {
    await Permission.microphone.request();
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.startRecorder(
      toFile: path,
      codec: Codec.aacMP4,
    );

    widget.recordedPath.value = path;
    setState(() => _isRecording.value = true);
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    _isRecording.value = false;
  }

  Future<void> _playRecording() async {
    if (_isPlaying.value) {
      await _player.stopPlayer();
      setState(() => _isPlaying.value = false);
      return;
    }

    await _player.startPlayer(
      fromURI: widget.recordedPath.value,
      codec: Codec.aacMP4,
      whenFinished: () => setState(() => _isPlaying.value = false),
    );

    setState(() => _isPlaying.value = true);
  }

  Future<void> _resetRecording() async {
    if (_isRecording.value) await _recorder.stopRecorder();
    if (_isPlaying.value) await _player.stopPlayer();

    if (widget.recordedPath.value.isNotEmpty) {
      final file = File(widget.recordedPath.value);
      if (await file.exists()) await file.delete();
    }

    widget.recordedPath.value = '';
    _isPlaying.value = false;
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          Row(
            children: [
              Text(
                widget.label.tr,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: ThemeService.isDark.value
                          ? AppColors.customGreyColor6
                          : AppColors.customGreyColor,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w400,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.whiteColor2,
              borderRadius: BorderRadius.circular(11),
            ),
            height: 50,
            child: Row(
              children: _isRecording.value
                  ? [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15.w),
                          child: Text(
                            "جارٍ التسجيل...",
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _stopRecording,
                        icon: const Icon(
                          Icons.stop,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ]
                  : (widget.recordedPath.value.isNotEmpty)
                      ? [
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.red),
                            onPressed: _resetRecording,
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15.w),
                              child: Text(
                                widget.recordedPath.value.split('/').last,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _playRecording,
                            icon: Icon(
                              _isPlaying.value
                                  ? Icons.pause
                                  : Icons.play_arrow_rounded,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ]
                      : [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15.w),
                              child: Text(
                                'اضغط للتسجيل الصوتي',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      fontSize: 15.sp,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _startRecording,
                            icon: const Icon(Icons.mic_none),
                          ),
                        ],
            ),
          ),
        ],
      );
    });
  }
}


  // Future<void> _uploadAudio(File file) async {
  //   final dio = Dio();
  //   final formData = FormData.fromMap({
  //     'audio':
  //         await MultipartFile.fromFile(file.path, filename: 'recorded.aac'),
  //   });

  //   try {
  //     final response = await dio.post(
  //       'https://your-api.com/upload',
  //       data: formData,
  //     );
  //     print('Upload success: ${response.data}');
  //   } catch (e) {
  //     print('Upload failed: $e');
  //   }
  // }

  // if (_recordedPath != null) ...[
  //   const SizedBox(height: 12),
  //   ElevatedButton.icon(
  //     icon: Obx(
  //         () => Icon(_isPlaying.value ? Icons.pause : Icons.play_arrow)),
  //     label: const Text('Play Recording'),
  //     onPressed: _playRecording,
  //   ),
  //   const SizedBox(height: 12),
  //   ElevatedButton.icon(
  //     icon: const Icon(Icons.cloud_upload),
  //     label: const Text('Upload'),
  //     onPressed: () {
  //       if (_recordedPath != null) {
  //         _uploadAudio(File(_recordedPath!));
  //       }
  //     },
  //   ),
  // ],



// import 'package:audio_waveforms/audio_waveforms.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart' hide FormData, MultipartFile;
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

// import '../../../../../core/services/theme_service.dart';
// import '../../../../../core/utils/app_colors.dart';

// class AudioRecorderButton extends StatefulWidget {
//   const AudioRecorderButton({Key? key}) : super(key: key);

//   @override
//   State<AudioRecorderButton> createState() => _AudioRecorderButtonState();
// }

// class _AudioRecorderButtonState extends State<AudioRecorderButton> {
//   late final RecorderController _recorderController;
//   late final PlayerController _playerController;

//   final RxBool isRecording = false.obs;
//   final RxBool isPlaying = false.obs;
//   final RxString recordedFilePath = ''.obs;

//   final Rx<Duration> recordingDuration = Duration.zero.obs;
//   final Rx<Duration> playbackPosition = Duration.zero.obs;
//   Duration totalDuration = Duration.zero;

//   @override
//   void initState() {
//     super.initState();
//     _initControllers();
//   }

//   Future<void> _initControllers() async {
//     await Permission.microphone.request();

//     _recorderController = RecorderController()
//       ..androidEncoder = AndroidEncoder.aac
//       ..androidOutputFormat = AndroidOutputFormat.mpeg4
//       ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
//       ..sampleRate = 16000
//       ..updateFrequency = const Duration(milliseconds: 100);

//     _playerController = PlayerController();

//     _recorderController.onCurrentDuration.listen((d) {
//       recordingDuration.value = d;
//     });

//     _playerController.onPlayerStateChanged.listen(
//       (state) {
//         isPlaying.value = state.isPlaying;
//       },
//     );

//     _playerController.onPlayerStateChanged.listen((state) {
//       isPlaying.value = state.isPlaying;
//     });

//     _playerController.onCompletion.listen((_) async {
//       isPlaying.value = false;
//       await _playerController.seekTo(0);
//     });
//   }

//   Future<void> _startRecording() async {
//     final dir = await getTemporaryDirectory();
//     final path =
//         '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';

//     await _recorderController.record(path: path);
//     isRecording.value = true;
//     recordedFilePath.value = path;
//   }

//   Future<void> _stopRecording() async {
//     await _recorderController.stop();
//     isRecording.value = false;
//   }

//   Future<void> _playRecording() async {
//     if (recordedFilePath.value.isEmpty) return;

//     await _playerController.stopPlayer();
//     await _playerController.preparePlayer(
//       path: recordedFilePath.value,
//       shouldExtractWaveform: true,
//     );

//     totalDuration = Duration(milliseconds: _playerController.maxDuration);
//     _playerController.setFinishMode(finishMode: FinishMode.pause);

//     await _playerController.startPlayer();
//   }

//   @override
//   void dispose() {
//     _recorderController.dispose();
//     _playerController.dispose();
//     super.dispose();
//   }

//   void _resetRecording() {
//     if (isRecording.value) _stopRecording();
//     recordedFilePath.value = '';
//     playbackPosition.value = Duration.zero;
//     totalDuration = Duration.zero;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       return Column(children: [
//         Container(
//           padding: EdgeInsets.symmetric(horizontal: 10.w),
//           width: double.infinity,
//           height: 50.h,
//           decoration: BoxDecoration(
//             color: ThemeService.isDark.value
//                 ? AppColors.customGreyColor
//                 : AppColors.whiteColor2,
//             borderRadius: BorderRadius.circular(11.r),
//           ),
//           child: Row(
//             children: [
//               if (isRecording.value)
//                 Flexible(
//                   child: AudioWaveforms(
//                     recorderController: _recorderController,
//                     waveStyle: const WaveStyle(showDurationLabel: true),
//                     size: const Size(double.infinity, 50),
//                   ),
//                 )
//               else if (recordedFilePath.value.isNotEmpty) ...[
//                 IconButton(
//                   onPressed: _resetRecording,
//                   icon: const Icon(Icons.close, color: Colors.red),
//                 ),
//                 Flexible(
//                   child: AudioFileWaveforms(
//                     playerController: _playerController,
//                     size: const Size(double.infinity, 50),
//                     playerWaveStyle: const PlayerWaveStyle(
//                         liveWaveColor: Colors.blueAccent,
//                         fixedWaveColor: Colors.grey,
//                         showSeekLine: true),
//                     enableSeekGesture: true,
//                   ),
//                 ),
//                 IconButton(
//                   onPressed: _playRecording,
//                   icon: Icon(
//                     isPlaying.value ? Icons.pause : Icons.play_arrow_rounded,
//                     color: AppColors.primaryColor,
//                   ),
//                 ),
//               ] else
//                 Expanded(
//                   child: Text(
//                     'اضغط لبدء التسجيل الصوتي',
//                     style: Theme.of(context).textTheme.bodyMedium!.copyWith(
//                           color: ThemeService.isDark.value
//                               ? AppColors.customGreyColor
//                               : AppColors.customGreyColor6,
//                           fontSize: 16.sp,
//                           fontWeight: FontWeight.w400,
//                         ),
//                   ),
//                 ),
//               if (!isRecording.value && recordedFilePath.value.isEmpty)
//                 IconButton(
//                   onPressed: _startRecording,
//                   icon: Icon(Icons.mic_none, color: AppColors.primaryColor),
//                 ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 8),
//         if (isRecording.value)
//           Text('Recording: ${recordingDuration.value.inSeconds}s'),
//         if (recordedFilePath.value.isNotEmpty &&
//             playbackPosition.value != Duration.zero)
//           Text(
//               'Played: ${playbackPosition.value.inSeconds}/${totalDuration.inSeconds}s'),
//         SizedBox(height: 16.h),
//         IconButton(
//           onPressed: _playRecording,
//           icon: Icon(
//             isPlaying.value ? Icons.pause : Icons.play_arrow_rounded,
//             color: AppColors.primaryColor,
//           ),
//         ),
//       ]);
//     });
//   }
// }
