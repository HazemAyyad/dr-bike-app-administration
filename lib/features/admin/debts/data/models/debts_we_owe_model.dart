import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

class DebtsWeOweModel {
  final String status;
  final List<DebtsWeOwe> debts;

  DebtsWeOweModel({required this.status, required this.debts});

  factory DebtsWeOweModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return DebtsWeOweModel(
      status: asString(j[ApiKey.status]),
      debts: mapListFromResponseKey(
        j,
        ApiKey.debts,
        (Map<String, dynamic> m) => DebtsWeOwe.fromJson(m),
        debugScope: 'DebtsWeOweModel',
      ),
    );
  }
}

class DebtsWeOwe {
  final int debtId;
  final int? customerId;
  final String customerName;
  final int? sellerId;
  final String sellerName;
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
    final j = Map<String, dynamic>.from(json);
    return DebtsWeOwe(
      debtId: asInt(j['debt_id']),
      customerId: j[ApiKey.customer_id] == null
          ? null
          : asInt(j[ApiKey.customer_id]),
      customerName: asString(j[ApiKey.customer_name]),
      customerIsCanceled: _nullableBool(j[ApiKey.customer_is_canceled]),
      sellerId: j['seller_id'] == null ? null : asInt(j['seller_id']),
      sellerName: asString(j['seller_name']),
      sellerIsCanceled: _nullableBool(j['seller_is_canceled']),
      dueDate: parseApiDateTime(j[ApiKey.due_date]),
      total: asString(j[ApiKey.total], '0'),
      status: asString(j[ApiKey.status], 'unpaid'),
      receiptImage:
          ShowNetImage.getPhoto(asNullableString(j[ApiKey.receipt_image])),
      debtType: asString(j[ApiKey.debt_type]),
      debtCreatedAt: parseApiDateTime(j[ApiKey.debt_created_at]),
      notes: asString(j[ApiKey.notes]),
    );
  }

  static bool? _nullableBool(dynamic v) {
    if (v == null) return null;
    return asBool(v);
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
