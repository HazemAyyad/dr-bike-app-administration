import 'package:doctorbike/core/databases/api/end_points.dart';

import '../utils/assets_manger.dart';

/// يزيل تكرار `public/` عندما يكون [baserUrlForImage] يُنهي بـ `/public/`
/// والمسار القادم من Laravel يبدأ بـ `public/...` (فيصبح `/public/public/...`).
/// Legacy store host (STORE_DOMAIN) does not send CORS headers; serve path via app CDN instead.
String _stripLegacyStoreHostToRelativePath(String raw) {
  final u = raw.trim();
  if (!u.startsWith('http://') && !u.startsWith('https://')) return u;
  final uri = Uri.tryParse(u);
  if (uri == null || uri.host.isEmpty) return u;
  if (uri.host == 'mjsall-001-site1.jtempurl.com') {
    final path = uri.path.isEmpty ? '' : uri.path.replaceFirst(RegExp(r'^/'), '');
    return path;
  }
  return u;
}

String _normalizeRelativeMediaPath(String raw) {
  var p = raw.trim();
  if (p.startsWith('http://') || p.startsWith('https://')) {
    return _stripLegacyStoreHostToRelativePath(p);
  }
  while (p.startsWith('public/')) {
    p = p.substring(7);
  }
  while (p.startsWith('/public/')) {
    p = p.substring(8);
  }
  return p;
}

class ShowNetImage {
  static String getPhoto(String? photoUrl) {
    if (photoUrl == null ||
        photoUrl == 'null' ||
        photoUrl.isEmpty ||
        photoUrl == '' ||
        photoUrl == 'no img' ||
        photoUrl == 'no images' ||
        photoUrl == 'no image' ||
        photoUrl == 'no admin image' ||
        photoUrl == 'no employee image' ||
        photoUrl == 'no audio' ||
        photoUrl == 'no image files') {
      return AssetsManager.noImageNet;
    }
    var normalized = _normalizeRelativeMediaPath(photoUrl);
    normalized = _stripLegacyStoreHostToRelativePath(normalized);
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }
    final base = EndPoints.baserUrlForImage;
    final sep = base.endsWith('/') || normalized.startsWith('/') ? '' : '/';
    return '$base$sep$normalized';
  }
}
