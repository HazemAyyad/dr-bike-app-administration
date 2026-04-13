import 'package:doctorbike/core/helpers/json_safe_parser.dart';

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
    final j = Map<String, dynamic>.from(json);
    return FollowupDetailsModel(
      id: asInt(j['id']),
      status: asString(j['status']),
      notes: asNullableString(j['notes']),
      createdAt: parseApiDateTime(j['created_at']),
      updatedAt: parseApiDateTime(j['updated_at']),
      isCanceled: asBool(j['is_canceled']),
      customer: j['customer'] != null
          ? Customer.fromJson(asMap(j['customer']))
          : null,
      seller:
          j['seller'] != null ? Seller.fromJson(asMap(j['seller'])) : null,
      product:
          j['product'] != null ? Product.fromJson(asMap(j['product'])) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_canceled': isCanceled ? '1' : '0',
      'customer': customer?.toJson(),
      'seller': seller?.toJson(),
      'product': product?.toJson(),
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
    final j = Map<String, dynamic>.from(json);
    return Customer(
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

class Seller {
  final int id;
  final String name;

  Seller({
    required this.id,
    required this.name,
  });

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

class Product {
  final int id;
  final String nameAr;

  Product({
    required this.id,
    required this.nameAr,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return Product(
      id: asInt(j['id']),
      nameAr: asString(j['nameAr']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
    };
  }
}
