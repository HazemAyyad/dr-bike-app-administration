import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class ProfitSale {
  final int id;
  final String totalCost;
  final String notes;
  final String? imagePath;
  final String? videoPath;
  final String? buyerType;
  final String? buyerName;
  final int? customerId;
  final int? sellerId;
  final String? paymentBoxName;
  final String? paymentBoxValue;
  final String? status;
  final String? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfitSale({
    required this.id,
    required this.totalCost,
    required this.notes,
    this.imagePath,
    this.videoPath,
    this.buyerType,
    this.buyerName,
    this.customerId,
    this.sellerId,
    this.paymentBoxName,
    this.paymentBoxValue,
    this.status,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfitSale.fromJson(Map<String, dynamic> json) {
    return ProfitSale(
      id: asInt(json['id']),
      totalCost: asString(json['total_cost'], '0'),
      notes: asString(json['notes'], 'no notes'),
      imagePath: asNullableString(json['image_path']),
      videoPath: asNullableString(json['video_path']),
      buyerType: asNullableString(json['buyer_type']),
      buyerName: asNullableString(json['buyer_name']),
      customerId: json['customer_id'] == null ? null : asInt(json['customer_id']),
      sellerId: json['seller_id'] == null ? null : asInt(json['seller_id']),
      paymentBoxName: asNullableString(json['payment_box_name']),
      paymentBoxValue: asNullableString(json['payment_box_value']),
      status: asNullableString(json['status']),
      cancelledAt: asNullableString(json['cancelled_at']),
      createdAt: parseApiDateTime(json['created_at']),
      updatedAt: parseApiDateTime(json['updated_at']),
    );
  }

  bool get isCancelled => status == 'cancelled' || (cancelledAt?.isNotEmpty ?? false);

  String get partnerDisplay {
    final name = buyerName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (customerId != null) return 'زبون #$customerId';
    if (sellerId != null) return 'تاجر #$sellerId';
    return 'بدون زبون';
  }

  String get paymentDisplay {
    final paid = paymentBoxValue?.trim();
    if (paid == null || paid.isEmpty) return 'غير مدفوع';
    final box = paymentBoxName?.trim();
    if (box == null || box.isEmpty) return paid;
    return '$paid - $box';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'total_cost': totalCost,
      'notes': notes,
      'image_path': imagePath,
      'video_path': videoPath,
      'buyer_type': buyerType,
      'buyer_name': buyerName,
      'customer_id': customerId,
      'seller_id': sellerId,
      'payment_box_name': paymentBoxName,
      'payment_box_value': paymentBoxValue,
      'status': status,
      'cancelled_at': cancelledAt,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
