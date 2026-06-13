import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/product_image_utils.dart';

import 'product_tag_model.dart';

class AllStockProductsModel {
  final int closeoutId;
  final String closeoutStatus;
  final String productId;
  final String name;
  final String stock;
  final String productMinSalePrice;
  final double normailPrice;
  final String image;
  final List<String> viewImageUrls;
  final List<String> normalImageUrls;
  final List<String> image3dUrls;
  final String numberOfUsedProducts;
  final String productCode;
  final List<ProductTagModel> tags;
  final String? storeSectionId;
  final String? storeSectionName;

  AllStockProductsModel({
    required this.closeoutId,
    required this.closeoutStatus,
    required this.productId,
    required this.name,
    required this.stock,
    required this.productMinSalePrice,
    this.normailPrice = 0,
    required this.image,
    this.viewImageUrls = const [],
    this.normalImageUrls = const [],
    this.image3dUrls = const [],
    required this.numberOfUsedProducts,
    this.productCode = '',
    this.tags = const [],
    this.storeSectionId,
    this.storeSectionName,
  });

  factory AllStockProductsModel.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tags'];
    final tags = tagsRaw is List
        ? tagsRaw
            .whereType<Map>()
            .map((e) => ProductTagModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <ProductTagModel>[];
    return AllStockProductsModel(
      closeoutId: asInt(json['closeout_id']),
      closeoutStatus: asString(json['closeout_status'], 'unarchived'),
      productId: asString(json['product_id'], '0'),
      name: asString(json['product_name'], 'Unknown'),
      stock: asString(json['product_stock'], '0'),
      productMinSalePrice: asString(json['product_min_sale_price'], '0'),
      normailPrice: asDouble(
        json['product_normail_price'] ?? json['normail_price'],
      ),
      image: asString(json['product_image']),
      viewImageUrls:
          ProductImageUtils.allValidUrlsFromList(json['product_viewImages']),
      normalImageUrls:
          ProductImageUtils.allValidUrlsFromList(json['product_normalImages']),
      image3dUrls:
          ProductImageUtils.allValidUrlsFromList(json['product_image3d']),
      numberOfUsedProducts: asString(json['number_of_used_products'], '0'),
      productCode: asString(json['product_code']),
      tags: tags,
      storeSectionId: asNullableString(json['store_section_id']),
      storeSectionName: asNullableString(json['store_section_name']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'closeout_id': closeoutId,
      'closeout_status': closeoutStatus,
      'product_id': productId,
      'product_name': name,
      'product_stock': stock,
      'product_min_sale_price': productMinSalePrice,
      'product_image': image,
      'product_viewImages': viewImageUrls,
      'product_normalImages': normalImageUrls,
      'product_image3d': image3dUrls,
      'number_of_used_products': numberOfUsedProducts,
      'product_code': productCode,
      'tags': tags.map((e) => e.toJson()).toList(),
      'store_section_id': storeSectionId,
      'store_section_name': storeSectionName,
    };
  }

  List<String> get allImageUrlsInPriority => ProductImageUtils.allValidUrlsInPriority(
        viewImages: viewImageUrls,
        normalImages: normalImageUrls,
        image3d: image3dUrls,
        fallbackImage: image,
      );

  String get preferredImageUrl => ProductImageUtils.preferredFromLists(
        viewImages: viewImageUrls,
        normalImages: normalImageUrls,
        image3d: image3dUrls,
        fallbackImage: image,
      );
}
