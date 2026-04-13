import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

import '../../../../../core/utils/assets_manger.dart';

class GeneralDataModel {
  final int id;
  final String phone;
  final String jobTitle;
  final String name;
  final String isCanceled;
  final String? idImage;
  final String? type;

  GeneralDataModel({
    required this.id,
    required this.phone,
    required this.jobTitle,
    required this.name,
    required this.isCanceled,
    this.idImage,
    this.type,
  });

  factory GeneralDataModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    final idImgRaw = j['ID_image'];
    return GeneralDataModel(
      id: asInt(j['id']),
      phone: asString(j['phone']),
      jobTitle: asString(j['job_title']),
      name: asString(j['name']),
      isCanceled: asString(j['is_canceled'], '0'),
      idImage: (idImgRaw != null && asString(idImgRaw).isNotEmpty)
          ? ShowNetImage.getPhoto(asNullableString(idImgRaw))
          : AssetsManager.noImageNet,
      type: asNullableString(j['type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'job_title': jobTitle,
      'name': name,
      'is_canceled': isCanceled,
      'ID_image': idImage,
      'type': type,
    };
  }
}
