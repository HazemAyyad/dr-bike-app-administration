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
    return DestructionModel(
      destructionId: json['destruction_id'] ?? 0,
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      destructionValue: json['destruction_value'] ?? 0,
      piecesNumber: json['pieces_number'] ?? '',
      destructionReason: json['destruction_reason'] ?? '',
      createdAt: DateTime.tryParse(json['created_at']) ?? DateTime.now(),
      image: json['image'] != null
          ? List<String>.from(
              json['image'].map((x) => ShowNetImage.getPhoto(x)))
          : [],
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
