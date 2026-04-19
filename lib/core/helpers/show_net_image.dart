import 'package:doctorbike/core/databases/api/end_points.dart';

import '../utils/assets_manger.dart';

/// مصدر الصورة في الواجهة (شارة على الصورة).
enum ProductImageSource {
  /// مسار يبدأ بـ `Images/Items/` — صور الأرشيف المنقولة إلى Laravel public
  legacyDotNetStore,
  /// مسار يبدأ بـ `storage/product-uploads` — صور محلية في Laravel
  laravelStorage,
  unknown,
}

/// يزيل تكرار `public/` عندما يكون [baserUrlForImage] يُنهي بـ `/public/`
/// والمسار القادم من Laravel يبدأ بـ `public/...` (فيصبح `/public/public/...`).
String _normalizeRelativeMediaPath(String raw) {
  var p = raw.trim();
  if (p.startsWith('http://') || p.startsWith('https://')) return p;
  while (p.startsWith('public/')) {
    p = p.substring(7);
  }
  while (p.startsWith('/public/')) {
    p = p.substring(8);
  }
  return p;
}

class ShowNetImage {
  /// يصنّف المسار **الخام** القادم من الـ API (قبل [getPhoto]) لعرض الشارة.
  static ProductImageSource classifySource(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'no image') {
      return ProductImageSource.unknown;
    }
    final t = raw.trim();
    final lower = t.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      final uri = Uri.tryParse(t);
      if (uri != null) {
        if (uri.host == 'mjsall-001-site1.jtempurl.com') {
          return ProductImageSource.legacyDotNetStore;
        }
        if (uri.host.contains('dr-bike.duosparktech.com') ||
            uri.path.contains('/storage/product-uploads')) {
          return ProductImageSource.laravelStorage;
        }
      }
      return ProductImageSource.unknown;
    }
    if (lower.startsWith('images/items/')) {
      return ProductImageSource.legacyDotNetStore;
    }
    if (lower.startsWith('storage/product-uploads') ||
        lower.contains('storage/product-uploads')) {
      return ProductImageSource.laravelStorage;
    }
    return ProductImageSource.unknown;
  }

  /// مثل [getPhoto] لكن يعيد الـ thumbnail لصور `Images/Items/` (للقوائم فقط).
  static String getThumbnailPhoto(String? path) {
    if (path == null || path.isEmpty) return getPhoto(path);
    final normalized = path.replaceAll('\\', '/');
    if (normalized.toLowerCase().startsWith('images/items/')) {
      final thumbPath = normalized.replaceFirst('Images/Items/', 'Images/Items/thumb/');
      final base = EndPoints.baserUrlForImage;
      return base.endsWith('/') ? '$base$thumbPath' : '$base/$thumbPath';
    }
    return getPhoto(path);
  }

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
    final t = photoUrl.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) {
      return t;
    }
    var normalized = _normalizeRelativeMediaPath(photoUrl);
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }
    // مسارات Images/Items/… مُنقولة إلى Laravel public — تُحمَّل مباشرةً من نفس النطاق
    final normLower = normalized.toLowerCase();
    if (normLower.startsWith('images/items/')) {
      final base = EndPoints.baserUrlForImage;
      return base.endsWith('/') ? '$base$normalized' : '$base/$normalized';
    }
    final base = EndPoints.baserUrlForImage;
    final sep = base.endsWith('/') || normalized.startsWith('/') ? '' : '/';
    return '$base$sep$normalized';
  }
}
