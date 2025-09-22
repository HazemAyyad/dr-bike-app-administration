import 'package:doctorbike/core/helpers/show_net_image.dart';

class BillDetailsModel {
  final int billId;
  final List<BillProductModel> products;
  final String sellerId;
  final String sellerName;
  final String createdAt;
  final String totalBill;

  BillDetailsModel({
    required this.billId,
    required this.products,
    required this.sellerId,
    required this.sellerName,
    required this.createdAt,
    required this.totalBill,
  });

  factory BillDetailsModel.fromJson(Map<String, dynamic> json) {
    return BillDetailsModel(
      billId: json['bill_id'] ?? 0,
      products: (json['products'] as List<dynamic>)
          .map((e) => BillProductModel.fromJson(e))
          .toList(),
      sellerId: json['seller_id'] ?? '',
      sellerName: json['seller_name'] ?? '',
      createdAt: json['created_at'] ?? '',
      totalBill: json['total_bill'] ?? '0.0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bill_id': billId,
      'products': products.map((e) => e.toJson()).toList(),
      'seller_id': sellerId,
      'seller_name': sellerName,
      'created_at': createdAt,
      'total_bill': totalBill,
    };
  }
}

class BillProductModel {
  final int billId;
  final String productId;
  final String productName;
  final String productImage;
  final String quantity;
  final String price;
  final String productStatus;
  final num subTotal;
  final String extraAmount;
  final String missingAmount;
  final String notCompatibleAmount;

  BillProductModel({
    required this.billId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.price,
    required this.productStatus,
    required this.subTotal,
    required this.extraAmount,
    required this.missingAmount,
    required this.notCompatibleAmount,
  });

  factory BillProductModel.fromJson(Map<String, dynamic> json) {
    return BillProductModel(
      billId: json['bill_id'] ?? 0,
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      productImage: ShowNetImage.getPhoto(json['product_image']),
      quantity: json['quantity'] ?? '0',
      price: json['price'] ?? '0',
      productStatus: json['product_status'] ?? '',
      subTotal: json['sub_total'] ?? 0,
      extraAmount: json['extra_amount'] ?? '',
      missingAmount: json['missing_amount'] ?? '',
      notCompatibleAmount: json['not_compatible_amount'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bill_id': billId,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'quantity': quantity,
      'price': price,
      'product_status': productStatus,
      'sub_total': subTotal,
      'extra_amount': extraAmount,
      'missing_amount': missingAmount,
      'not_compatible_amount': notCompatibleAmount,
    };
  }
}
