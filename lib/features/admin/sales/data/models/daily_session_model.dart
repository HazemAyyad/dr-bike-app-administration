import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class DailySessionPayload {
  final DailySessionInfo? session;
  final List<DailyCurrencyRow> currencies;
  final int instantSalesCount;
  final int profitSalesCount;
  final int? pendingClosingRequestId;
  final int? pendingReopenRequestId;
  final DailySessionConfig config;
  final bool canRequestOpen;
  final bool blockedByOtherSession;
  final String? blockedByEmployeeName;
  final bool canManageOtherSession;
  final int? manageableSessionId;
  final bool canFinalizeClosing;

  const DailySessionPayload({
    this.session,
    this.currencies = const [],
    this.instantSalesCount = 0,
    this.profitSalesCount = 0,
    this.pendingClosingRequestId,
    this.pendingReopenRequestId,
    this.config = const DailySessionConfig(),
    this.canRequestOpen = false,
    this.blockedByOtherSession = false,
    this.blockedByEmployeeName,
    this.canManageOtherSession = false,
    this.manageableSessionId,
    this.canFinalizeClosing = false,
  });

  bool get allowsSales => session?.allowsSales ?? false;

  bool get isClosingRequested =>
      session?.status == 'closing_requested';

  bool get isClosed => session?.status == 'closed';

  bool get isReopenPending =>
      pendingReopenRequestId != null || (session?.hasPendingReopen ?? false);

  bool get canRequestReopen =>
      isClosed && !isReopenPending;

  bool get canRequestClosing =>
      session?.canRequestClosing ?? false;

  bool get requiresLateCloseReason =>
      (session?.requiresLateCloseReason ?? false) || isBlockingPreviousDay;

  bool get isBlockingPreviousDay =>
      session?.isBlockingPreviousDay ?? false;

  bool get needsManualOpen =>
      session == null && canRequestOpen && !blockedByOtherSession;

  DailyCurrencyRow? rowForCurrency(String currency) {
    final i = currencies.indexWhere((c) => c.currency == currency);
    return i >= 0 ? currencies[i] : null;
  }

  factory DailySessionPayload.fromJson(Map<String, dynamic> json) {
    return DailySessionPayload(
      session: json['session'] is Map
          ? DailySessionInfo.fromJson(
              Map<String, dynamic>.from(json['session'] as Map),
            )
          : null,
      currencies: mapList(
        json['currencies'],
        (Map<String, dynamic> m) => DailyCurrencyRow.fromJson(m),
      ),
      instantSalesCount: asInt(json['instant_sales_count']),
      profitSalesCount: asInt(json['profit_sales_count']),
      pendingClosingRequestId: json['pending_closing_request_id'] == null
          ? null
          : int.tryParse('${json['pending_closing_request_id']}'),
      pendingReopenRequestId: json['pending_reopen_request_id'] == null
          ? null
          : int.tryParse('${json['pending_reopen_request_id']}'),
      config: json['config'] is Map
          ? DailySessionConfig.fromJson(
              Map<String, dynamic>.from(json['config'] as Map),
            )
          : const DailySessionConfig(),
      canRequestOpen: json['can_request_open'] == true ||
          json['can_request_open'] == 1,
      blockedByOtherSession: json['blocked_by_other_session'] == true ||
          json['blocked_by_other_session'] == 1,
      blockedByEmployeeName: asNullableString(json['blocked_by_employee_name']),
      canManageOtherSession: json['can_manage_other_session'] == true ||
          json['can_manage_other_session'] == 1,
      manageableSessionId: json['manageable_session_id'] == null
          ? null
          : int.tryParse('${json['manageable_session_id']}'),
      canFinalizeClosing: json['can_finalize_closing'] == true ||
          json['can_finalize_closing'] == 1,
    );
  }
}

