import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class QuickEditProductModel {
  final String productId;
  final String productCode;
  final String productImage;
  final String nameAr;
  final String nameEng;
  final String nameAbree;
  final String descriptionAr;
  final String descriptionEng;
  final String descriptionAbree;
  final String categoryName;
  final String subCategories;
  final String storeSectionName;
  final String normailPrice;
  final String wholesalePrice;
  final String costPrice;
  final String price;
  final String minSalePrice;
  final String stock;
  final String minStock;
  final String discount;
  final bool isShow;
  final bool isNewItem;
  final bool isMoreSales;
  final bool isSoldWithPaper;
  final String rate;
  final String manufactureYear;
  final String model;
  final String rotationDate;
  final String projectName;
  final String lastEditMarkedAt;
  final bool markedToday;

  QuickEditProductModel({
    required this.productId,
    required this.productCode,
    required this.productImage,
    required this.nameAr,
    required this.nameEng,
    required this.nameAbree,
    required this.descriptionAr,
    required this.descriptionEng,
    required this.descriptionAbree,
    required this.categoryName,
    required this.subCategories,
    required this.storeSectionName,
    required this.normailPrice,
    required this.wholesalePrice,
    required this.costPrice,
    required this.price,
    required this.minSalePrice,
    required this.stock,
    required this.minStock,
    required this.discount,
    required this.isShow,
    required this.isNewItem,
    required this.isMoreSales,
    required this.isSoldWithPaper,
    required this.rate,
    required this.manufactureYear,
    required this.model,
    required this.rotationDate,
    required this.projectName,
    required this.lastEditMarkedAt,
    required this.markedToday,
  });

  factory QuickEditProductModel.fromJson(Map<String, dynamic> json) {
    return QuickEditProductModel(
      productId: asString(json['product_id']),
      productCode: asString(json['product_code']),
      productImage: asString(json['product_image']),
      nameAr: asString(json['nameAr']),
      nameEng: asString(json['nameEng']),
      nameAbree: asString(json['nameAbree']),
      descriptionAr: asString(json['descriptionAr']),
      descriptionEng: asString(json['descriptionEng']),
      descriptionAbree: asString(json['descriptionAbree']),
      categoryName: asString(json['category_name']),
      subCategories: asString(json['sub_categories']),
      storeSectionName: asString(json['store_section_name']),
      normailPrice: asString(json['normailPrice']),
      wholesalePrice: asString(json['wholesalePrice']),
      costPrice: asString(json['cost_price']),
      price: asString(json['price']),
      minSalePrice: asString(json['min_sale_price']),
      stock: asString(json['stock']),
      minStock: asString(json['min_stock']),
      discount: asString(json['discount']),
      isShow: json['isShow'] == true,
      isNewItem: json['isNewItem'] == true,
      isMoreSales: json['isMoreSales'] == true,
      isSoldWithPaper: json['is_sold_with_paper'] == true,
      rate: asString(json['rate']),
      manufactureYear: asString(json['manufactureYear']),
      model: asString(json['model']),
      rotationDate: asString(json['rotation_date']),
      projectName: asString(json['project_name']),
      lastEditMarkedAt: asString(json['last_edit_marked_at']),
      markedToday: json['marked_today'] == true,
    );
  }

  Map<String, dynamic> toUpdateJson({bool markToday = false}) {
    return {
      'product_id': productId,
      'product_code': productCode,
      'nameAr': nameAr,
      'nameEng': nameEng,
      'nameAbree': nameAbree,
      'descriptionAr': descriptionAr,
      'descriptionEng': descriptionEng,
      'descriptionAbree': descriptionAbree,
      'normailPrice': normailPrice,
      'wholesalePrice': wholesalePrice,
      'cost_price': costPrice,
      'price': price,
      'min_sale_price': minSalePrice,
      'stock': stock,
      'min_stock': minStock,
      'discount': discount,
      'isShow': isShow,
      'isNewItem': isNewItem,
      'isMoreSales': isMoreSales,
      'is_sold_with_paper': isSoldWithPaper,
      'rate': rate,
      'manufactureYear': manufactureYear,
      'model': model,
      'rotation_date': rotationDate,
      'mark_today': markToday,
    };
  }
}
