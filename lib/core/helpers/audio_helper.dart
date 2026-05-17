import '../utils/assets_manger.dart';
import 'show_net_image.dart';

/// قيم فارغة/بديلة من الـ API — ليست ملف صوت حقيقي.
bool isNoMediaPlaceholder(String? value) {
  if (value == null || value.isEmpty) return true;
  final lower = value.trim().toLowerCase();
  const placeholders = {
    'no audio',
    'no image',
    'no img',
    'no images',
    'no employee image',
    'no admin image',
    'no image files',
    'null',
  };
  if (placeholders.contains(lower)) return true;
  if (lower == AssetsManager.noImageNet.toLowerCase()) return true;
  if (lower.contains('gstatic.com/images')) return true;
  return false;
}

/// مسار يشير لملف صوت (وليس صورة).
bool isAudioMediaPath(String? value) {
  if (value == null || value.isEmpty) return false;
  final lower = value.trim().toLowerCase();
  return lower.contains('.m4a') ||
      lower.contains('.aac') ||
      lower.contains('.mp3') ||
      lower.contains('.wav') ||
      lower.contains('employeetasksaudio');
}

/// Returns true when [audio] is a non-empty playable recording URL/path.
bool hasPlayableAudio(String? audio) {
  if (audio == null || audio.isEmpty) return false;
  if (isNoMediaPlaceholder(audio)) return false;
  return isAudioMediaPath(audio);
}

/// من حقل audio في الـ API — null إن لم يكن هناك تسجيل.
String? parseAudioFromApi(String? raw) {
  if (!hasPlayableAudio(raw)) return null;
  return resolveAudioPlaybackUri(raw!.trim());
}

/// مسار التشغيل: ملف محلي على الجهاز أو رابط كامل من السيرفر.
String resolveAudioPlaybackUri(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return '';

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }

  if (trimmed.startsWith('/') || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(trimmed)) {
    return trimmed;
  }

  return ShowNetImage.getPhoto(trimmed);
}

bool isNetworkAudioUri(String uri) {
  return uri.startsWith('http://') || uri.startsWith('https://');
}
