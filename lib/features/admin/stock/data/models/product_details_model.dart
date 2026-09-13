import 'package:doctorbike/core/helpers/json_safe_parser.dart';

import 'product_tag_model.dart';

class ProductDetailsModel {
  String id;
  String? productCode;
  List<ProductTagModel>? productTags;
  String nameAr;
  DateTime createdAt;
  DateTime updatedAt;
  dynamic price;
  String nameEng;
  String? nameAbree;
  String? isShow;
  String? descriptionAr;
  String? descriptionEng;
  String? descriptionAbree;
  dynamic videoUrl;
  String? normailPrice;
  String? wholesalePrice;
  String? stock;
  String? model;
  String? isNewItem;
  String? isMoreSales;
  String? rate;
  String? manufactureYear;
  String? discount;
  dynamic userIdAdd;
  DateTime? dateAdd;
  dynamic userIdUpdate;
  DateTime? dateUpdate;
  dynamic minStock;
  dynamic rotationDate;
  dynamic minSalePrice;
  dynamic isSoldWithPaper;
  dynamic projectId;

  /// Main category id from `products.category_id` (API).
  String? categoryId;

  /// Resolved main category label from API `category_name` (preferred over inferring from subs).
  String? categoryName;
  String? storeSectionId;
  String? storeSectionName;

  /// Flat list from API `sub_categories` when present.
  List<String>? subCategoryIds;
  List<ProductSubCategory>? productSubCategories;
  List<PurchasePrice>? purchasePrices;
  List<Size>? sizes;
  List<dynamic>? wholesales;
  List<String>? normalImages;
  List<String>? viewImages;
  List<String>? image3d;
  List<ProductMediaItem>? normalImageItems;
  List<ProductMediaItem>? viewImageItems;
  List<ProductMediaItem>? image3dItems;
  dynamic purchase;
  InventorySummary? inventory;
  bool canViewInventoryCost;

  ProductDetailsModel({
    required this.id,
    this.productCode,
    this.productTags,
    required this.nameAr,
    required this.createdAt,
    required this.updatedAt,
    required this.price,
    required this.nameEng,
    this.nameAbree,
    this.isShow,
    this.descriptionAr,
    this.descriptionEng,
    this.descriptionAbree,
    this.videoUrl,
    this.normailPrice,
    this.wholesalePrice,
    this.stock,
    this.model,
    this.isNewItem,
    this.isMoreSales,
    this.rate,
    this.manufactureYear,
    this.discount,
    this.userIdAdd,
    this.dateAdd,
    this.userIdUpdate,
    this.dateUpdate,
    this.minStock,
    this.rotationDate,
    this.minSalePrice,
    this.isSoldWithPaper,
    this.projectId,
    this.categoryId,
    this.categoryName,
    this.storeSectionId,
    this.storeSectionName,
    this.subCategoryIds,
    this.productSubCategories,
    this.purchasePrices,
    this.sizes,
    this.wholesales,
    this.normalImages,
    this.viewImages,
    this.image3d,
    this.normalImageItems,
    this.viewImageItems,
    this.image3dItems,
    this.purchase,
    this.inventory,
    this.canViewInventoryCost = false,
  });

  static List<ProductMediaItem>? _parseMediaItems(dynamic v) {
    if (v is! List) {
      return null;
    }
    final out = <ProductMediaItem>[];
    for (final e in v) {
      if (e is Map) {
        final m = Map<String, dynamic>.from(e);
        out.add(ProductMediaItem(
          id: asString(m['id']),
          url: asNullableString(m['url']),
        ));
      }
    }
    return out.isEmpty ? null : out;
  }

  static List<String>? _parseSubCategoryIdList(dynamic v) {
    if (v is! List) {
      return null;
    }
    final out = <String>[];
    for (final e in v) {
      if (e == null) {
        continue;
      }
      final s = e.toString().trim();
      if (s.isNotEmpty) {
        out.add(s);
      }
    }
    return out.isEmpty ? null : out;
  }

