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
  final int? createdBy;
  final String? createdByName;
  final int? updatedBy;
  final String? updatedByName;

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
    this.createdBy,
    this.createdByName,
    this.updatedBy,
    this.updatedByName,
  });

  bool get isCancelled => status == 'cancelled';

  String get displayTitle =>
      isPackageSale ? (packageName ?? product) : product;

  String get invoiceNumber => '#$id';

  /// Total piece count (package lines sum sub-qty; else main + extras).
  int get piecesCount {
    if (isPackageSale && subProducts.isNotEmpty) {
      return subProducts.fold<int>(
        0,
        (sum, p) => sum + (int.tryParse(p.quantity) ?? 0),
      );
    }
    final mainQty = int.tryParse(quantity) ?? 0;
    if (subProducts.isEmpty) return mainQty;
    final subTotal = subProducts.fold<int>(
      0,
      (sum, p) => sum + (int.tryParse(p.quantity) ?? 0),
    );
    return subTotal > 0 ? mainQty + subTotal : mainQty;
  }

  bool get isCustomerBuyer =>
      buyerType == 'customer' || buyerType == 'customers';

  bool get isSellerBuyer => buyerType == 'seller' || buyerType == 'sellers';

  String get partnerName {
    final name = buyerName?.trim();
    if (name != null && name.isNotEmpty && name != '-') return name;
    final project = projectName?.trim();
    if (project != null && project.isNotEmpty) return project;
    return '—';
  }

  /// Lines shown in the invoice detail modal.
  List<InstantSaleLineItem> get lineItems {
    final lines = <InstantSaleLineItem>[];
    if (isPackageSale) {
      lines.add(InstantSaleLineItem(
        name: displayTitle,
        quantity: quantity,
        unitCost: cost,
        isPackageHeader: true,
      ));
    } else {
      lines.add(InstantSaleLineItem(
        name: product.isNotEmpty ? product : displayTitle,
        quantity: quantity,
        unitCost: cost,
      ));
    }
    for (final sub in subProducts) {
      lines.add(InstantSaleLineItem(
        name: sub.productName,
        quantity: sub.quantity,
        unitCost: sub.cost,
      ));
    }
    return lines;
  }

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
      createdBy: json['created_by'] == null
          ? null
          : int.tryParse('${json['created_by']}'),
      createdByName: asNullableString(json['created_by_name']),
      updatedBy: json['updated_by'] == null
          ? null
          : int.tryParse('${json['updated_by']}'),
      updatedByName: asNullableString(json['updated_by_name']),
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

class InstantSaleLineItem {
  final String name;
  final String quantity;
  final String unitCost;
  final bool isPackageHeader;

  const InstantSaleLineItem({
    required this.name,
    required this.quantity,
    required this.unitCost,
    this.isPackageHeader = false,
  });
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
