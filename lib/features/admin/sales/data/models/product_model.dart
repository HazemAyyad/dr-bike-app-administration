class ProductModel {
  final String id;
  final String nameAr;

  const ProductModel({
    required this.id,
    required this.nameAr,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      nameAr: json['nameAr'] != null && json['nameAr'].isNotEmpty
          ? json['nameAr']
          : json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
    };
  }
}
