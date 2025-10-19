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
    return ProductDevelopmentModel(
      id: json['id'] ?? 0,
      productName: json['product_name'] ?? '',
      productImage: json['product_image'] ?? '',
      description: json['description'] ?? '',
      currentStep: json['current_step'] ?? '',
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
