import 'package:doctorbike/core/helpers/json_safe_parser.dart';

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
      id: asInt(json['id']),
      product: asString(json['product']),
      productImage: asString(json['product_image']),
      cost: asString(json['cost'], '0'),
      quantity: asString(json['quantity'], '0'),
      totalCost: asString(json['total_cost'], '0'),
      discount: asString(json['discount'], '0'),
      subProducts: mapList(
        json['sub_products'],
        (Map<String, dynamic> m) => SubProductModel.fromJson(m),
      ),
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
      id: asInt(json['id']),
      productName: asString(json['product_name']),
      productImage: asString(json['product_image']),
      cost: asString(json['cost'], '0'),
      quantity: asString(json['quantity'], '0'),
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