class DailySessionInfo {
  final int id;
  final String businessDate;
  final String status;
  final bool allowsSales;
  final bool isBlockingPreviousDay;
  final bool canRequestClosing;
  final bool requiresLateCloseReason;
  final bool closedOnNextDay;
  final String? employeeName;
  final String? openedAt;
  final String? closedAt;
  final bool hasPendingReopen;

  const DailySessionInfo({
    required this.id,
    required this.businessDate,
    required this.status,
    this.allowsSales = false,
    this.isBlockingPreviousDay = false,
    this.canRequestClosing = false,
    this.requiresLateCloseReason = false,
    this.closedOnNextDay = false,
    this.employeeName,
    this.openedAt,
    this.closedAt,
    this.hasPendingReopen = false,
  });

  factory DailySessionInfo.fromJson(Map<String, dynamic> json) {
    return DailySessionInfo(
      id: asInt(json['id']),
      businessDate: asString(json['business_date']),
      status: asString(json['status']),
      allowsSales: json['allows_sales'] == true || json['allows_sales'] == 1,
      isBlockingPreviousDay: json['is_blocking_previous_day'] == true ||
          json['is_blocking_previous_day'] == 1,
      canRequestClosing: json['can_request_closing'] == true ||
          json['can_request_closing'] == 1,
      requiresLateCloseReason: json['requires_late_close_reason'] == true ||
          json['requires_late_close_reason'] == 1,
      closedOnNextDay: json['closed_on_next_day'] == true ||
          json['closed_on_next_day'] == 1,
      employeeName: asNullableString(json['employee_name']),
      openedAt: asNullableString(json['opened_at']),
      closedAt: asNullableString(json['closed_at']),
      hasPendingReopen: json['has_pending_reopen'] == true ||
          json['has_pending_reopen'] == 1,
    );
  }
}

class DailyReopenRequestModel {
  final int id;
  final String status;
  final String reason;
  final String? requestedAt;
  final String? employeeName;
  final String? businessDate;

  const DailyReopenRequestModel({
    required this.id,
    required this.status,
    required this.reason,
    this.requestedAt,
    this.employeeName,
    this.businessDate,
  });

  factory DailyReopenRequestModel.fromJson(Map<String, dynamic> json) {
    return DailyReopenRequestModel(
      id: asInt(json['id']),
      status: asString(json['status']),
      reason: asString(json['reason']),
      requestedAt: asNullableString(json['requested_at']),
      employeeName: asNullableString(json['employee_name']),
      businessDate: asNullableString(json['business_date']),
    );
  }
}

class DailyCurrencyRow {
  final String currency;
  final int dailyBoxId;
  final String dailyBoxName;
  final double boxBalance;
  final double openingFloat;
  final double salesCollected;
  final double systemBalance;

  const DailyCurrencyRow({
    required this.currency,
    required this.dailyBoxId,
    required this.dailyBoxName,
    this.boxBalance = 0,
    this.openingFloat = 0,
    this.salesCollected = 0,
    this.systemBalance = 0,
  });

  factory DailyCurrencyRow.fromJson(Map<String, dynamic> json) {
    return DailyCurrencyRow(
      currency: asString(json['currency']),
      dailyBoxId: asInt(json['daily_box_id']),
      dailyBoxName: asString(json['daily_box_name']),
      boxBalance: asDouble(json['box_balance']),
      openingFloat: asDouble(json['opening_float']),
      salesCollected: asDouble(json['sales_collected']),
      systemBalance: asDouble(json['system_balance']),
    );
  }
}

class DailySessionConfig {
  final double varianceAlertThreshold;
  final Map<String, double> maxFloat;

  const DailySessionConfig({
    this.varianceAlertThreshold = 50,
    this.maxFloat = const {},
  });

  factory DailySessionConfig.fromJson(Map<String, dynamic> json) {
    final raw = json['max_float'];
    final maxFloat = <String, double>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        maxFloat['$key'] = asDouble(value);
      });
    }
    return DailySessionConfig(
      varianceAlertThreshold: asDouble(json['variance_alert_threshold'], 50),
      maxFloat: maxFloat,
    );
  }
}

