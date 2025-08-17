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
    return QrGenerationModel(
      codeText: json[ApiKey.code_text] ?? '',
      qrImageUrl: ShowNetImage.getPhoto(json[ApiKey.qr_image_url]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.code_text: codeText,
      ApiKey.qr_image_url: qrImageUrl,
    };
  }
}
