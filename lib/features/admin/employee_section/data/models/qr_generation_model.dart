import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../domain/entities/qr_generation_entity.dart';

class QrGenerationModel extends QrGenerationEntity {
  const QrGenerationModel({
    required String codeText,
    required String qrImageUrl,
  }) : super(
          codeText: codeText,
          qrImageUrl: qrImageUrl,
        );

  factory QrGenerationModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return QrGenerationModel(
      codeText: asString(j[ApiKey.code_text]),
      qrImageUrl: ShowNetImage.getPhoto(asNullableString(j[ApiKey.qr_image_url])),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.code_text: codeText,
      ApiKey.qr_image_url: qrImageUrl,
    };
  }
}