class DailyClosingRequestModel {
  final int id;
  final String status;
  final String? requestedAt;
  final String? requestedDate;
  final String? employeeName;
  final String? businessDate;
  final int instantSalesCount;
  final int profitSalesCount;
  final List<DailyCashCountRow> cashCounts;
  final bool isLateClose;
  final String? lateCloseReason;

  bool get hasLateCloseInfo =>
      isLateClose ||
      (lateCloseReason != null && lateCloseReason!.trim().isNotEmpty);

  const DailyClosingRequestModel({
    required this.id,
    required this.status,
    this.requestedAt,
    this.requestedDate,
    this.employeeName,
    this.businessDate,
    this.instantSalesCount = 0,
    this.profitSalesCount = 0,
    this.cashCounts = const [],
    this.isLateClose = false,
    this.lateCloseReason,
  });

  factory DailyClosingRequestModel.fromJson(Map<String, dynamic> json) {
    final counts = <DailyCashCountRow>[];
    final raw = json['cash_counts'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          counts.add(DailyCashCountRow.fromJson(
            Map<String, dynamic>.from(item),
          ));
        }
      }
    }
    return DailyClosingRequestModel(
      id: asInt(json['id']),
      status: asString(json['status']),
      requestedAt: asNullableString(json['requested_at']),
      requestedDate: asNullableString(json['requested_date']),
      employeeName: asNullableString(json['employee_name']),
      businessDate: asNullableString(json['business_date']),
      instantSalesCount: asInt(json['instant_sales_count']),
      profitSalesCount: asInt(json['profit_sales_count']),
      cashCounts: counts,
      isLateClose:
          json['is_late_close'] == true || json['is_late_close'] == 1,
      lateCloseReason: asNullableString(json['late_close_reason']),
    );
  }
}

class DailyCashCountRow {
  final String currency;
  final int dailyBoxId;
  final double openingFloat;
  final double salesCollected;
  final double systemBalance;
  final double physicalCount;
  final double variance;
  final double floatToKeep;
  final double amountToTransfer;
  final String employeeNote;
  final bool varianceAlert;

  const DailyCashCountRow({
    required this.currency,
    this.dailyBoxId = 0,
    this.openingFloat = 0,
    this.salesCollected = 0,
    this.systemBalance = 0,
    this.physicalCount = 0,
    this.variance = 0,
    this.floatToKeep = 0,
    this.amountToTransfer = 0,
    this.employeeNote = '',
    this.varianceAlert = false,
  });

  factory DailyCashCountRow.fromJson(Map<String, dynamic> json) {
    return DailyCashCountRow(
      currency: asString(json['currency']),
      dailyBoxId: asInt(json['daily_box_id']),
      openingFloat: asDouble(json['opening_float']),
      salesCollected: asDouble(json['sales_collected']),
      systemBalance: asDouble(json['system_balance']),
      physicalCount: asDouble(json['physical_count']),
      variance: asDouble(json['variance']),
      floatToKeep: asDouble(json['float_to_keep']),
      amountToTransfer: asDouble(json['amount_to_transfer']),
      employeeNote: asString(json['employee_note']),
      varianceAlert:
          json['variance_alert'] == true || json['variance_alert'] == 1,
    );
  }

  Map<String, dynamic> toRequestJson({
    required String physical,
    required String floatKeep,
    String? note,
  }) {
    return {
      'currency': currency,
      'physical_count': physical,
      'float_to_keep': floatKeep,
      if (note != null && note.trim().isNotEmpty) 'employee_note': note.trim(),
    };
  }
}

class DailySessionSummaryModel {
  final int id;
  final int userId;
  final int? employeeId;
  final String? employeeName;
  final String businessDate;
  final String status;
  final String? openedAt;
  final String? closedAt;
  final bool closedOnNextDay;
  final int instantSalesCount;
  final int profitSalesCount;
  final List<DailyCurrencyRow> currencies;
  final bool canClose;
  final int? pendingClosingRequestId;

