import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class ProductSizeVariant {
  final String id;
  final String size;
  final List<ProductColorVariant> colorSizes;

  const ProductSizeVariant({
    required this.id,
    required this.size,
    required this.colorSizes,
  });

  factory ProductSizeVariant.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return ProductSizeVariant(
      id: asString(j['id']),
      size: asString(j['size']),
      colorSizes: j['color_sizes'] == null
          ? const []
          : mapList(j['color_sizes'], (m) => ProductColorVariant.fromJson(m)),
    );
  }
}

class ProductColorVariant {
  final String id;
  final String sizeId;
  final String colorAr;
  final String? colorEn;
  final String? colorAbbr;
  final int stock;
  final double normailPrice;
  final double wholesalePrice;
  final double discount;
  final String imageUrl;

  const ProductColorVariant({
    required this.id,
    required this.sizeId,
    required this.colorAr,
    this.colorEn,
    this.colorAbbr,
    required this.stock,
    required this.normailPrice,
    this.wholesalePrice = 0,
    this.discount = 0,
    this.imageUrl = '',
  });

  String get sizeColorKey => '$sizeId-$id';

  double get effectiveUnitPrice => normailPrice > 0 ? normailPrice : 0;

  factory ProductColorVariant.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return ProductColorVariant(
      id: asString(j['id']),
      sizeId: asString(j['size_id'] ?? j['sizeId']),
      colorAr: asString(j['colorAr'] ?? j['color_ar'] ?? j['color_name']),
      colorEn: asNullableString(j['colorEn'] ?? j['color_en']),
      colorAbbr: asNullableString(j['colorAbbr'] ?? j['color_abbr']),
      stock: asInt(j['stock']),
      normailPrice: asDouble(j['normailPrice'] ?? j['normail_price'] ?? 0),
      wholesalePrice:
          asDouble(j['wholesalePrice'] ?? j['wholesale_price'] ?? 0),
      discount: asDouble(j['discount'] ?? 0),
      imageUrl: asString(j['image_url'] ?? j['imageUrl'], ''),
    );
  }
}