  factory ProductDetailsModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    List<ProductTagModel>? pTags;
    final pt = j['product_tags'];
    if (pt is List) {
      pTags = pt
          .whereType<Map>()
          .map((e) => ProductTagModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return ProductDetailsModel(
      id: asString(j['id']),
      productCode: asNullableString(j['product_code']),
      productTags: pTags,
      nameAr: asString(j['nameAr']),
      createdAt: parseApiDateTime(j['created_at']),
      updatedAt: parseApiDateTime(j['updated_at']),
      price: j['price'],
      nameEng: asString(j['nameEng']),
      nameAbree: asNullableString(j['nameAbree']),
      isShow: asNullableString(j['isShow']),
      descriptionAr: asNullableString(j['descriptionAr']),
      descriptionEng: asNullableString(j['descriptionEng']),
      descriptionAbree: asNullableString(j['descriptionAbree']),
      videoUrl: j['videoUrl'] ?? j['video_url'],
      normailPrice: asNullableString(j['normailPrice']),
      wholesalePrice: asNullableString(j['wholesalePrice']),
      stock: asNullableString(j['stock']),
      model: asNullableString(j['model']),
      isNewItem: asNullableString(j['isNewItem']),
      isMoreSales: asNullableString(j['isMoreSales']),
      rate: asNullableString(j['rate']),
      manufactureYear: asNullableString(j['manufactureYear']),
      discount: asNullableString(j['discount']),
      userIdAdd: j['userIdAdd'],
      dateAdd: j['dateAdd'] == null ? null : parseApiDateTime(j['dateAdd']),
      userIdUpdate: j['userIdUpdate'],
      dateUpdate:
          j['dateUpdate'] == null ? null : parseApiDateTime(j['dateUpdate']),
      minStock: j['min_stock'],
      rotationDate: j['rotation_date'],
      minSalePrice: j['min_sale_price'],
      isSoldWithPaper: j['is_sold_with_paper'],
      projectId: j['project_id'],
      categoryId: asNullableString(j['category_id']),
      categoryName: asNullableString(j['category_name']),
      storeSectionId: asNullableString(j['store_section_id']),
      storeSectionName: asNullableString(j['store_section_name']),
      subCategoryIds: _parseSubCategoryIdList(j['sub_categories']),
      productSubCategories: j['product_subCategories'] == null
          ? null
          : mapList(
              j['product_subCategories'],
              (m) => ProductSubCategory.fromJson(m),
            ),
      purchasePrices: j['purchase_prices'] == null
          ? null
          : mapList(j['purchase_prices'], (m) => PurchasePrice.fromJson(m)),
      sizes: j['sizes'] == null
          ? null
          : mapList(j['sizes'], (m) => Size.fromJson(m)),
      wholesales: j['wholesales'] is List
          ? List<dynamic>.from(j['wholesales'] as List)
          : null,
      normalImages: j['product_normalImages'] is List
          ? (j['product_normalImages'] as List).map((v) => asString(v)).toList()
          : null,
      viewImages: j['product_viewImages'] is List
          ? (j['product_viewImages'] as List).map((v) => asString(v)).toList()
          : null,
      image3d: j['product_image3d'] is List
          ? (j['product_image3d'] as List).map((v) => asString(v)).toList()
          : null,
      normalImageItems: _parseMediaItems(j['product_normalImages_items']),
      viewImageItems: _parseMediaItems(j['product_viewImages_items']),
      image3dItems: _parseMediaItems(j['product_image3d_items']),
      purchase: j['purchase'],
      inventory: j['inventory'] is Map
          ? InventorySummary.fromJson(asMap(j['inventory']))
          : null,
      canViewInventoryCost: j['can_view_inventory_cost'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['product_code'] = productCode;
    if (productTags != null) {
      data['product_tags'] = productTags!.map((e) => e.toJson()).toList();
    }
    data['nameAr'] = nameAr;
    data['created_at'] = createdAt.toIso8601String();
    data['updated_at'] = updatedAt.toIso8601String();
    data['price'] = price;
    data['nameEng'] = nameEng;
    data['nameAbree'] = nameAbree;
    data['isShow'] = isShow;
    data['descriptionAr'] = descriptionAr;
    data['descriptionEng'] = descriptionEng;
    data['descriptionAbree'] = descriptionAbree;
    data['videoUrl'] = videoUrl;
    data['normailPrice'] = normailPrice;
    data['wholesalePrice'] = wholesalePrice;
    data['stock'] = stock;
    data['model'] = model;
    data['isNewItem'] = isNewItem;
    data['isMoreSales'] = isMoreSales;
    data['rate'] = rate;
    data['manufactureYear'] = manufactureYear;
    data['discount'] = discount;
    data['userIdAdd'] = userIdAdd;
    data['dateAdd'] = dateAdd;
    data['userIdUpdate'] = userIdUpdate;
    data['dateUpdate'] = dateUpdate;
    data['min_stock'] = minStock;
    data['rotation_date'] = rotationDate;
    data['min_sale_price'] = minSalePrice;
    data['is_sold_with_paper'] = isSoldWithPaper;
    data['project_id'] = projectId;
    data['category_id'] = categoryId;
    data['category_name'] = categoryName;
    if (subCategoryIds != null) {
      data['sub_categories'] = subCategoryIds;
    }

    if (productSubCategories != null) {
      data['product_subCategories'] =
          productSubCategories!.map((v) => v.toJson()).toList();
    }
    if (purchasePrices != null) {
      data['purchase_prices'] = purchasePrices!.map((v) => v.toJson()).toList();
    }
    if (sizes != null) {
      data['sizes'] = sizes!.map((v) => v.toJson()).toList();
    }
    data['wholesales'] = wholesales;
    if (normalImages != null) {
      data['product_normalImages'] = normalImages!.toList();
    }
    if (viewImages != null) {
      data['product_viewImages'] = viewImages!.toList();
    }
    if (image3d != null) {
      data['product_image3d'] = image3d!.toList();
    }
    data['purchase'] = purchase;
    data['inventory'] = inventory?.toJson();
    data['can_view_inventory_cost'] = canViewInventoryCost;

    return data;
  }
}

class InventorySummary {
  final double quantityOnHand;
  final double costedQuantity;
  final double missingCostQuantity;
  final String costingMethod;
  final String currency;
  final double? inventoryValue;
  final double? averageUnitCost;
  final double? nextFifoUnitCost;
  final bool coverageComplete;
  final bool hasVariants;
  final List<InventoryIdentitySummary> variants;
  final List<InventoryCostLayerDetails> costLayers;
  final List<InventoryAuditEntry> recentMovements;
  final List<InventoryAuditEntry> lastAdjustments;

  const InventorySummary({
    required this.quantityOnHand,
    required this.costedQuantity,
    required this.missingCostQuantity,
    required this.costingMethod,
    required this.currency,
    required this.inventoryValue,
    required this.averageUnitCost,
    required this.nextFifoUnitCost,
    required this.coverageComplete,
    required this.hasVariants,
    required this.variants,
    required this.costLayers,
    required this.recentMovements,
    required this.lastAdjustments,
  });

  factory InventorySummary.fromJson(Map<String, dynamic> json) {
    return InventorySummary(
      quantityOnHand: asDouble(json['quantity_on_hand']),
      costedQuantity: asDouble(json['costed_quantity']),
      missingCostQuantity: asDouble(json['missing_cost_quantity']),
      costingMethod: asString(json['costing_method'], 'fifo'),
      currency: asString(json['currency'], 'شيكل'),
      inventoryValue: json['inventory_value'] == null
          ? null
          : asDouble(json['inventory_value']),
      averageUnitCost: json['average_inventory_unit_cost'] == null
          ? null
          : asDouble(json['average_inventory_unit_cost']),
      nextFifoUnitCost: json['next_fifo_unit_cost'] == null
          ? null
          : asDouble(json['next_fifo_unit_cost']),
      coverageComplete: json['cost_coverage_complete'] == true,
      hasVariants: json['has_variants'] == true,
      variants: mapList(
        json['variants'],
        (item) => InventoryIdentitySummary.fromJson(item),
      ),
      costLayers: mapList(
        json['cost_layers'],
        (item) => InventoryCostLayerDetails.fromJson(item),
      ),
      recentMovements: mapList(
        json['recent_movements'],
        (item) => InventoryAuditEntry.fromJson(item),
      ),
      lastAdjustments: mapList(
        json['last_adjustments'],
        (item) => InventoryAuditEntry.fromJson(item),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'quantity_on_hand': quantityOnHand,
        'costed_quantity': costedQuantity,
        'missing_cost_quantity': missingCostQuantity,
        'costing_method': costingMethod,
        'currency': currency,
        'inventory_value': inventoryValue,
        'average_inventory_unit_cost': averageUnitCost,
        'next_fifo_unit_cost': nextFifoUnitCost,
        'cost_coverage_complete': coverageComplete,
        'has_variants': hasVariants,
        'variants': variants.map((e) => e.toJson()).toList(),
        'cost_layers': costLayers.map((e) => e.toJson()).toList(),
        'recent_movements': recentMovements.map((e) => e.toJson()).toList(),
        'last_adjustments': lastAdjustments.map((e) => e.toJson()).toList(),
      };
}

class InventoryAuditEntry {
  const InventoryAuditEntry({
    required this.id,
    this.type,
    this.reference,
    this.quantity,
    this.stockBefore,
    this.stockAfter,
    this.valueDifference,
    this.reason,
    this.notes,
    this.variantLabel,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String? type;
  final String? reference;
  final double? quantity;
  final double? stockBefore;
  final double? stockAfter;
  final double? valueDifference;
  final String? reason;
  final String? notes;
  final String? variantLabel;
  final String? createdBy;
  final String? createdAt;

  factory InventoryAuditEntry.fromJson(Map<String, dynamic> json) {
    final size = asNullableString(json['size']);
    final color = asNullableString(json['color_ar']);
    final labels = <String>[
      if (size?.trim().isNotEmpty == true) size!,
      if (color?.trim().isNotEmpty == true) color!,
    ];
    return InventoryAuditEntry(
      id: asString(json['id']),
      type: asNullableString(json['type'] ?? json['adjustment_type']),
      reference: asNullableString(json['reference']),
      quantity: json['quantity'] == null && json['quantity_difference'] == null
          ? null
          : asDouble(json['quantity'] ?? json['quantity_difference']),
      stockBefore:
          json['stock_before'] == null ? null : asDouble(json['stock_before']),
      stockAfter:
          json['stock_after'] == null ? null : asDouble(json['stock_after']),
      valueDifference: json['value_difference'] == null
          ? null
          : asDouble(json['value_difference']),
      reason: asNullableString(json['reason']),
      notes: asNullableString(json['notes'] ?? json['note']),
      variantLabel: labels.isEmpty ? null : labels.join(' / '),
      createdBy: asNullableString(json['created_by_name']),
      createdAt: asNullableString(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'reference': reference,
        'quantity': quantity,
        'stock_before': stockBefore,
        'stock_after': stockAfter,
        'value_difference': valueDifference,
        'reason': reason,
        'notes': notes,
        'variant_label': variantLabel,
        'created_by_name': createdBy,
        'created_at': createdAt,
      };
}

class InventoryIdentitySummary {
  final String? sizeColorId;
  final String sizeLabel;
  final String colorLabel;
  final double quantityOnHand;
  final double missingCostQuantity;
  final String currency;
  final double? inventoryValue;
  final double? averageUnitCost;
  final double? nextFifoUnitCost;
  final bool coverageComplete;

  const InventoryIdentitySummary({
    this.sizeColorId,
    required this.sizeLabel,
    required this.colorLabel,
    required this.quantityOnHand,
    required this.missingCostQuantity,
    required this.currency,
    this.inventoryValue,
    this.averageUnitCost,
    this.nextFifoUnitCost,
    required this.coverageComplete,
  });

  factory InventoryIdentitySummary.fromJson(Map<String, dynamic> json) =>
      InventoryIdentitySummary(
        sizeColorId: asNullableString(json['size_color_id']),
        sizeLabel: asString(json['size_label'], '—'),
        colorLabel: asString(json['color_label'], '—'),
        quantityOnHand: asDouble(json['quantity_on_hand']),
        missingCostQuantity: asDouble(json['missing_cost_quantity']),
        currency: asString(json['currency'], 'شيكل'),
        inventoryValue: json['inventory_value'] == null
            ? null
            : asDouble(json['inventory_value']),
        averageUnitCost: json['average_inventory_unit_cost'] == null
            ? null
            : asDouble(json['average_inventory_unit_cost']),
        nextFifoUnitCost: json['next_fifo_unit_cost'] == null
            ? null
            : asDouble(json['next_fifo_unit_cost']),
        coverageComplete: json['cost_coverage_complete'] == true,
      );

  Map<String, dynamic> toJson() => {
        'size_color_id': sizeColorId,
        'size_label': sizeLabel,
        'color_label': colorLabel,
        'quantity_on_hand': quantityOnHand,
        'missing_cost_quantity': missingCostQuantity,
        'currency': currency,
        'inventory_value': inventoryValue,
        'average_inventory_unit_cost': averageUnitCost,
        'next_fifo_unit_cost': nextFifoUnitCost,
        'cost_coverage_complete': coverageComplete,
      };
}

class InventoryCostLayerDetails {
  final String id;
  final String sourceType;
  final double remainingQuantity;
  final double unitCost;
  final double remainingValue;
  final String currency;
  final String? sizeColorId;
  final String? effectiveAt;

  const InventoryCostLayerDetails({
    required this.id,
    required this.sourceType,
    required this.remainingQuantity,
    required this.unitCost,
    required this.remainingValue,
    required this.currency,
    this.sizeColorId,
    this.effectiveAt,
  });

  factory InventoryCostLayerDetails.fromJson(Map<String, dynamic> json) =>
      InventoryCostLayerDetails(
        id: asString(json['id']),
        sourceType: asString(json['source_type']),
        remainingQuantity: asDouble(json['remaining_quantity']),
        unitCost: asDouble(json['unit_cost']),
        remainingValue: asDouble(json['remaining_value']),
        currency: asString(json['currency'], 'NIS'),
        sizeColorId: asNullableString(json['size_color_id']),
        effectiveAt: asNullableString(json['effective_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'source_type': sourceType,
        'remaining_quantity': remainingQuantity,
        'unit_cost': unitCost,
        'remaining_value': remainingValue,
        'currency': currency,
        'size_color_id': sizeColorId,
        'effective_at': effectiveAt,
      };
}

class ProductMediaItem {
  final String id;
  final String? url;

  ProductMediaItem({required this.id, this.url});
}

class ProductSubCategory {
  String? subCategoryId;
  String? subCategoryName;
  String? mainCategoryId;
  String? mainCategoryName;

  ProductSubCategory({
    this.subCategoryId,
    this.subCategoryName,
    this.mainCategoryId,
    this.mainCategoryName,
  });

  factory ProductSubCategory.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return ProductSubCategory(
      subCategoryId: asNullableString(j['sub_category_id']),
      subCategoryName: asNullableString(j['sub_category_name']),
      mainCategoryId: asNullableString(j['main_category_id']),
      mainCategoryName: asNullableString(j['main_category_name']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sub_category_id': subCategoryId,
      'sub_category_name': subCategoryName,
      'main_category_id': mainCategoryId,
      'main_category_name': mainCategoryName,
    };
  }
}

class PurchasePrice {
  String? sellerId;
  String? price;

  PurchasePrice({this.sellerId, this.price});

  factory PurchasePrice.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return PurchasePrice(
      sellerId: asString(j['seller_id'], '0'),
      price: asString(j['price'], '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seller_id': sellerId,
      'price': price,
    };
  }
}

class Size {
  String? id;
  String? size;
  String? itemId;
  List<ColorSize>? colorSizes;

  Size({this.id, this.size, this.itemId, this.colorSizes});

  factory Size.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return Size(
      id: asNullableString(j['id']),
      size: asNullableString(j['size']),
      itemId: asNullableString(j['itemId']),
      colorSizes: j['color_sizes'] == null
          ? null
          : mapList(j['color_sizes'], (m) => ColorSize.fromJson(m)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'size': size,
      'itemId': itemId,
      'color_sizes': colorSizes?.map((v) => v.toJson()).toList(),
    };
  }
}

class ColorSize {
  String? id;
  String? colorAr;
  String? colorEn;
  String? colorAbbr;
  String? normailPrice;
  String? wholesalePrice;
  String? discount;
  String? stock;
  String? sizeId;
  String? imageUrl;

  ColorSize({
    this.id,
    this.colorAr,
    this.colorEn,
    this.colorAbbr,
    this.normailPrice,
    this.wholesalePrice,
    this.discount,
    this.stock,
    this.sizeId,
    this.imageUrl,
  });

  factory ColorSize.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return ColorSize(
      id: asString(j['id'], '0'),
      colorAr: asString(j['colorAr'], '0'),
      colorEn: asNullableString(j['colorEn']),
      colorAbbr: asNullableString(j['colorAbbr']),
      normailPrice: asString(j['normailPrice'], '0'),
      wholesalePrice: asString(j['wholesalePrice'], '0'),
      discount: asString(j['discount'], '0'),
      stock: asString(j['stock'], '0'),
      sizeId: asString(j['sizeId'], '0'),
      imageUrl: asNullableString(j['image_url'] ?? j['imageUrl']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'colorAr': colorAr,
      'colorEn': colorEn,
      'colorAbbr': colorAbbr,
      'normailPrice': normailPrice,
      'wholesalePrice': wholesalePrice,
      'discount': discount,
      'stock': stock,
      'sizeId': sizeId,
      'image_url': imageUrl,
    };
  }
}

// class NormalImage {
//   String? id;
//   String? itemId;
//   String? imageUrl;

//   NormalImage({this.id, this.itemId, this.imageUrl});

//   factory NormalImage.fromJson(Map<String, dynamic> json) {
//     return NormalImage(
//       id: json['id']?.toString(),
//       itemId: json['itemId']?.toString(),
//       imageUrl: ShowNetImage.getPhoto(json['imageUrl']),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'itemId': itemId,
//       'imageUrl': imageUrl,
//     };
//   }
// }

// class ViewImage {
//   String? id;
//   String? itemId;
//   String? imageUrl;

//   ViewImage({this.id, this.itemId, this.imageUrl});

//   factory ViewImage.fromJson(Map<String, dynamic> json) {
//     return ViewImage(
//       id: json['id']?.toString(),
//       itemId: json['itemId']?.toString(),
//       imageUrl: ShowNetImage.getPhoto(json['imageUrl']),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'itemId': itemId,
//       'imageUrl': imageUrl,
//     };
//   }
// }

// class Image3D {
//   String? id;
//   String? itemId;
//   String? imageUrl;

//   Image3D({this.id, this.itemId, this.imageUrl});

//   factory Image3D.fromJson(Map<String, dynamic> json) {
//     return Image3D(
//       id: json['id']?.toString(),
//       itemId: json['itemId']?.toString(),
//       imageUrl: ShowNetImage.getPhoto(json['imageUrl']),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'itemId': itemId,
//       'imageUrl': imageUrl,
//     };
//   }
// }
