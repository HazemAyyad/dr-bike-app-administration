import 'package:doctorbike/core/databases/api/end_points.dart';

import '../../../../../core/helpers/show_net_image.dart';

class DebtsWeOweModel {
  final String status;
  final List<DebtsWeOwe> debts;

  DebtsWeOweModel({required this.status, required this.debts});

  factory DebtsWeOweModel.fromJson(Map<String, dynamic> json) {
    return DebtsWeOweModel(
      status: json[ApiKey.status],
      debts: (json[ApiKey.debts] as List<dynamic>)
          .map((e) => DebtsWeOwe.fromJson(e))
          .toList(),
    );
  }
}

class DebtsWeOwe {
  final int debtId;
  final int? customerId;
  final String? customerName;
  final int? sellerId;
  final String? sellerName;
  final bool? customerIsCanceled;
  final bool? sellerIsCanceled;
  final DateTime dueDate;
  final String total;
  final String status;
  final String receiptImage;
  final String debtType;
  final DateTime debtCreatedAt;
  final String notes;

  const DebtsWeOwe({
    required this.debtId,
    required this.customerId,
    required this.customerName,
    required this.customerIsCanceled,
    required this.sellerId,
    required this.sellerName,
    required this.sellerIsCanceled,
    required this.dueDate,
    required this.total,
    required this.status,
    required this.receiptImage,
    required this.debtType,
    required this.debtCreatedAt,
    required this.notes,
  });

  factory DebtsWeOwe.fromJson(Map<String, dynamic> json) {
    return DebtsWeOwe(
      debtId: json['debt_id'] ?? 0,
      customerId: json[ApiKey.customer_id] ?? 0,
      customerName: json[ApiKey.customer_name] ?? '',
      customerIsCanceled: json[ApiKey.customer_is_canceled] == '1',
      sellerId: json['seller_id'] ?? 0,
      sellerName: json['seller_name'] ?? '',
      sellerIsCanceled: json['seller_is_canceled'] == '1',
      dueDate: DateTime.parse(json[ApiKey.due_date]),
      total: json[ApiKey.total] ?? '0',
      status: json[ApiKey.status] ?? 'unpaid',
      receiptImage: ShowNetImage.getPhoto(json[ApiKey.receipt_image]),
      debtType: json[ApiKey.debt_type] ?? '',
      debtCreatedAt: DateTime.parse(
          json[ApiKey.debt_created_at] ?? DateTime.now().toIso8601String()),
      notes: json[ApiKey.notes] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'debt_id': debtId,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_is_canceled': customerIsCanceled! ? '1' : '0',
      'seller_id': sellerId,
      'seller_name': sellerName,
      'seller_is_canceled': sellerIsCanceled! ? '1' : '0',
      ApiKey.due_date: dueDate.toIso8601String(),
      ApiKey.total: total,
      ApiKey.status: status,
      ApiKey.receipt_image: receiptImage,
      ApiKey.debt_type: debtType,
      ApiKey.debt_created_at: debtCreatedAt.toIso8601String(),
      ApiKey.notes: notes,
    };
  }
}
