class ProductModel {
  final String id;
  final String nameAr;
  final String stock;
  final List<dynamic> projects;

  const ProductModel({
    required this.id,
    required this.nameAr,
    required this.stock,
    required this.projects,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      nameAr: json['nameAr'] != null && json['nameAr'].isNotEmpty
          ? json['nameAr']
          : json['name'] ?? '',
      stock: json['stock'] ?? '',
      projects: json['projects'] != null && json['projects'].isNotEmpty
          ? json['projects']
          : json['projects'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'stock': stock,
      'projects': projects,
    };
  }
}
