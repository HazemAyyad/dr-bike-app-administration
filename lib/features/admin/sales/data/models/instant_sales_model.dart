import 'package:doctorbike/core/helpers/json_safe_parser.dart';

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
      id: asInt(json['id']),
      product: asString(json['product']),
      cost: asString(json['cost'], '0'),
      totalCost: asString(json['total_cost'], '0'),
      quantity: asString(json['quantity'], '0'),
      date: parseApiDateTime(json['date']),
      notes: asString(json['notes']),
      subProducts: mapList(
        json['sub_products'],
        (Map<String, dynamic> m) => SubProductsModel.fromJson(m),
      ),
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
      id: asInt(json['id']),
      productName: asString(json['product_name']),
      cost: asString(json['cost'], '0'),
      quantity: asString(json['quantity'], '0'),
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
