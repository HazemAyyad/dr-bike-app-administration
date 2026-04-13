import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class ProductDevelopmentModel {
  final int id;
  final String productName;
  final String productImage;
  final String description;
  final String currentStep;

  ProductDevelopmentModel({
    required this.id,
    required this.productName,
    required this.productImage,
    required this.description,
    required this.currentStep,
  });

  factory ProductDevelopmentModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return ProductDevelopmentModel(
      id: asInt(j['id']),
      productName: asString(j['product_name']),
      productImage: asString(j['product_image']),
      description: asString(j['description']),
      currentStep: asString(j['current_step']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_name': productName,
      'product_image': productImage,
      'description': description,
      'current_step': currentStep,
    };
  }
}