  const DailySessionSummaryModel({
    required this.id,
    required this.userId,
    this.employeeId,
    this.employeeName,
    required this.businessDate,
    required this.status,
    this.openedAt,
    this.closedAt,
    this.closedOnNextDay = false,
    this.instantSalesCount = 0,
    this.profitSalesCount = 0,
    this.currencies = const [],
    this.canClose = false,
    this.pendingClosingRequestId,
  });

  bool get isOpen => status == 'open';
  bool get isClosingRequested => status == 'closing_requested';

  factory DailySessionSummaryModel.fromJson(Map<String, dynamic> json) {
    return DailySessionSummaryModel(
      id: asInt(json['id']),
      userId: asInt(json['user_id']),
      employeeId: json['employee_id'] == null
          ? null
          : int.tryParse('${json['employee_id']}'),
      employeeName: asNullableString(json['employee_name']),
      businessDate: asString(json['business_date']),
      status: asString(json['status']),
      openedAt: asNullableString(json['opened_at']),
      closedAt: asNullableString(json['closed_at']),
      closedOnNextDay: json['closed_on_next_day'] == true ||
          json['closed_on_next_day'] == 1,
      instantSalesCount: asInt(json['instant_sales_count']),
      profitSalesCount: asInt(json['profit_sales_count']),
      currencies: mapList(
        json['currencies'],
        (Map<String, dynamic> m) => DailyCurrencyRow.fromJson(m),
      ),
      canClose: json['can_close'] == true || json['can_close'] == 1,
      pendingClosingRequestId: json['pending_closing_request_id'] == null
          ? null
          : int.tryParse('${json['pending_closing_request_id']}'),
    );
  }
}

class DailyTodayOverviewModel {
  final String businessDate;
  final List<DailySessionSummaryModel> sessions;
  final int total;
  final int openCount;
  final int closingRequestedCount;
  final int closedCount;

  const DailyTodayOverviewModel({
    required this.businessDate,
    this.sessions = const [],
    this.total = 0,
    this.openCount = 0,
    this.closingRequestedCount = 0,
    this.closedCount = 0,
  });

  factory DailyTodayOverviewModel.fromJson(Map<String, dynamic> json) {
    final counts = json['counts'] is Map
        ? Map<String, dynamic>.from(json['counts'] as Map)
        : <String, dynamic>{};

    return DailyTodayOverviewModel(
      businessDate: asString(json['business_date']),
      sessions: mapList(
        json['sessions'],
        (Map<String, dynamic> m) => DailySessionSummaryModel.fromJson(m),
      ),
      total: asInt(counts['total']),
      openCount: asInt(counts['open']),
      closingRequestedCount: asInt(counts['closing_requested']),
      closedCount: asInt(counts['closed']),
    );
  }
}

class DailyClosingHistoryModel {
  final int id;
  final String status;
  final String? requestedAt;
  final String? requestedDate;
  final String? reviewedAt;
  final String? reviewedDate;
  final String? reviewNotes;
  final String? requestedBy;
  final String? reviewedBy;
  final String? businessDate;
  final int instantSalesCount;
  final int profitSalesCount;
  final List<DailyCashCountRow> cashCounts;
  final List<Map<String, dynamic>> transfers;
  final bool isLateClose;
  final String? lateCloseReason;

  const DailyClosingHistoryModel({
    required this.id,
    required this.status,
    this.requestedAt,
    this.requestedDate,
    this.reviewedAt,
    this.reviewedDate,
    this.reviewNotes,
    this.requestedBy,
    this.reviewedBy,
    this.businessDate,
    this.instantSalesCount = 0,
    this.profitSalesCount = 0,
    this.cashCounts = const [],
    this.transfers = const [],
    this.isLateClose = false,
    this.lateCloseReason,
  });

