import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

class DestructionModel {
  final int destructionId;
  final String productId;
  final String productName;
  final int destructionValue;
  final String piecesNumber;
  final String destructionReason;
  final DateTime createdAt;
  final List<String> image;

  DestructionModel({
    required this.destructionId,
    required this.productId,
    required this.productName,
    required this.destructionValue,
    required this.piecesNumber,
    required this.destructionReason,
    required this.createdAt,
    required this.image,
  });

  factory DestructionModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    List<String> mapImages(dynamic raw) {
      if (raw is! List) return [];
      return raw
          .map((x) => ShowNetImage.getPhoto(asNullableString(x)))
          .toList();
    }

    return DestructionModel(
      destructionId: asInt(j['destruction_id']),
      productId: asString(j['product_id']),
      productName: asString(j['product_name']),
      destructionValue: asInt(j['destruction_value']),
      piecesNumber: asString(j['pieces_number']),
      destructionReason: asString(j['destruction_reason']),
      createdAt: parseApiDateTime(j['created_at']),
      image: mapImages(j['image']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'destruction_id': destructionId,
      'product_id': productId,
      'product_name': productName,
      'destruction_value': destructionValue,
      'pieces_number': piecesNumber,
      'destruction_reason': destructionReason,
      'created_at': createdAt,
      'image': image,
    };
  }
}
