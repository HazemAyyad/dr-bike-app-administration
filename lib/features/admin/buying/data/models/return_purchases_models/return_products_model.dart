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
    return ReturnProduct(
      id: json['id'] ?? 0,
      sellerId: json['seller_id'] ?? "",
      total: json['total'] ?? "0.0",
      status: json['status'] ?? "",
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      seller: Seller.fromJson(json['seller']),
      items: (json['items'] as List<dynamic>)
          .map((e) => ReturnItem.fromJson(e))
          .toList(),
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
    return Seller(
      id: json['id'] ?? 0,
      name: json['name'] ?? "",
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

  ReturnItem({
    required this.id,
    required this.returnId,
    required this.productId,
    required this.price,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReturnItem.fromJson(Map<String, dynamic> json) {
    return ReturnItem(
      id: json['id'] ?? 0,
      returnId: json['return_id'] ?? "",
      productId: json['product_id'] ?? "",
      price: json['price'] ?? "",
      quantity: json['quantity'] ?? "",
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
    };
  }
}