  factory DailyClosingHistoryModel.fromJson(Map<String, dynamic> json) {
    final transfers = <Map<String, dynamic>>[];
    final rawTransfers = json['transfers'];
    if (rawTransfers is List) {
      for (final item in rawTransfers) {
        if (item is Map) {
          transfers.add(Map<String, dynamic>.from(item));
        }
      }
    }

    return DailyClosingHistoryModel(
      id: asInt(json['id']),
      status: asString(json['status']),
      requestedAt: asNullableString(json['requested_at']),
      requestedDate: asNullableString(json['requested_date']),
      reviewedAt: asNullableString(json['reviewed_at']),
      reviewedDate: asNullableString(json['reviewed_date']),
      reviewNotes: asNullableString(json['review_notes']),
      requestedBy: asNullableString(json['requested_by']),
      reviewedBy: asNullableString(json['reviewed_by']),
      businessDate: asNullableString(json['business_date']),
      instantSalesCount: asInt(json['instant_sales_count']),
      profitSalesCount: asInt(json['profit_sales_count']),
      cashCounts: mapList(
        json['cash_counts'],
        (Map<String, dynamic> m) => DailyCashCountRow.fromJson(m),
      ),
      transfers: transfers,
      isLateClose:
          json['is_late_close'] == true || json['is_late_close'] == 1,
      lateCloseReason: asNullableString(json['late_close_reason']),
    );
  }
}

class DailySessionSaleLogRow {
  final int id;
  final String saleType;
  final String label;
  final double totalCost;
  final double paidAmount;
  final double remainingAmount;
  final double quantity;
  final String status;
  final String? createdAt;
  final String? buyerName;
  final String? paymentBoxName;
  final String? notes;
  final bool isPackageSale;
  final bool isFromSalesOrder;
  final int? salesOrderId;
  final String? salesOrderSerial;

  const DailySessionSaleLogRow({
    required this.id,
    required this.saleType,
    required this.label,
    this.totalCost = 0,
    this.paidAmount = 0,
    this.remainingAmount = 0,
    this.quantity = 0,
    this.status = 'active',
    this.createdAt,
    this.buyerName,
    this.paymentBoxName,
    this.notes,
    this.isPackageSale = false,
    this.isFromSalesOrder = false,
    this.salesOrderId,
    this.salesOrderSerial,
  });

  bool get isCancelled => status == 'cancelled';

  bool get isInstant => saleType == 'instant';

  factory DailySessionSaleLogRow.fromJson(Map<String, dynamic> json) {
    return DailySessionSaleLogRow(
      id: asInt(json['id']),
      saleType: asString(json['sale_type'], 'instant'),
      label: asString(json['label']),
      totalCost: asDouble(json['total_cost']),
      paidAmount: asDouble(json['paid_amount']),
      remainingAmount: asDouble(json['remaining_amount']),
      quantity: asDouble(json['quantity']),
      status: asString(json['status'], 'active'),
      createdAt: asNullableString(json['created_at']),
      buyerName: asNullableString(json['buyer_name']),
      paymentBoxName: asNullableString(json['payment_box_name']),
      notes: asNullableString(json['notes']),
      isPackageSale:
          json['is_package_sale'] == true || json['is_package_sale'] == 1,
      isFromSalesOrder:
          json['is_from_sales_order'] == true || json['is_from_sales_order'] == 1,
      salesOrderId: json['sales_order_id'] as int?,
      salesOrderSerial: asNullableString(json['sales_order_serial']),
    );
  }
}

class DailySessionOrderLogRow {
  final int id;
  final String? serialNumber;
  final String status;
  final String? customerName;
  final double total;
  final String paymentType;
  final double paymentAmount;
  final int? instantSaleId;
  final bool deliveredToday;
  final String? createdAt;

