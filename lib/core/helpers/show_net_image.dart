import 'package:doctorbike/core/databases/api/end_points.dart';

import '../utils/assets_manger.dart';

class ShowNetImage {
  static String getPhoto(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return AssetsManger.noImageNet; // صورة افتراضية إذا كانت الصورة غير متاحة
    }
    return "${EndPoints.baserUrlForImage}$photoUrl/";
  }
}
