import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class ReturnProduct {
  final int id;
  final String sellerId;
  final String total;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Seller seller;
  final List<ReturnItem> items;

  ReturnProduct({
    required this.id,
    required this.sellerId,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.seller,
    required this.items,
  });

  factory ReturnProduct.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return ReturnProduct(
      id: asInt(j['id']),
      sellerId: asString(j['seller_id']),
      total: asString(j['total'], '0.0'),
      status: asString(j['status']),
      createdAt: parseApiDateTime(j['created_at']),
      updatedAt: parseApiDateTime(j['updated_at']),
      seller: Seller.fromJson(asMap(j['seller'])),
      items: mapList(
        j['items'],
        (Map<String, dynamic> m) => ReturnItem.fromJson(m),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'total': total,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'seller': seller.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class Seller {
  final int id;
  final String name;

  Seller({required this.id, required this.name});

  factory Seller.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return Seller(
      id: asInt(j['id']),
      name: asString(j['name']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class ReturnItem {
  final int id;
  final String returnId;
  final String productId;
  final String price;
  final String quantity;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String productName;

  ReturnItem({
    required this.id,
    required this.returnId,
    required this.productId,
    required this.price,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
    required this.productName,
  });

  factory ReturnItem.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return ReturnItem(
      id: asInt(j['id']),
      returnId: asString(j['return_id']),
      productId: asString(j['product_id']),
      price: asString(j['price']),
      quantity: asString(j['quantity']),
      createdAt: parseApiDateTime(j['created_at']),
      updatedAt: parseApiDateTime(j['updated_at']),
      productName: asString(j['product_name']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'return_id': returnId,
      'product_id': productId,
      'price': price,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'product_name': productName,
    };
  }
}
