import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/product_image_utils.dart';

import 'product_variant_model.dart';

class ProductModel {
  final String id;
  final String nameAr;
  final String stock;
  final List<dynamic> projects;
  final double unitPrice;
  final double wholesalePrice;
  final double rate;
  final String imageUrl;
  final List<String> viewImageUrls;
  final List<String> normalImageUrls;
  final List<String> image3dUrls;

  /// Parent main category id when this row is a subcategory (from API).
  final String? mainCategoryId;

  final String? productCode;
  final String? storeSectionId;
  final String? storeSectionName;
  final bool hasVariants;
  final List<ProductSizeVariant> sizes;

  const ProductModel({
    required this.id,
    required this.nameAr,
    required this.stock,
    required this.projects,
    this.unitPrice = 0,
    this.wholesalePrice = 0,
    this.rate = 0,
    this.imageUrl = '',
    this.viewImageUrls = const [],
    this.normalImageUrls = const [],
    this.image3dUrls = const [],
    this.mainCategoryId,
    this.productCode,
    this.storeSectionId,
    this.storeSectionName,
    this.hasVariants = false,
    this.sizes = const [],
  });

  String get preferredImageUrl => ProductImageUtils.preferredFromLists(
        viewImages: viewImageUrls,
        normalImages: normalImageUrls,
        image3d: image3dUrls,
        fallbackImage: imageUrl,
      );

  List<String> get allImageUrlsInPriority => ProductImageUtils.allValidUrlsInPriority(
        viewImages: viewImageUrls,
        normalImages: normalImageUrls,
        image3d: image3dUrls,
        fallbackImage: imageUrl,
      );

  /// Product code for display; falls back to numeric id when code is missing.
  String get displayProductCode {
    final code = productCode?.trim() ?? '';
    if (code.isNotEmpty) return code;
    return id.trim();
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);

    final idRaw =
        j['id'] ?? j['product_id'] ?? j['category_id'] ?? j['sub_category_id'];
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
      rate: asDouble(j['rate'] ?? 0),
      imageUrl: asString(
        j['product_image'] ?? j['image'] ?? j['imageUrl'],
        '',
      ),
      viewImageUrls:
          ProductImageUtils.allValidUrlsFromList(j['product_viewImages']),
      normalImageUrls:
          ProductImageUtils.allValidUrlsFromList(j['product_normalImages']),
      image3dUrls:
          ProductImageUtils.allValidUrlsFromList(j['product_image3d']),
      mainCategoryId: mainCatRaw == null ? null : asString(mainCatRaw),
      productCode: asNullableString(
        j['product_code'] ?? j['productCode'] ?? j['code'],
      ),
      storeSectionId: asNullableString(j['store_section_id']),
      storeSectionName: asNullableString(j['store_section_name']),
      hasVariants: j['has_variants'] == true || j['hasVariants'] == true,
      sizes: j['sizes'] == null
          ? const []
          : mapList(j['sizes'], (m) => ProductSizeVariant.fromJson(m)),
    );
  }

  static List<dynamic> _projectsFromJson(dynamic raw) {
    if (raw == null) return <dynamic>[];
    if (raw is List) return List<dynamic>.from(raw);
    return <dynamic>[];
  }

  ProductModel copyWith({
    double? unitPrice,
    double? wholesalePrice,
    String? productCode,
    String? storeSectionId,
    String? storeSectionName,
  }) {
    return ProductModel(
      id: id,
      nameAr: nameAr,
      stock: stock,
      projects: projects,
      unitPrice: unitPrice ?? this.unitPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      rate: rate,
      imageUrl: imageUrl,
      viewImageUrls: viewImageUrls,
      normalImageUrls: normalImageUrls,
      image3dUrls: image3dUrls,
      mainCategoryId: mainCategoryId,
      productCode: productCode ?? this.productCode,
      storeSectionId: storeSectionId ?? this.storeSectionId,
      storeSectionName: storeSectionName ?? this.storeSectionName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'stock': stock,
      'projects': projects,
      'normail_price': unitPrice,
      'rate': rate,
      'product_image': imageUrl,
      'product_viewImages': viewImageUrls,
      'product_normalImages': normalImageUrls,
      'product_image3d': image3dUrls,
      if (mainCategoryId != null) 'mainCategoryId': mainCategoryId,
      if (productCode != null) 'product_code': productCode,
      if (storeSectionId != null) 'store_section_id': storeSectionId,
      if (storeSectionName != null) 'store_section_name': storeSectionName,
    };
  }
}
