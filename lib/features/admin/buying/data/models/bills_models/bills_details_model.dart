import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

class BillDetailsModel {
  final int billId;
  final List<BillProductModel> products;
  final String sellerId;
  final String sellerName;
  final String createdAt;
  final String totalBill;
  final String workflowStatus;
  final String paymentStatus;
  final String finalTotal;
  final String paidAmount;
  final String remainingAmount;

  BillDetailsModel({
    required this.billId,
    required this.products,
    required this.sellerId,
    required this.sellerName,
    required this.createdAt,
    required this.totalBill,
    required this.workflowStatus,
    required this.paymentStatus,
    required this.finalTotal,
    required this.paidAmount,
    required this.remainingAmount,
  });

  factory BillDetailsModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return BillDetailsModel(
      billId: asInt(j['bill_id']),
      products: mapList(
        j['products'],
        (Map<String, dynamic> m) => BillProductModel.fromJson(m),
      ),
      sellerId: asString(j['seller_id']),
      sellerName: asString(j['seller_name']),
      createdAt: asString(j['created_at']),
      totalBill: asString(j['total_bill'], '0.0'),
      workflowStatus: asString(j['workflow_status']),
      paymentStatus: asString(j['payment_status']),
      finalTotal: asString(j['final_total'], asString(j['total_bill'], '0')),
      paidAmount: asString(j['paid_amount'], '0'),
      remainingAmount: asString(j['remaining_amount'], '0'),
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
      'workflow_status': workflowStatus,
      'payment_status': paymentStatus,
      'final_total': finalTotal,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
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
  final int billItemId;
  final num orderedQuantity;
  final num receivedOwnedQuantity;
  final num remainingQuantity;
  final num custodyQuantity;

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
    required this.billItemId,
    required this.orderedQuantity,
    required this.receivedOwnedQuantity,
    required this.remainingQuantity,
    required this.custodyQuantity,
  });

  factory BillProductModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return BillProductModel(
      billId: asInt(j['bill_id']),
      productId: asString(j['product_id']),
      productName: asString(j['product_name']),
      productImage: ShowNetImage.getPhoto(asNullableString(j['product_image'])),
      quantity: asString(j['quantity'], '0'),
      price: asString(j['price'], '0'),
      productStatus: asString(j['product_status']),
      subTotal: asDouble(j['sub_total']),
      extraAmount: asString(j['extra_amount']),
      missingAmount: asString(j['missing_amount']),
      notCompatibleAmount: asString(j['not_compatible_amount']),
      billItemId: asInt(j['bill_item_id'], asInt(j['id'])),
      orderedQuantity: asDouble(j['ordered_quantity'], asDouble(j['quantity'])),
      receivedOwnedQuantity: asDouble(j['received_owned_quantity']),
      remainingQuantity: asDouble(j['remaining_quantity']),
      custodyQuantity: asDouble(j['custody_quantity']),
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
      'bill_item_id': billItemId,
      'ordered_quantity': orderedQuantity,
      'received_owned_quantity': receivedOwnedQuantity,
      'remaining_quantity': remainingQuantity,
      'custody_quantity': custodyQuantity,
    };
  }
}
