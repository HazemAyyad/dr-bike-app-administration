class InstantSalesModel {
  final int id;
  final String product;
  final String cost;
  final String totalCost;
  final String quantity;
  final DateTime date;
  final String notes;
  final List<SubProductsModel> subProducts;

  const InstantSalesModel({
    required this.id,
    required this.product,
    required this.cost,
    required this.totalCost,
    required this.quantity,
    required this.date,
    required this.notes,
    this.subProducts = const [],
  });

  factory InstantSalesModel.fromJson(Map<String, dynamic> json) {
    return InstantSalesModel(
      id: json['id'] ?? 0,
      product: json['product'] ?? '',
      cost: json['cost'] ?? '0',
      totalCost: json['total_cost'] ?? '0',
      quantity: json['quantity'] ?? '0',
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      notes: json['notes'] ?? '',
      subProducts: (json['sub_products'] as List<dynamic>?)
              ?.map((e) => SubProductsModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product,
      'cost': cost,
      'total_cost': totalCost,
      'quantity': quantity,
      'date': date,
      'notes': notes,
      'sub_products': subProducts.map((e) => e.toJson()).toList(),
    };
  }
}

class SubProductsModel {
  final int id;
  final String productName;
  final String cost;
  final String quantity;

  const SubProductsModel({
    required this.id,
    required this.productName,
    required this.cost,
    required this.quantity,
  });

  factory SubProductsModel.fromJson(Map<String, dynamic> json) {
    return SubProductsModel(
      id: json['id'] ?? 0,
      productName: json['product_name'] ?? '',
      cost: json['cost'] ?? '0',
      quantity: json['quantity'] ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_name': productName,
      'cost': cost,
      'quantity': quantity,
    };
  }
}
