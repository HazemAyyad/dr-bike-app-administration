class LedgerSummary {
  final double totalTakenCustomers;
  final double totalGivenCustomers;
  final double balanceCustomers;
  final double totalTakenSellers;
  final double totalGivenSellers;
  final double balanceSellers;

  LedgerSummary({
    required this.totalTakenCustomers,
    required this.totalGivenCustomers,
    required this.balanceCustomers,
    required this.totalTakenSellers,
    required this.totalGivenSellers,
    required this.balanceSellers,
  });

  factory LedgerSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    double parse(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0;

    return LedgerSummary(
      totalTakenCustomers: parse(data['total_taken_customers']),
      totalGivenCustomers: parse(data['total_given_customers']),
      balanceCustomers: parse(data['balance_customers']),
      totalTakenSellers: parse(data['total_taken_sellers']),
      totalGivenSellers: parse(data['total_given_sellers']),
      balanceSellers: parse(data['balance_sellers']),
    );
  }
}

class LedgerPerson {
  final int id;
  final String name;
  final String? phone;
  final double totalTaken;
  final double totalGiven;
  final double balance;
  final int transactionsCount;
  final LedgerLastTransaction? lastTransaction;

  LedgerPerson({
    required this.id,
    required this.name,
    this.phone,
    required this.totalTaken,
    required this.totalGiven,
    required this.balance,
    required this.transactionsCount,
    this.lastTransaction,
  });

