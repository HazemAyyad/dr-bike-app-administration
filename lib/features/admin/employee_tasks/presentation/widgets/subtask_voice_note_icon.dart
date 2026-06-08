import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/audio_helper.dart';
import '../../../../../core/utils/app_colors.dart';
import 'subtask_voice_note_tile.dart';

/// Small mic icon for subtask voice notes (employee checklist).
class SubtaskVoiceNoteIcon extends StatelessWidget {
  const SubtaskVoiceNoteIcon({
    Key? key,
    required this.url,
    this.size = 40,
  }) : super(key: key);

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!hasPlayableAudio(url)) {
      return const SizedBox.shrink();
    }

    final dim = size.w;
    return Material(
      color: AppColors.operationalPurple,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () => SubtaskVoiceNoteTile.openPlayer(context, url: url),
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: dim,
          height: dim,
          child: Icon(
            Icons.mic_rounded,
            color: Colors.white,
            size: (size * 0.52).sp,
          ),
        ),
      ),
    );
  }
}
