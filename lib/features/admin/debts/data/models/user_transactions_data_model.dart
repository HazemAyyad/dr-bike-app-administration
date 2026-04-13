import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

class UserTransactionsDataModel {
  final String status;
  final String customerBalance;
  final List<Debt> customerDebts;

  UserTransactionsDataModel({
    required this.status,
    required this.customerBalance,
    required this.customerDebts,
  });

  factory UserTransactionsDataModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return UserTransactionsDataModel(
      status: asString(j[ApiKey.status], 'failed'),
      customerBalance: asString(j['person_balance'], '0'),
      customerDebts: mapListFromResponseKey(
        j,
        'person_debts',
        (Map<String, dynamic> m) => Debt.fromJson(m),
        debugScope: 'UserTransactionsDataModel',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.status: status,
      ApiKey.customer_balance: customerBalance,
      ApiKey.customer_debts: customerDebts.map((e) => e.toJson()).toList(),
    };
  }
}

class Debt {
  final int id;
  final int customerId;
  final String customerName;
  final bool isCanceledCustomer;
  final DateTime dueDate;
  final String total;
  final String status;
  final String receiptImage;
  final String? notes;
  final String debtType;
  final DateTime debtCreatedAt;

  Debt({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.isCanceledCustomer,
    required this.debtType,
    required this.dueDate,
    required this.total,
    required this.receiptImage,
    this.notes,
    required this.debtCreatedAt,
    required this.status,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return Debt(
      id: asInt(j[ApiKey.id]),
      customerId: asInt(j[ApiKey.customer_id]),
      customerName: asString(j[ApiKey.customer_name]),
      isCanceledCustomer: asBool(j[ApiKey.customer_is_canceled]),
      debtType: asString(j[ApiKey.debt_type]),
      dueDate: parseApiDateTime(j[ApiKey.due_date]),
      total: asString(j[ApiKey.total], '0'),
      receiptImage:
          ShowNetImage.getPhoto(asNullableString(j[ApiKey.receipt_image])),
      notes: asNullableString(j[ApiKey.notes]),
      debtCreatedAt: parseApiDateTime(j[ApiKey.debt_created_at]),
      status: asString(j[ApiKey.status]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.id: id,
      ApiKey.customer_id: customerId,
      ApiKey.type: debtType,
      ApiKey.due_date: dueDate.toIso8601String(),
      ApiKey.total: total,
      ApiKey.receipt_image: receiptImage,
      ApiKey.notes: notes,
      ApiKey.debt_created_at: debtCreatedAt.toIso8601String(),
      ApiKey.status: status,
    };
  }
}
