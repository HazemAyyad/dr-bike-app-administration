class LedgerCurrencyTotals {
  final double receivable;
  final double payable;

  const LedgerCurrencyTotals({
    required this.receivable,
    required this.payable,
  });

  factory LedgerCurrencyTotals.fromJson(Map<String, dynamic> json) {
    double parse(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0;
    return LedgerCurrencyTotals(
      receivable: parse(json['receivable']),
      payable: parse(json['payable']),
    );
  }
}

class ContactCategory {
  final int id;
  final String name;
  final String color;
  final int customersCount;
  final int sellersCount;
  final List<int> customerIds;
  final List<int> sellerIds;

  const ContactCategory({
    required this.id,
    required this.name,
    required this.color,
    required this.customersCount,
    required this.sellersCount,
    this.customerIds = const [],
    this.sellerIds = const [],
  });

  factory ContactCategory.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
    List<int> parseIds(dynamic value) {
      if (value is! List) return const [];
      return value.map(parseInt).where((id) => id > 0).toList();
    }

    return ContactCategory(
      id: parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      color: json['color']?.toString() ?? '#2196F3',
      customersCount: parseInt(json['customers_count']),
      sellersCount: parseInt(json['sellers_count']),
      customerIds: parseIds(json['customer_ids']),
      sellerIds: parseIds(json['seller_ids']),
    );
  }
}

class LedgerSummary {
  /// مجموع الأرصدة الموجبة (لنا) — يُعرض في «أخذت».
  final double totalTakenCustomers;

  /// مجموع الأرصدة السالبة (علينا) — يُعرض في «أعطيت».
  final double totalGivenCustomers;
  final double balanceCustomers;
  final int customersCount;
  final double totalTakenSellers;
  final double totalGivenSellers;
  final double balanceSellers;
  final int sellersCount;
  final Map<String, LedgerCurrencyTotals> customersByCurrency;
  final Map<String, LedgerCurrencyTotals> sellersByCurrency;

  LedgerSummary({
    required this.totalTakenCustomers,
    required this.totalGivenCustomers,
    required this.balanceCustomers,
    required this.customersCount,
    required this.totalTakenSellers,
    required this.totalGivenSellers,
    required this.balanceSellers,
    required this.sellersCount,
    this.customersByCurrency = const {},
    this.sellersByCurrency = const {},
  });

