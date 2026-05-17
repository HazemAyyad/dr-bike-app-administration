import '../../../../../core/helpers/json_safe_parser.dart';

class OfferPackageItemModel {
  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final double stock;
  final double unitPrice;
  final String productImage;

  OfferPackageItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.stock,
    required this.unitPrice,
    required this.productImage,
  });

  factory OfferPackageItemModel.fromJson(Map<String, dynamic> json) {
    return OfferPackageItemModel(
      id: asInt(json['id']),
      productId: asInt(json['product_id']),
      productName: asString(json['product_name'], '-'),
      quantity: asInt(json['quantity'], 1),
      stock: asDouble(json['stock']),
      unitPrice: asDouble(json['unit_price'] ?? json['product_normail_price']),
      productImage: asString(json['product_image'], 'no image'),
    );
  }
}

class OfferPackageModel {
  final int id;
  final String name;
  final double price;
  final int packageQuantity;
  final double effectivePrice;
  final String image;
  final bool isActive;
  final int availableQuantity;
  final int packagesSold;
  final int salesCount;
  final int remainingQuantity;
  final bool needsAdjustment;
  final List<OfferPackageItemModel> items;

  final int maxSellableQuantity;

  OfferPackageModel({
    required this.id,
    required this.name,
    required this.price,
    required this.packageQuantity,
    required this.effectivePrice,
    required this.image,
    required this.isActive,
    required this.availableQuantity,
    required this.packagesSold,
    required this.salesCount,
    required this.remainingQuantity,
    required this.maxSellableQuantity,
    required this.needsAdjustment,
    required this.items,
  });

  factory OfferPackageModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <OfferPackageItemModel>[];
    if (rawItems is List) {
      for (final row in rawItems) {
        if (row is Map<String, dynamic>) {
          items.add(OfferPackageItemModel.fromJson(row));
        } else if (row is Map) {
          items.add(OfferPackageItemModel.fromJson(Map<String, dynamic>.from(row)));
        }
      }
    }

    return OfferPackageModel(
      id: asInt(json['id']),
      name: asString(json['name'], '-'),
      price: asDouble(json['price']),
      packageQuantity: asInt(json['package_quantity'], 1),
      effectivePrice: asDouble(json['effective_price']),
      image: asString(json['image'], 'no image'),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      availableQuantity: asInt(json['available_quantity']),
      packagesSold: asInt(json['packages_sold']),
      salesCount: asInt(json['sales_count']),
      remainingQuantity: asInt(
        json['remaining_quantity'],
        asInt(json['package_quantity']),
      ),
      maxSellableQuantity: _parseMaxSellable(json),
      needsAdjustment: json['needs_adjustment'] == true || json['needs_adjustment'] == 1,
      items: items,
    );
  }

  static int _parseMaxSellable(Map<String, dynamic> json) {
    final fromApi = asInt(json['max_sellable_quantity']);
    if (fromApi > 0) {
      return fromApi;
    }
    final available = asInt(json['available_quantity']);
    final remaining = asInt(
      json['remaining_quantity'],
      asInt(json['package_quantity']),
    );
    if (available <= 0 || remaining <= 0) {
      return 0;
    }
    return available < remaining ? available : remaining;
  }
}
