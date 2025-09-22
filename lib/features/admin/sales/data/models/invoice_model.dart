class InvoiceModel {
  final int id;
  final String product;
  final String productImage;
  final String cost;
  final String quantity;
  final String totalCost;
  final String discount;
  final List<SubProductModel> subProducts;

  InvoiceModel({
    required this.id,
    required this.product,
    required this.productImage,
    required this.cost,
    required this.quantity,
    required this.totalCost,
    required this.discount,
    required this.subProducts,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] ?? 0,
      product: json['product'] ?? '',
      productImage: json['product_image'],
      cost: json['cost'] ?? '0',
      quantity: json['quantity'] ?? '0',
      totalCost: json['total_cost'] ?? '0',
      discount: json['discount'] ?? '0',
      subProducts: (json['sub_products'] as List<dynamic>?)
              ?.map((e) => SubProductModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product,
      'product_image': productImage,
      'cost': cost,
      'quantity': quantity,
      'total_cost': totalCost,
      'discount': discount,
      'sub_products': subProducts.map((e) => e.toJson()).toList(),
    };
  }
}

class SubProductModel {
  final int id;
  final String productName;
  final String productImage;
  final String cost;
  final String quantity;

  SubProductModel({
    required this.id,
    required this.productName,
    required this.productImage,
    required this.cost,
    required this.quantity,
  });

  factory SubProductModel.fromJson(Map<String, dynamic> json) {
    return SubProductModel(
      id: json['id'] ?? 0,
      productName: json['product_name'] ?? '',
      productImage: json['product_image'],
      cost: json['cost'] ?? '0',
      quantity: json['quantity'] ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_name': productName,
      'product_image': productImage,
      'cost': cost,
      'quantity': quantity,
    };
  }
}
