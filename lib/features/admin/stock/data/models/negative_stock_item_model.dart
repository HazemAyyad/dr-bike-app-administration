import '../../../../../core/helpers/json_safe_parser.dart';

class NegativeStockCauseModel {
  const NegativeStockCauseModel({
    required this.userName,
    required this.quantity,
    required this.stockBefore,
    required this.stockAfter,
    this.invoiceNumber,
    this.createdAt,
  });

  final String? userName;
  final int quantity;
  final int stockBefore;
  final int stockAfter;
  final String? invoiceNumber;
  final String? createdAt;

  factory NegativeStockCauseModel.fromJson(Map<String, dynamic> json) =>
      NegativeStockCauseModel(
        userName: asNullableString(json['user_name']),
        quantity: asInt(json['quantity']),
        stockBefore: asInt(json['stock_before']),
        stockAfter: asInt(json['stock_after']),
        invoiceNumber: asNullableString(json['invoice_number']),
        createdAt: asNullableString(json['created_at']),
      );
}

class NegativeStockItemModel {
  const NegativeStockItemModel({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.image,
    required this.stock,
    required this.missingQuantity,
    required this.pendingCostQuantity,
    required this.causes,
    this.sizeId,
    this.sizeColorId,
    this.variantLabel,
    this.lastCreatedByName,
    this.lastInvoiceNumber,
    this.lastNegativeAt,
  });

  final String productId;
  final String productName;
  final String productCode;
  final String image;
  final int stock;
  final int missingQuantity;
  final double pendingCostQuantity;
  final String? sizeId;
  final String? sizeColorId;
  final String? variantLabel;
  final String? lastCreatedByName;
  final String? lastInvoiceNumber;
  final String? lastNegativeAt;
  final List<NegativeStockCauseModel> causes;

  String get identityKey => '$productId:${sizeColorId ?? 'main'}';

  factory NegativeStockItemModel.fromJson(Map<String, dynamic> json) {
    final rawCauses = json['caused_by'];
    return NegativeStockItemModel(
      productId: asString(json['product_id']),
      productName: asString(json['product_name'], 'منتج'),
      productCode: asString(json['product_code']),
      image: asString(json['product_image']),
      stock: asInt(json['stock']),
      missingQuantity: asInt(json['missing_quantity']),
      pendingCostQuantity: asDouble(json['pending_cost_quantity']),
      sizeId: asNullableString(json['size_id']),
      sizeColorId: asNullableString(json['size_color_id']),
      variantLabel: asNullableString(json['variant_label']),
      lastCreatedByName: asNullableString(json['last_created_by_name']),
      lastInvoiceNumber: asNullableString(json['last_invoice_number']),
      lastNegativeAt: asNullableString(json['last_negative_at']),
      causes: rawCauses is List
          ? rawCauses
              .whereType<Map>()
              .map((row) => NegativeStockCauseModel.fromJson(
                    Map<String, dynamic>.from(row),
                  ))
              .toList(growable: false)
          : const [],
    );
  }
}

class NegativeStockResultModel {
  const NegativeStockResultModel({
    required this.items,
    required this.identitiesCount,
    required this.missingQuantity,
    required this.pendingCostQuantity,
  });

  final List<NegativeStockItemModel> items;
  final int identitiesCount;
  final int missingQuantity;
  final double pendingCostQuantity;
}
