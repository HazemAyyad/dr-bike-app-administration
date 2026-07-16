class ActivitySummaryModel {
  ActivitySummaryModel({
    required this.totals,
    required this.logTypeCounts,
    required this.salesPeople,
    required this.debtPeople,
    required this.soldProducts,
  });

  final ActivitySummaryTotals totals;
  final List<ActivityTypeCountModel> logTypeCounts;
  final List<ActivitySalesPersonModel> salesPeople;
  final List<ActivityDebtPersonModel> debtPeople;
  final List<ActivitySoldProductModel> soldProducts;

  factory ActivitySummaryModel.fromJson(Map<String, dynamic> json) {
    return ActivitySummaryModel(
      totals: ActivitySummaryTotals.fromJson(_map(json['totals'])),
      logTypeCounts: _list(json['log_type_counts'])
          .map((item) => ActivityTypeCountModel.fromJson(_map(item)))
          .toList(),
      salesPeople: _list(json['sales_people'])
          .map((item) => ActivitySalesPersonModel.fromJson(_map(item)))
          .toList(),
      debtPeople: _list(json['debt_people'])
          .map((item) => ActivityDebtPersonModel.fromJson(_map(item)))
          .toList(),
      soldProducts: _list(json['sold_products'])
          .map((item) => ActivitySoldProductModel.fromJson(_map(item)))
          .toList(),
    );
  }
}

class ActivitySummaryTotals {
  ActivitySummaryTotals({
    required this.logsCount,
    required this.logTypesCount,
    required this.customersCount,
    required this.peopleCount,
    required this.invoicesCount,
    required this.salesCount,
    required this.salesAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.debtTransactionsCount,
    required this.debtAmount,
    required this.debtGivenAmount,
    required this.debtTakenAmount,
    required this.soldItemsQuantity,
  });

  final int logsCount;
  final int logTypesCount;
  final int customersCount;
  final int peopleCount;
  final int invoicesCount;
  final int salesCount;
  final double salesAmount;
  final double paidAmount;
  final double remainingAmount;
  final int debtTransactionsCount;
  final double debtAmount;
  final double debtGivenAmount;
  final double debtTakenAmount;
  final double soldItemsQuantity;

  factory ActivitySummaryTotals.fromJson(Map<String, dynamic> json) {
    return ActivitySummaryTotals(
      logsCount: _int(json['logs_count']),
      logTypesCount: _int(json['log_types_count']),
      customersCount: _int(json['customers_count']),
      peopleCount: _int(json['people_count']),
      invoicesCount: _int(json['invoices_count']),
      salesCount: _int(json['sales_count']),
      salesAmount: _double(json['sales_amount']),
      paidAmount: _double(json['paid_amount']),
      remainingAmount: _double(json['remaining_amount']),
      debtTransactionsCount: _int(json['debt_transactions_count']),
      debtAmount: _double(json['debt_amount']),
      debtGivenAmount: _double(json['debt_given_amount']),
      debtTakenAmount: _double(json['debt_taken_amount']),
      soldItemsQuantity: _double(json['sold_items_quantity']),
    );
  }
}

class ActivityTypeCountModel {
  ActivityTypeCountModel({required this.type, required this.count});

  final String type;
  final int count;

  factory ActivityTypeCountModel.fromJson(Map<String, dynamic> json) {
    return ActivityTypeCountModel(
      type: _string(json['type']),
      count: _int(json['count']),
    );
  }
}

class ActivitySalesPersonModel {
  ActivitySalesPersonModel({
    required this.name,
    required this.invoicesCount,
    required this.salesAmount,
    required this.paidAmount,
    required this.remainingAmount,
  });

  final String name;
  final int invoicesCount;
  final double salesAmount;
  final double paidAmount;
  final double remainingAmount;

  factory ActivitySalesPersonModel.fromJson(Map<String, dynamic> json) {
    return ActivitySalesPersonModel(
      name: _string(json['name']),
      invoicesCount: _int(json['invoices_count']),
      salesAmount: _double(json['sales_amount']),
      paidAmount: _double(json['paid_amount']),
      remainingAmount: _double(json['remaining_amount']),
    );
  }
}

class ActivityDebtPersonModel {
  ActivityDebtPersonModel({
    required this.name,
    required this.transactionsCount,
    required this.amount,
    required this.givenAmount,
    required this.takenAmount,
    this.lastNote,
  });

  final String name;
  final int transactionsCount;
  final double amount;
  final double givenAmount;
  final double takenAmount;
  final String? lastNote;

  factory ActivityDebtPersonModel.fromJson(Map<String, dynamic> json) {
    return ActivityDebtPersonModel(
      name: _string(json['name']),
      transactionsCount: _int(json['transactions_count']),
      amount: _double(json['amount']),
      givenAmount: _double(json['given_amount']),
      takenAmount: _double(json['taken_amount']),
      lastNote: json['last_note']?.toString(),
    );
  }
}

class ActivitySoldProductModel {
  ActivitySoldProductModel({
    required this.name,
    required this.quantity,
    required this.salesAmount,
    required this.linesCount,
  });

  final String name;
  final double quantity;
  final double salesAmount;
  final int linesCount;

  factory ActivitySoldProductModel.fromJson(Map<String, dynamic> json) {
    return ActivitySoldProductModel(
      name: _string(json['name']),
      quantity: _double(json['quantity']),
      salesAmount: _double(json['sales_amount']),
      linesCount: _int(json['lines_count']),
    );
  }
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

List<dynamic> _list(dynamic value) => value is List ? value : <dynamic>[];

String _string(dynamic value) => value?.toString() ?? '';

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _double(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