  static Map<String, LedgerCurrencyTotals> _parseByCurrency(dynamic raw) {
    if (raw is! Map) return {};
    final out = <String, LedgerCurrencyTotals>{};
    for (final entry in raw.entries) {
      if (entry.value is Map<String, dynamic>) {
        out[entry.key.toString()] = LedgerCurrencyTotals.fromJson(
          entry.value as Map<String, dynamic>,
        );
      } else if (entry.value is Map) {
        out[entry.key.toString()] = LedgerCurrencyTotals.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
    }
    return out;
  }

  LedgerCurrencyTotals totalsFor(String currency, {required bool customers}) {
    final map = customers ? customersByCurrency : sellersByCurrency;
    return map[currency] ??
        const LedgerCurrencyTotals(receivable: 0, payable: 0);
  }

  factory LedgerSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    double parse(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0;
    int parseInt(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;

    return LedgerSummary(
      totalTakenCustomers: parse(
        data['receivable_customers'] ?? data['total_taken_customers'],
      ),
      totalGivenCustomers: parse(
        data['payable_customers'] ?? data['total_given_customers'],
      ),
      balanceCustomers: parse(data['balance_customers']),
      customersCount: parseInt(data['customers_count']),
      totalTakenSellers: parse(
        data['receivable_sellers'] ?? data['total_taken_sellers'],
      ),
      totalGivenSellers: parse(
        data['payable_sellers'] ?? data['total_given_sellers'],
      ),
      balanceSellers: parse(data['balance_sellers']),
      sellersCount: parseInt(data['sellers_count']),
      customersByCurrency: _parseByCurrency(data['customers_by_currency']),
      sellersByCurrency: _parseByCurrency(data['sellers_by_currency']),
    );
  }
}

class LedgerPerson {
  final int id;
  final String name;
  final String? phone;
  final String? imageUrl;
  final String personType;
  final double totalTaken;
  final double totalGiven;
  final double balance;
  final Map<String, double> balancesByCurrency;
  final int transactionsCount;
  final LedgerLastTransaction? lastTransaction;

  LedgerPerson({
    required this.id,
    required this.name,
    this.phone,
    this.imageUrl,
    this.personType = 'customer',
    required this.totalTaken,
    required this.totalGiven,
    required this.balance,
    this.balancesByCurrency = const {},
    required this.transactionsCount,
    this.lastTransaction,
  });

  bool get isCustomer => personType == 'customer';

  factory LedgerPerson.fromJson(Map<String, dynamic> json) {
    double parse(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0;

    final balancesRaw = json['balances'] as Map<String, dynamic>?;
    final balancesByCurrency = <String, double>{};
    if (balancesRaw != null) {
      for (final entry in balancesRaw.entries) {
        final inner = entry.value as Map<String, dynamic>?;
        balancesByCurrency[entry.key] = parse(inner?['balance'] ?? entry.value);
      }
    }

    return LedgerPerson(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      imageUrl: json['image_url']?.toString(),
      personType: json['person_type']?.toString() ?? 'customer',
      totalTaken: parse(json['total_taken']),
      totalGiven: parse(json['total_given']),
      balance: parse(json['balance']),
      balancesByCurrency: balancesByCurrency,
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

class LedgerCurrencyBalance {
  final double totalTaken;
  final double totalGiven;
  final double balance;

  const LedgerCurrencyBalance({
    required this.totalTaken,
    required this.totalGiven,
    required this.balance,
  });

  factory LedgerCurrencyBalance.fromJson(Map<String, dynamic> json) {
    double parse(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0;
    return LedgerCurrencyBalance(
      totalTaken: parse(json['total_taken']),
      totalGiven: parse(json['total_given']),
      balance: parse(json['balance']),
    );
  }
}

class LedgerPersonDetail {
  final LedgerPersonInfo person;
  final double totalTaken;
  final double totalGiven;
  final double balance;
  final Map<String, LedgerCurrencyBalance> balancesByCurrency;
  final int activeTransactionsCount;
  final List<LedgerTransaction> transactions;

  LedgerPersonDetail({
    required this.person,
    required this.totalTaken,
    required this.totalGiven,
    required this.balance,
    this.balancesByCurrency = const {},
    required this.activeTransactionsCount,
    required this.transactions,
  });

  LedgerCurrencyBalance balanceFor(String currency) {
    return balancesByCurrency[currency] ??
        const LedgerCurrencyBalance(
          totalTaken: 0,
          totalGiven: 0,
          balance: 0,
        );
  }

  factory LedgerPersonDetail.fromJson(Map<String, dynamic> json) {
    double parse(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0;
    final list = (json['transactions'] as List<dynamic>? ?? [])
        .map((e) => LedgerTransaction.fromJson(e as Map<String, dynamic>))
        .toList();

    final balancesRaw = json['balances'] as Map<String, dynamic>?;
    final balancesByCurrency = <String, LedgerCurrencyBalance>{};
    if (balancesRaw != null) {
      for (final entry in balancesRaw.entries) {
        if (entry.value is Map<String, dynamic>) {
          balancesByCurrency[entry.key] = LedgerCurrencyBalance.fromJson(
            entry.value as Map<String, dynamic>,
          );
        } else if (entry.value is Map) {
          balancesByCurrency[entry.key] = LedgerCurrencyBalance.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      }
    }

    return LedgerPersonDetail(
      person: LedgerPersonInfo.fromJson(json['person'] as Map<String, dynamic>),
      totalTaken: parse(json['total_taken']),
      totalGiven: parse(json['total_given']),
      balance: parse(json['balance']),
      balancesByCurrency: balancesByCurrency,
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
  final String? sourceLabel;
  final String currency;

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
    this.sourceLabel,
    this.currency = 'شيكل',
  });

  factory LedgerTransaction.fromJson(Map<String, dynamic> json) {
    return LedgerTransaction(
      id: json['id'] as int,
      type: json['type']?.toString() ?? '',
      typeLabel: json['type_label']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      currency: json['currency']?.toString() ?? 'شيكل',
      balanceBefore:
          double.tryParse(json['balance_before']?.toString() ?? '') ??
              _calcBalanceBefore(
                json['type']?.toString() ?? '',
                double.tryParse(json['balance_after']?.toString() ?? '0') ?? 0,
                double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
              ),
      balanceAfter:
          double.tryParse(json['balance_after']?.toString() ?? '0') ?? 0,
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
      sourceLabel: json['source_label']?.toString(),
    );
  }

  bool get isTaken => type == 'taken';

  bool get isManual => source == null || source == '' || source == 'manual';

  bool get isInstantSale => source == 'instant_sale';

  /// نص يُعرض للمستخدم (ملاحظة أو وصف مصدر مثل بيع فوري #123).
  String get displayDescription {
    final n = note?.trim();
    if (n != null && n.isNotEmpty) return n;
    final s = sourceLabel?.trim();
    if (s != null && s.isNotEmpty) return s;
    return '';
  }

  static double _calcBalanceBefore(String type, double after, double amount) {
    return type == 'taken' ? after - amount : after + amount;
  }
}

Map<String, LedgerCurrencyBalance> _parseBalancesByCurrency(
  Map<String, dynamic>? balancesRaw,
) {
  final balancesByCurrency = <String, LedgerCurrencyBalance>{};
  if (balancesRaw == null) return balancesByCurrency;
  for (final entry in balancesRaw.entries) {
    if (entry.value is Map<String, dynamic>) {
      balancesByCurrency[entry.key] = LedgerCurrencyBalance.fromJson(
        entry.value as Map<String, dynamic>,
      );
    } else if (entry.value is Map) {
      balancesByCurrency[entry.key] = LedgerCurrencyBalance.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
    }
  }
  return balancesByCurrency;
}

class LedgerPersonArchiveDetail {
  final LedgerPersonInfo person;
  final double totalTaken;
  final double totalGiven;
  final double balance;
  final Map<String, LedgerCurrencyBalance> balancesByCurrency;
  final int archivedTransactionsCount;
  final List<LedgerTransaction> transactions;

  LedgerPersonArchiveDetail({
    required this.person,
    required this.totalTaken,
    required this.totalGiven,
    required this.balance,
    this.balancesByCurrency = const {},
    required this.archivedTransactionsCount,
    required this.transactions,
  });

  LedgerCurrencyBalance balanceFor(String currency) {
    return balancesByCurrency[currency] ??
        const LedgerCurrencyBalance(
          totalTaken: 0,
          totalGiven: 0,
          balance: 0,
        );
  }

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
      balancesByCurrency:
          _parseBalancesByCurrency(data['balances'] as Map<String, dynamic>?),
      archivedTransactionsCount: data['archived_transactions_count'] as int? ??
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

class LedgerActivityEntry {
  final int id;
  final String action;
  final String title;
  final String description;
  final String? createdByName;
  final String? createdAt;

  LedgerActivityEntry({
    required this.id,
    required this.action,
    required this.title,
    required this.description,
    this.createdByName,
    this.createdAt,
  });

  factory LedgerActivityEntry.fromJson(Map<String, dynamic> json) {
    return LedgerActivityEntry(
      id: json['id'] as int,
      action: json['action']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdByName: json['created_by_name']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}
