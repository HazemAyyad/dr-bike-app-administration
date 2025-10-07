import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

class UserTransactionsDataModel {
  final String status;
  final double customerBalance;
  final List<Debt> customerDebts;

  UserTransactionsDataModel({
    required this.status,
    required this.customerBalance,
    required this.customerDebts,
  });

  factory UserTransactionsDataModel.fromJson(Map<String, dynamic> json) {
    return UserTransactionsDataModel(
      status: json[ApiKey.status] ?? 'failed',
      customerBalance: json['person_balance'] ?? 0.0,
      customerDebts: (json['person_debts'] as List<dynamic>?)
              ?.map((e) => Debt.fromJson(e))
              .toList() ??
          [],
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
    return Debt(
      id: json[ApiKey.id] ?? 0,
      customerId: json[ApiKey.customer_id] ?? 0,
      customerName: json[ApiKey.customer_name] ?? '',
      isCanceledCustomer: json[ApiKey.customer_is_canceled] == '1',
      debtType: json[ApiKey.debt_type] ?? '',
      dueDate: json[ApiKey.due_date] != null
          ? DateTime.parse(json[ApiKey.due_date])
          : DateTime.now(),
      total: json[ApiKey.total] ?? '0',
      receiptImage: ShowNetImage.getPhoto(json[ApiKey.receipt_image]),
      notes: json[ApiKey.notes] ?? '',
      debtCreatedAt: json[ApiKey.debt_created_at] != null
          ? DateTime.parse(json[ApiKey.debt_created_at])
          : DateTime.now(),
      status: json[ApiKey.status] ?? '',
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
