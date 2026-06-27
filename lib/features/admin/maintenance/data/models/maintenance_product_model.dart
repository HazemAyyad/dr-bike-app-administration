import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class MaintenanceProductModel {
  final int? id;
  final int productId;
  final String productName;
  final int? sizeId;
  final int? sizeColorId;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  const MaintenanceProductModel({
    this.id,
    required this.productId,
    this.productName = '',
    this.sizeId,
    this.sizeColorId,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory MaintenanceProductModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return MaintenanceProductModel(
      id: j['id'] == null ? null : asInt(j['id']),
      productId: asInt(j['product_id']),
      productName: asString(j['product_name']),
      sizeId: j['size_id'] == null ? null : asInt(j['size_id']),
      sizeColorId:
          j['size_color_id'] == null ? null : asInt(j['size_color_id']),
      quantity: asInt(j['quantity'], 1),
      unitPrice: asDouble(j['unit_price']),
      lineTotal: asDouble(j['line_total']),
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'product_id': productId,
      if (sizeId != null) 'size_id': sizeId,
      if (sizeColorId != null) 'size_color_id': sizeColorId,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }

  MaintenanceProductModel copyWith({
    int? quantity,
    double? unitPrice,
    String? productName,
  }) {
    final qty = quantity ?? this.quantity;
    final price = unitPrice ?? this.unitPrice;
    return MaintenanceProductModel(
      id: id,
      productId: productId,
      productName: productName ?? this.productName,
      sizeId: sizeId,
      sizeColorId: sizeColorId,
      quantity: qty,
      unitPrice: price,
      lineTotal: qty * price,
    );
  }
}

class MaintenanceBillingModel {
  final List<MaintenanceProductModel> items;
  final double partsTotal;
  final double laborCost;
  final double discount;
  final double invoiceTotal;
  final double paidAmount;
  final int? instantSaleId;
  final String? serialNumber;

  const MaintenanceBillingModel({
    this.items = const [],
    this.partsTotal = 0,
    this.laborCost = 0,
    this.discount = 0,
    this.invoiceTotal = 0,
    this.paidAmount = 0,
    this.instantSaleId,
    this.serialNumber,
  });

  factory MaintenanceBillingModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MaintenanceBillingModel();
    final j = Map<String, dynamic>.from(json);
    final rawItems = j['items'];
    final items = rawItems is List
        ? rawItems
            .map((e) => MaintenanceProductModel.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList()
        : <MaintenanceProductModel>[];

    return MaintenanceBillingModel(
      items: items,
      partsTotal: asDouble(j['parts_total']),
      laborCost: asDouble(j['labor_cost']),
      discount: asDouble(j['discount']),
      invoiceTotal: asDouble(j['invoice_total']),
      paidAmount: asDouble(j['paid_amount']),
      instantSaleId:
          j['instant_sale_id'] == null ? null : asInt(j['instant_sale_id']),
      serialNumber: asNullableString(j['serial_number']),
    );
  }
}
