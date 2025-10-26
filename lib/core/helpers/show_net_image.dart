import 'package:doctorbike/core/databases/api/end_points.dart';

import '../utils/assets_manger.dart';

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
    return "${EndPoints.baserUrlForImage}$photoUrl";
  }
}
