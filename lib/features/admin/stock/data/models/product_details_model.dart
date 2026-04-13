import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class ProductDetailsModel {
  String id;
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
  List<ProductSubCategory>? productSubCategories;
  List<PurchasePrice>? purchasePrices;
  List<Size>? sizes;
  List<dynamic>? wholesales;
  List<String>? normalImages;
  List<String>? viewImages;
  List<String>? image3d;
  dynamic purchase;

  ProductDetailsModel({
    required this.id,
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
    this.productSubCategories,
    this.purchasePrices,
    this.sizes,
    this.wholesales,
    this.normalImages,
    this.viewImages,
    this.image3d,
    this.purchase,
  });

  factory ProductDetailsModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return ProductDetailsModel(
      id: asString(j['id']),
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
      videoUrl: j['videoUrl'],
      normailPrice: asNullableString(j['normailPrice']),
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
      dateUpdate: j['dateUpdate'] == null ? null : parseApiDateTime(j['dateUpdate']),
      minStock: j['min_stock'],
      rotationDate: j['rotation_date'],
      minSalePrice: j['min_sale_price'],
      isSoldWithPaper: j['is_sold_with_paper'],
      projectId: j['project_id'],
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
      purchase: j['purchase'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
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

    return data;
  }
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
  String? normailPrice;
  String? wholesalePrice;
  String? discount;
  String? stock;
  String? sizeId;

  ColorSize({
    this.id,
    this.colorAr,
    this.normailPrice,
    this.wholesalePrice,
    this.discount,
    this.stock,
    this.sizeId,
  });

  factory ColorSize.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return ColorSize(
      id: asString(j['id'], '0'),
      colorAr: asString(j['colorAr'], '0'),
      normailPrice: asString(j['normailPrice'], '0'),
      wholesalePrice: asString(j['wholesalePrice'], '0'),
      discount: asString(j['discount'], '0'),
      stock: asString(j['stock'], '0'),
      sizeId: asString(j['sizeId'], '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'colorAr': colorAr,
      'normailPrice': normailPrice,
      'wholesalePrice': wholesalePrice,
      'discount': discount,
      'stock': stock,
      'sizeId': sizeId,
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
