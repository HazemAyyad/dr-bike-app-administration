class FollowupDetailsModel {
  final int id;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCanceled;
  final Customer? customer;
  final Seller? seller;
  final Product? product;

  FollowupDetailsModel({
    required this.id,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.isCanceled,
    this.customer,
    this.seller,
    this.product,
  });

  factory FollowupDetailsModel.fromJson(Map<String, dynamic> json) {
    return FollowupDetailsModel(
      id: json['id'] ?? 0,
      status: json['status'] ?? '',
      notes: json['notes'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isCanceled: json['is_canceled'] == "1",
      customer:
          json['customer'] != null ? Customer.fromJson(json['customer']) : null,
      seller: json['seller'] != null ? Seller.fromJson(json['seller']) : null,
      product:
          json['product'] != null ? Product.fromJson(json['product']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "status": status,
      "notes": notes,
      "created_at": createdAt.toIso8601String(),
      "updated_at": updatedAt.toIso8601String(),
      "is_canceled": isCanceled ? "1" : "0",
      "customer": customer?.toJson(),
      "seller": seller?.toJson(),
      "product": product?.toJson(),
    };
  }
}

class Customer {
  final int id;
  final String name;

  Customer({
    required this.id,
    required this.name,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
    };
  }
}

class Seller {
  final int id;
  final String name;

  Seller({
    required this.id,
    required this.name,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: json['id'] as int,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
    };
  }
}

class Product {
  final int id;
  final String nameAr;

  Product({
    required this.id,
    required this.nameAr,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '0',
      nameAr: json['nameAr'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nameAr": nameAr,
    };
  }
}
