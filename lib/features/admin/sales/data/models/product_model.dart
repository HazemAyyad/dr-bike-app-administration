import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class ProductModel {
  final String id;
  final String nameAr;
  final String stock;
  final List<dynamic> projects;
  final double unitPrice;
  final double wholesalePrice;
  final String imageUrl;
  /// Parent main category id when this row is a subcategory (from API).
  final String? mainCategoryId;

  const ProductModel({
    required this.id,
    required this.nameAr,
    required this.stock,
    required this.projects,
    this.unitPrice = 0,
    this.wholesalePrice = 0,
    this.imageUrl = '',
    this.mainCategoryId,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);

    final idRaw = j['id'] ??
        j['product_id'] ??
        j['category_id'] ??
        j['sub_category_id'];
    final nameRaw = j['nameAr'] ??
        j['name'] ??
        j['product_name'] ??
        j['category_name'] ??
        j['sub_category_name'] ??
        j['title'];
    final stockRaw = j['stock'] ?? j['product_stock'] ?? j['quantity'];
    final mainCatRaw = j['mainCategoryId'] ?? j['main_category_id'];

    return ProductModel(
      id: asString(idRaw),
      nameAr: asString(nameRaw),
      stock: asString(stockRaw),
      projects: _projectsFromJson(j['projects']),
      unitPrice: asDouble(
        j['normail_price'] ?? j['normailPrice'] ?? j['price'] ?? 0,
      ),
      wholesalePrice: asDouble(
        j['wholesale_price'] ?? j['wholesalePrice'] ?? 0,
      ),
      imageUrl: asString(
        j['product_image'] ?? j['image'] ?? j['imageUrl'],
        '',
      ),
      mainCategoryId: mainCatRaw == null ? null : asString(mainCatRaw),
    );
  }

  static List<dynamic> _projectsFromJson(dynamic raw) {
    if (raw == null) return <dynamic>[];
    if (raw is List) return List<dynamic>.from(raw);
    return <dynamic>[];
  }

  ProductModel copyWith({double? unitPrice, double? wholesalePrice}) {
    return ProductModel(
      id: id,
      nameAr: nameAr,
      stock: stock,
      projects: projects,
      unitPrice: unitPrice ?? this.unitPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      imageUrl: imageUrl,
      mainCategoryId: mainCategoryId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'stock': stock,
      'projects': projects,
      'normail_price': unitPrice,
      'product_image': imageUrl,
      if (mainCategoryId != null) 'mainCategoryId': mainCategoryId,
    };
  }
}
