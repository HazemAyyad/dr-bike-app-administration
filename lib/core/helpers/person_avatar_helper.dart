import 'show_net_image.dart';
import '../utils/assets_manger.dart';

/// حل مسار صورة الزبون/التاجر — شعار دكتور بايك عند عدم وجود صورة.
class PersonAvatarHelper {
  static const String placeholder = AssetsManager.personAvatarPlaceholder;

  static bool isPlaceholder(String? url) {
    if (url == null || url.trim().isEmpty) return true;
    final t = url.trim();
    return t == placeholder ||
        t == AssetsManager.noImageNet ||
        t.endsWith(placeholder);
  }

  static bool isAssetPath(String url) => url.startsWith('assets/');

  static String resolve(dynamic raw) {
    if (raw == null) return placeholder;

    if (raw is List) {
      if (raw.isEmpty) return placeholder;
      return resolve(raw.first);
    }

    final value = raw.toString().trim();
    if (value.isEmpty ||
        value == 'null' ||
        value == 'no img' ||
        value == 'no image' ||
        value == 'no images' ||
        value == 'no admin image' ||
        value == '[]') {
      return placeholder;
    }

    final resolved = ShowNetImage.getPhoto(value);
    if (resolved == AssetsManager.noImageNet) {
      return placeholder;
    }

    return resolved;
  }
}
