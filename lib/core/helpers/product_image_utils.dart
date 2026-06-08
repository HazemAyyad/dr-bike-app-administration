import 'json_safe_parser.dart';

class ProductImageUtils {
  ProductImageUtils._();

  static const _invalidTokens = {
    'no image',
    'no img',
    'no images',
    'no image files',
    'no admin image',
    'no employee image',
    'null',
    'undefined',
    'none',
    '-',
    'n/a',
  };

  static bool isValidUrl(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return false;
    return !_invalidTokens.contains(trimmed.toLowerCase());
  }

  static String urlFromItem(dynamic item) {
    if (item is Map) {
      final map = Map<String, dynamic>.from(item);
      return asString(
        map['imageUrl'] ??
            map['image_url'] ??
            map['ImageUrl'] ??
            map['url'] ??
            map['image'],
      );
    }
    return asString(item);
  }

  static String firstValidFromList(dynamic value) {
    for (final url in allValidUrlsFromList(value)) {
      return url;
    }
    return '';
  }

  static List<String> allValidUrlsFromList(dynamic value) {
    final result = <String>[];
    if (value is! List) {
      final url = urlFromItem(value);
      if (isValidUrl(url)) {
        result.add(url.trim());
      }
      return result;
    }

    for (final item in value) {
      final url = urlFromItem(item);
      if (isValidUrl(url)) {
        final trimmed = url.trim();
        if (!result.contains(trimmed)) {
          result.add(trimmed);
        }
      }
    }
    return result;
  }

  static List<String> allValidUrlsInPriority({
    dynamic viewImages,
    dynamic normalImages,
    dynamic image3d,
    String? fallbackImage,
  }) {
    final result = <String>[];
    void append(dynamic source) {
      for (final url in allValidUrlsFromList(source)) {
        if (!result.contains(url)) {
          result.add(url);
        }
      }
    }

    append(viewImages);
    append(normalImages);
    append(image3d);

    if (isValidUrl(fallbackImage)) {
      final trimmed = fallbackImage!.trim();
      if (!result.contains(trimmed)) {
        result.add(trimmed);
      }
    }

    return result;
  }

  static String preferredUrl({
    String? viewImage,
    String? normalImage,
    String? image3d,
    String? fallbackImage,
  }) {
    for (final image in [viewImage, normalImage, image3d, fallbackImage]) {
      if (isValidUrl(image)) {
        return image!.trim();
      }
    }
    return '';
  }

  static String preferredFromLists({
    dynamic viewImages,
    dynamic normalImages,
    dynamic image3d,
    String? fallbackImage,
  }) {
    final urls = allValidUrlsInPriority(
      viewImages: viewImages,
      normalImages: normalImages,
      image3d: image3d,
      fallbackImage: fallbackImage,
    );
    return urls.isEmpty ? '' : urls.first;
  }
}
