import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class InstantSalesModel {
  final int id;
  final String product;
  final String cost;
  final String totalCost;
  final String quantity;
  final DateTime date;
  final DateTime? createdAt;
  final String notes;
  final List<SubProductsModel> subProducts;
  final String? buyerType;
  final String? buyerTypeLabelAr;
  final int? buyerId;
  final String? buyerName;
  final String? buyerPhone;
  final String? projectName;
  final String? status;
  final String? paymentBoxName;
  final String? paymentBoxValue;
  final bool isPackageSale;
  final int? offerPackageId;
  final String? packageName;
  final String saleType;

  const InstantSalesModel({
    required this.id,
    required this.product,
    required this.cost,
    required this.totalCost,
    required this.quantity,
    required this.date,
    this.createdAt,
    required this.notes,
    this.subProducts = const [],
    this.buyerType,
    this.buyerTypeLabelAr,
    this.buyerId,
    this.buyerName,
    this.buyerPhone,
    this.projectName,
    this.status,
    this.paymentBoxName,
    this.paymentBoxValue,
    this.isPackageSale = false,
    this.offerPackageId,
    this.packageName,
    this.saleType = 'product',
  });

  bool get isCancelled => status == 'cancelled';

  String get displayTitle =>
      isPackageSale ? (packageName ?? product) : product;

  String get displayBuyerLine {
    final name = buyerName?.trim();
    if (name != null && name.isNotEmpty && name != '-') {
      final type = buyerTypeLabelAr?.trim();
      if (type != null && type.isNotEmpty) {
        return '$type: $name';
      }
      return name;
    }
    final project = projectName?.trim();
    if (project != null && project.isNotEmpty) {
      return project;
    }
    return '';
  }

  factory InstantSalesModel.fromJson(Map<String, dynamic> json) {
    return InstantSalesModel(
      id: asInt(json['id']),
      product: asString(json['product']),
      cost: asString(json['cost'], '0'),
      totalCost: asString(json['total_cost'], '0'),
      quantity: asString(json['quantity'], '0'),
      date: parseApiDateTime(json['date']),
      createdAt: json['created_at'] != null
          ? parseApiDateTime(json['created_at'])
          : null,
      notes: asString(json['notes']),
      subProducts: mapList(
        json['sub_products'],
        (Map<String, dynamic> m) => SubProductsModel.fromJson(m),
      ),
      buyerType: asNullableString(json['buyer_type']),
      buyerTypeLabelAr: asNullableString(json['buyer_type_label_ar']),
      buyerId: json['buyer_id'] == null
          ? null
          : int.tryParse('${json['buyer_id']}'),
      buyerName: asNullableString(json['buyer_name']),
      buyerPhone: asNullableString(json['buyer_phone']),
      projectName: asNullableString(json['project_name']),
      status: asNullableString(json['status']),
      paymentBoxName: asNullableString(json['payment_box_name']),
      paymentBoxValue: asNullableString(json['payment_box_value']?.toString()),
      isPackageSale: json['is_package_sale'] == true ||
          json['is_package_sale'] == 1 ||
          json['sale_type'] == 'package',
      offerPackageId: json['offer_package_id'] == null
          ? null
          : int.tryParse('${json['offer_package_id']}'),
      packageName: asNullableString(json['package_name']),
      saleType: asString(json['sale_type'], 'product'),
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
      'created_at': createdAt,
      'notes': notes,
      'sub_products': subProducts.map((e) => e.toJson()).toList(),
      'buyer_type': buyerType,
      'buyer_type_label_ar': buyerTypeLabelAr,
      'buyer_id': buyerId,
      'buyer_name': buyerName,
      'buyer_phone': buyerPhone,
      'project_name': projectName,
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