  factory LedgerPerson.fromJson(Map<String, dynamic> json) {
    double parse(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0;

    return LedgerPerson(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      totalTaken: parse(json['total_taken']),
      totalGiven: parse(json['total_given']),
      balance: parse(json['balance']),
      transactionsCount: json['transactions_count'] as int? ?? 0,
      lastTransaction: json['last_transaction'] != null
          ? LedgerLastTransaction.fromJson(
              json['last_transaction'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class LedgerLastTransaction {
  final int id;
  final String type;
  final String typeLabel;
  final double amount;
  final String? transactionDate;
  final String? createdAt;

  LedgerLastTransaction({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.amount,
    this.transactionDate,
    this.createdAt,
  });

  factory LedgerLastTransaction.fromJson(Map<String, dynamic> json) {
    return LedgerLastTransaction(
      id: json['id'] as int,
      type: json['type']?.toString() ?? '',
      typeLabel: json['type_label']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      transactionDate: json['transaction_date']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class LedgerPersonDetail {
  final LedgerPersonInfo person;
  final double totalTaken;
  final double totalGiven;
  final double balance;
  final int activeTransactionsCount;
  final List<LedgerTransaction> transactions;

  LedgerPersonDetail({
    required this.person,
    required this.totalTaken,
    required this.totalGiven,
    required this.balance,
    required this.activeTransactionsCount,
    required this.transactions,
  });

  factory LedgerPersonDetail.fromJson(Map<String, dynamic> json) {
    double parse(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0;
    final list = (json['transactions'] as List<dynamic>? ?? [])
        .map((e) => LedgerTransaction.fromJson(e as Map<String, dynamic>))
        .toList();

    return LedgerPersonDetail(
      person: LedgerPersonInfo.fromJson(json['person'] as Map<String, dynamic>),
      totalTaken: parse(json['total_taken']),
      totalGiven: parse(json['total_given']),
      balance: parse(json['balance']),
      activeTransactionsCount: json['active_transactions_count'] as int? ?? 0,
      transactions: list,
    );
  }
}

class LedgerPersonInfo {
  final int id;
  final String name;
  final String? phone;
  final String personType;
  final String? notes;
  final String? collectionReminderAt;

  LedgerPersonInfo({
    required this.id,
    required this.name,
    this.phone,
    required this.personType,
    this.notes,
    this.collectionReminderAt,
  });

  factory LedgerPersonInfo.fromJson(Map<String, dynamic> json) {
    return LedgerPersonInfo(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      personType: json['person_type']?.toString() ?? 'customer',
      notes: json['notes']?.toString(),
      collectionReminderAt: json['collection_reminder_at']?.toString(),
    );
  }

  LedgerPersonInfo copyWith({
    String? notes,
    String? collectionReminderAt,
    bool clearCollectionReminder = false,
  }) {
    return LedgerPersonInfo(
      id: id,
      name: name,
      phone: phone,
      personType: personType,
      notes: notes ?? this.notes,
      collectionReminderAt: clearCollectionReminder
          ? null
          : (collectionReminderAt ?? this.collectionReminderAt),
    );
  }

  bool get isCustomer => personType == 'customer';

  bool get hasNotes => notes != null && notes!.trim().isNotEmpty;

  bool get hasCollectionReminder =>
      collectionReminderAt != null && collectionReminderAt!.isNotEmpty;
}

class LedgerTransaction {
  final int id;
  final String type;
  final String typeLabel;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String? note;
  final List<String> receiptImages;
  final String? transactionDate;
  final String? createdAt;
  final int? boxId;
  final String? source;

  LedgerTransaction({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.note,
    required this.receiptImages,
    this.transactionDate,
    this.createdAt,
    this.boxId,
    this.source,
  });

  factory LedgerTransaction.fromJson(Map<String, dynamic> json) {
    return LedgerTransaction(
      id: json['id'] as int,
      type: json['type']?.toString() ?? '',
      typeLabel: json['type_label']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      balanceBefore: double.tryParse(json['balance_before']?.toString() ?? '') ??
          _calcBalanceBefore(
            json['type']?.toString() ?? '',
            double.tryParse(json['balance_after']?.toString() ?? '0') ?? 0,
            double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
          ),
      balanceAfter: double.tryParse(json['balance_after']?.toString() ?? '0') ?? 0,
      note: json['note']?.toString(),
      receiptImages: (json['receipt_images'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      transactionDate: json['transaction_date']?.toString(),
      createdAt: json['created_at']?.toString(),
      boxId: json['box_id'] == null
          ? null
          : int.tryParse(json['box_id'].toString()),
      source: json['source']?.toString(),
    );
  }

  bool get isTaken => type == 'taken';

  bool get isManual =>
      source == null || source == '' || source == 'manual';

  bool get isInstantSale => source == 'instant_sale';

  static double _calcBalanceBefore(String type, double after, double amount) {
    return type == 'taken' ? after - amount : after + amount;
  }
}

class LedgerPersonArchiveDetail {
  final LedgerPersonInfo person;
  final double totalTaken;
  final double totalGiven;
  final double balance;
  final int archivedTransactionsCount;
  final List<LedgerTransaction> transactions;

  LedgerPersonArchiveDetail({
    required this.person,
    required this.totalTaken,
    required this.totalGiven,
    required this.balance,
    required this.archivedTransactionsCount,
    required this.transactions,
  });

  factory LedgerPersonArchiveDetail.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    double parse(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0;
    final list = (data['transactions'] as List<dynamic>? ?? [])
        .map((e) => LedgerTransaction.fromJson(e as Map<String, dynamic>))
        .toList();

    return LedgerPersonArchiveDetail(
      person: LedgerPersonInfo.fromJson(data['person'] as Map<String, dynamic>),
      totalTaken: parse(data['total_taken']),
      totalGiven: parse(data['total_given']),
      balance: parse(data['balance']),
      archivedTransactionsCount:
          data['archived_transactions_count'] as int? ??
          data['deleted_transactions_count'] as int? ??
          list.length,
      transactions: list,
    );
  }
}

class LedgerCreateResult {
  final LedgerTransaction transaction;
  final double balance;

  LedgerCreateResult({
    required this.transaction,
    required this.balance,
  });

  factory LedgerCreateResult.fromJson(Map<String, dynamic> json) {
    double parse(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0;

    return LedgerCreateResult(
      transaction: LedgerTransaction.fromJson(
        json['transaction'] as Map<String, dynamic>,
      ),
      balance: parse(json['balance']),
    );
  }
}

class LedgerReportData {
  final String? pdfUrl;
  final String? fileName;
  final double balance;
  final String? periodLabel;

  LedgerReportData({
    this.pdfUrl,
    this.fileName,
    required this.balance,
    this.periodLabel,
  });

  factory LedgerReportData.fromJson(Map<String, dynamic> json) {
    final report = json['report'] as Map<String, dynamic>? ?? {};
    return LedgerReportData(
      pdfUrl: report['pdf_url']?.toString(),
      fileName: report['file_name']?.toString(),
      balance: double.tryParse(report['balance']?.toString() ?? '0') ?? 0,
      periodLabel: report['period_label']?.toString(),
    );
  }
}
