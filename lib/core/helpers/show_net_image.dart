import 'package:doctorbike/core/databases/api/end_points.dart';

import '../utils/assets_manger.dart';

/// مصدر الصورة في الواجهة (شارة على الصورة).
enum ProductImageSource {
  /// مسار يبدأ بـ `Images/Items/` أو رابط مضيف المتجر .NET القديم
  legacyDotNetStore,
  /// مسار يبدأ بـ `storage/product-uploads` أو رابط Laravel
  laravelStorage,
  unknown,
}

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
    // روابط مطلقة: روابط mjsall تُفشل بـ CORS وتفشل على Android — نمرّرها دائماً عبر بروكسي Laravel
    if (t.startsWith('http://') || t.startsWith('https://')) {
      final uri = Uri.tryParse(t);
      if (uri != null && uri.host == 'mjsall-001-site1.jtempurl.com') {
        var path = uri.path.replaceFirst(RegExp(r'^/'), '');
        if (path.toLowerCase().startsWith('images/items/')) {
          return '${EndPoints.baserUrl}legacy-store-image?path=${Uri.encodeComponent(path)}';
        }
      }
      return t;
    }
    var normalized = _normalizeRelativeMediaPath(photoUrl);
    normalized = _stripLegacyStoreHostToRelativePath(normalized);
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }
    // مسارات Images/Items/… تخص خادم المتجر .NET — نمرّرها دائماً عبر بروكسي Laravel لجميع المنصات
    final normLower = normalized.toLowerCase();
    if (normLower.startsWith('images/items/')) {
      final path =
          normalized.startsWith('/') ? normalized.substring(1) : normalized;
      return '${EndPoints.baserUrl}legacy-store-image?path=${Uri.encodeComponent(path)}';
    }
    final base = EndPoints.baserUrlForImage;
    final sep = base.endsWith('/') || normalized.startsWith('/') ? '' : '/';
    return '$base$sep$normalized';
  }
}
