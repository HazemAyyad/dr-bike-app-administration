import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../../data/whatsapp_models.dart';
import '../controllers/whatsapp_conversation_controller.dart';

class WhatsAppAudioBubble extends StatefulWidget {
  const WhatsAppAudioBubble({
    Key? key,
    required this.message,
    required this.controller,
  }) : super(key: key);

  final WhatsAppMessage message;
  final WhatsAppConversationController controller;

  @override
  State<WhatsAppAudioBubble> createState() => _WhatsAppAudioBubbleState();
}

class _WhatsAppAudioBubbleState extends State<WhatsAppAudioBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      final bytes = await widget.controller.getMediaBytes(widget.message);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/whatsapp-${widget.message.id}.m4a');
      await file.writeAsBytes(bytes, flush: true);
      await _player.setFilePath(file.path);
    } catch (e) {
      _error = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 220,
        height: 52,
        child: Center(child: LinearProgressIndicator()),
      );
    }
    if (_error != null) return const Text('تعذر تحميل التسجيل الصوتي');
    return SizedBox(
      width: 280,
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF7B8B87),
                foregroundColor: Colors.white,
                child: widget.message.senderName?.isNotEmpty == true
                    ? Text(widget.message.senderName!.characters.first)
                    : const Icon(Icons.person),
              ),
              const Positioned(
                bottom: -2,
                left: -2,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Color(0xFF00A884),
                  child: Icon(Icons.mic, color: Colors.white, size: 10),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (_, snapshot) {
              final state = snapshot.data;
              final playing = state?.playing == true;
              final completed =
                  state?.processingState == ProcessingState.completed;
              return IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF00A884),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (completed) await _player.seek(Duration.zero);
                  playing ? await _player.pause() : await _player.play();
                },
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (_, snapshot) {
                final duration = _player.duration ?? Duration.zero;
                final position = snapshot.data ?? Duration.zero;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _WaveformProgress(
                      position: position,
                      duration: duration,
                      onSeek: _player.seek,
                    ),
                    Text(
                      _formatDuration(duration),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF667781),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration value) {
  final minutes = value.inMinutes.toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _WaveformProgress extends StatelessWidget {
  const _WaveformProgress({
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    const heights = <double>[
      12,
      22,
      15,
      30,
      18,
      25,
      34,
      16,
      28,
      20,
      32,
      14,
      24,
      35,
      19,
      27,
      13,
      31,
      21,
      26,
      16,
      33,
      18,
      29,
      12,
      25,
      35,
      17,
      28,
      20,
      31,
      14,
      24,
      18,
    ];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || duration == Duration.zero) return;
        final ratio =
            (details.localPosition.dx / box.size.width).clamp(0.0, 1.0);
        onSeek(
            Duration(milliseconds: (duration.inMilliseconds * ratio).round()));
      },
      child: SizedBox(
        height: 42,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(heights.length, (index) {
            final played = index / heights.length <= progress;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 2.5,
              height: heights[index],
              decoration: BoxDecoration(
                color:
                    played ? const Color(0xFF00A884) : const Color(0xFF9AA9A5),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class WhatsAppVideoBubble extends StatefulWidget {
  const WhatsAppVideoBubble({
    Key? key,
    required this.message,
    required this.controller,
  }) : super(key: key);

  final WhatsAppMessage message;
  final WhatsAppConversationController controller;

  @override
  State<WhatsAppVideoBubble> createState() => _WhatsAppVideoBubbleState();
}

class _WhatsAppVideoBubbleState extends State<WhatsAppVideoBubble> {
  VideoPlayerController? _video;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      final bytes = await widget.controller.getMediaBytes(widget.message);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/whatsapp-${widget.message.id}.mp4');
      await file.writeAsBytes(bytes, flush: true);
      final video = VideoPlayerController.file(file);
      await video.initialize();
      video.addListener(_refresh);
      _video = video;
    } catch (e) {
      _error = e;
    }
    if (mounted) setState(() {});
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _video?.removeListener(_refresh);
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return const SizedBox(
        width: 230,
        height: 130,
        child: Center(child: Text('تعذر تحميل الفيديو')),
      );
    }
    final video = _video;
    if (video == null || !video.value.isInitialized) {
      return const SizedBox(
        width: 230,
        height: 130,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return GestureDetector(
      onTap: () => video.value.isPlaying ? video.pause() : video.play(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          width: 240,
          child: AspectRatio(
            aspectRatio: video.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(video),
                if (!video.value.isPlaying)
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.black54,
                    child:
                        Icon(Icons.play_arrow, color: Colors.white, size: 34),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: VideoProgressIndicator(
                    video,
                    allowScrubbing: true,
                    padding: EdgeInsets.zero,
                    colors: const VideoProgressColors(
                      playedColor: Color(0xFF00A884),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
