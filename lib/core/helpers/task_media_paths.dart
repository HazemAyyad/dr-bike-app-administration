import 'audio_helper.dart';
import 'show_net_image.dart';
import '../utils/assets_manger.dart';

/// Parsed task attachment URLs (images vs videos).
class TaskMediaPaths {
  const TaskMediaPaths({
    this.images = const [],
    this.videos = const [],
  });

  final List<String> images;
  final List<String> videos;

  bool get isEmpty => images.isEmpty && videos.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

const _videoExtensions = [
  '.mp4',
  '.mov',
  '.avi',
  '.webm',
  '.mkv',
  '.m4v',
  '.3gp',
];

/// Video file path or URL (not audio).
bool isVideoMediaPath(String? value) {
  if (value == null || value.isEmpty) return false;
  if (isNoMediaPlaceholder(value) || isAudioMediaPath(value)) return false;
  final lower = value.trim().toLowerCase();
  return _videoExtensions.any(lower.contains);
}

String resolveTaskMediaUri(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('http://') ||
      trimmed.startsWith('https://') ||
      trimmed.startsWith('file://') ||
      trimmed.startsWith('/') ||
      RegExp(r'^[A-Za-z]:[\\/]').hasMatch(trimmed)) {
    return trimmed;
  }
  return ShowNetImage.getPhoto(trimmed);
}

List<String> _collectRawPaths(dynamic raw) {
  final out = <String>[];
  if (raw == null) return out;
  if (raw is String) {
    if (!isNoMediaPlaceholder(raw)) out.add(raw);
    return out;
  }
  if (raw is List) {
    for (final e in raw) {
      final s = e?.toString().trim() ?? '';
      if (s.isNotEmpty && !isNoMediaPlaceholder(s)) out.add(s);
    }
  }
  return out;
}

TaskMediaPaths parseTaskMediaFromApi(dynamic raw) {
  final images = <String>[];
  final videos = <String>[];

  for (final path in _collectRawPaths(raw)) {
    final uri = resolveTaskMediaUri(path);
    if (uri.isEmpty) continue;
    if (isVideoMediaPath(path) || isVideoMediaPath(uri)) {
      videos.add(uri);
    } else {
      final img = ShowNetImage.getPhoto(path);
      if (img != AssetsManager.noImageNet) {
        images.add(img);
      }
    }
  }

  return TaskMediaPaths(images: images, videos: videos);
}

bool localFileIsVideo(String path) {
  return isVideoMediaPath(path);
}