  const DailySessionOrderLogRow({
    required this.id,
    this.serialNumber,
    required this.status,
    this.customerName,
    this.total = 0,
    this.paymentType = 'cash',
    this.paymentAmount = 0,
    this.instantSaleId,
    this.deliveredToday = false,
    this.createdAt,
  });

  factory DailySessionOrderLogRow.fromJson(Map<String, dynamic> json) {
    return DailySessionOrderLogRow(
      id: asInt(json['id']),
      serialNumber: asNullableString(json['serial_number']),
      status: asString(json['status'], 'unconfirmed'),
      customerName: asNullableString(json['customer_name']),
      total: asDouble(json['total']),
      paymentType: asString(json['payment_type'], 'cash'),
      paymentAmount: asDouble(json['payment_amount']),
      instantSaleId: json['instant_sale_id'] as int?,
      deliveredToday:
          json['delivered_today'] == true || json['delivered_today'] == 1,
      createdAt: asNullableString(json['created_at']),
    );
  }
}

class DailySessionDetailModel {
  final DailySessionInfo session;
  final List<DailyCurrencyRow> currencies;
  final int instantSalesCount;
  final int profitSalesCount;
  final List<DailySessionSaleLogRow> instantSales;
  final List<DailySessionSaleLogRow> profitSales;
  final List<DailyClosingHistoryModel> closingRequests;
  final int salesOrdersCount;
  final List<DailySessionOrderLogRow> salesOrders;

  const DailySessionDetailModel({
    required this.session,
    this.currencies = const [],
    this.instantSalesCount = 0,
    this.profitSalesCount = 0,
    this.instantSales = const [],
    this.profitSales = const [],
    this.closingRequests = const [],
    this.salesOrdersCount = 0,
    this.salesOrders = const [],
  });

  factory DailySessionDetailModel.fromJson(Map<String, dynamic> json) {
    final sessionJson = json['session'];
    return DailySessionDetailModel(
      session: sessionJson is Map
          ? DailySessionInfo.fromJson(
              Map<String, dynamic>.from(sessionJson),
            )
          : const DailySessionInfo(
              id: 0,
              businessDate: '',
              status: '',
            ),
      currencies: mapList(
        json['currencies'],
        (Map<String, dynamic> m) => DailyCurrencyRow.fromJson(m),
      ),
      instantSalesCount: asInt(json['instant_sales_count']),
      profitSalesCount: asInt(json['profit_sales_count']),
      instantSales: mapList(
        json['instant_sales'],
        (Map<String, dynamic> m) => DailySessionSaleLogRow.fromJson(m),
      ),
      profitSales: mapList(
        json['profit_sales'],
        (Map<String, dynamic> m) => DailySessionSaleLogRow.fromJson(m),
      ),
      closingRequests: mapList(
        json['closing_requests'],
        (Map<String, dynamic> m) => DailyClosingHistoryModel.fromJson(m),
      ),
      salesOrdersCount: asInt(json['sales_orders_count']),
      salesOrders: mapList(
        json['sales_orders'],
        (Map<String, dynamic> m) => DailySessionOrderLogRow.fromJson(m),
      ),
    );
  }
}

class SalesCancellationRequestModel {
  final int id;
  final String saleType;
  final int saleId;
  final String status;
  final String reason;
  final String? requestedAt;
  final String? employeeName;
  final String? businessDate;

  const SalesCancellationRequestModel({
    required this.id,
    required this.saleType,
    required this.saleId,
    required this.status,
    required this.reason,
    this.requestedAt,
    this.employeeName,
    this.businessDate,
  });

  factory SalesCancellationRequestModel.fromJson(Map<String, dynamic> json) {
    return SalesCancellationRequestModel(
      id: asInt(json['id']),
      saleType: asString(json['sale_type']),
      saleId: asInt(json['sale_id']),
      status: asString(json['status']),
      reason: asString(json['reason']),
      requestedAt: asNullableString(json['requested_at']),
      employeeName: asNullableString(json['employee_name']),
      businessDate: asNullableString(json['business_date']),
    );
  }
}
